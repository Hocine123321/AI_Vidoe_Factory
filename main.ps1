#Requires -Version 5.1
param([switch]$Settings)

# Runtime PS7 check — #Requires -Version 7.0 silently kills window on PS5
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "`n  [ERROR] PowerShell 7 required. You are running PS $($PSVersionTable.PSVersion)." -ForegroundColor Red
    Write-Host "  Install PS7: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Yellow
    Write-Host "  Or use Launch.bat instead of running main.ps1 directly." -ForegroundColor Yellow
    cmd /c pause
    exit 1
}

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-RunAsAdminPreference {
    param([string]$ConfigPath)
    try {
        if (-not (Test-Path $ConfigPath)) { return $false }
        $raw = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if ($raw.PSObject.Properties['runtime'] -and $raw.runtime.PSObject.Properties['run_as_admin']) {
            return [bool]$raw.runtime.run_as_admin
        }
    } catch {}
    return $false
}

# ── Auto-elevate ──────────────────────────────────────────────────────────────
$shouldRunAsAdmin = Get-RunAsAdminPreference -ConfigPath "$ROOT\config\config.json"
if ($shouldRunAsAdmin -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
          ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $a = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Settings) { $a += ' -Settings' }
    Start-Process pwsh -Verb RunAs -ArgumentList $a
    exit
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Error log — written before any pause so error is never lost ───────────────
$ERRORLOG = "$ROOT\error.log"

trap {
    $msg = $_.Exception.Message
    $stk = $_.ScriptStackTrace

    # Write to file FIRST — survives window close
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $msg`n$stk`n" |
            Add-Content -Path $ERRORLOG -Encoding UTF8
    } catch {}

    Write-Host "`n  [ERROR] $msg" -ForegroundColor Red
    Write-Host "  Detail saved to: $ERRORLOG" -ForegroundColor DarkGray
    if ($env:VAF_DEBUG) { Write-Host $stk -ForegroundColor DarkRed }

    # cmd /c pause is the most reliable way to hold a window open
    cmd /c pause
    exit 1
}

# ── Load modules — guarded so errors surface instead of silent close ──────────
foreach ($mod in @('project','ai','images','media')) {
    $modPath = "$ROOT\modules\$mod.ps1"
    if (-not (Test-Path $modPath)) {
        Write-Host "  [FATAL] Missing module: $modPath" -ForegroundColor Red
        Read-Host '  Press Enter to exit'; exit 1
    }
    . $modPath
}

# ══════════════════════════════════════════════════════════════════════════════
# CONFIG  — Load, auto-migrate missing keys, validate
# ══════════════════════════════════════════════════════════════════════════════

function Get-ConfigDefaults {
    return [ordered]@{
        ai           = [ordered]@{
            primary       = 'openai'; fallback = 'gemini'; auto_fallback = $true
            openai        = [ordered]@{ model = 'gpt-4o-mini' }
            gemini        = [ordered]@{ model = 'gemini-2.5-flash'; timeout_seconds = 300 }
            huggingface   = [ordered]@{ model = 'meta-llama/Meta-Llama-3-8B-Instruct' }
        }
        api_keys     = [ordered]@{ openai = ''; elevenlabs = ''; gemini = ''; pollinations = ''; huggingface = '' }
        runtime      = [ordered]@{ run_as_admin = $false; theme = 'soft_dark'; startup_checks = $true }
        voice        = [ordered]@{ provider = 'elevenlabs'; voice_id = '21m00Tcm4TlvDq8ikWAM'; model_id = 'eleven_flash_v2_5'; social_media_only = $false; stability = 0.5; similarity_boost = 0.75; speed = 1.0; edge_voice = 'en-US-ChristopherNeural' }
        images       = [ordered]@{
            mode = 'auto_review'; provider = 'openai'; model = 'gpt-image-1.5'; size = '1536x1024'; quality = 'medium'
            aspect_ratio = '16:9'; image_size = '1K'; parallel = 1; retries = 2; fallback_to_manual = $true; auto_provider_fallback = $false
            pollinations_width = 1536; pollinations_height = 864; pollinations_seed = -1; pollinations_enhance = $false
            pollinations_safe = $true; pollinations_negative_prompt = 'text, watermark, logo, blurry, low quality'; composite_grid = 1; composite_layout = '1x1'
        }
        style_lock   = 'MS Paint style illustration, simple 2D cartoon, flat colors, rough digital marker lines, minimalist background'
        paths        = [ordered]@{ project_root = 'C:\AI_Video_Factory'; python_exe = 'python'; output_folder = 'C:\AI_Video_Factory\output' }
        audio        = [ordered]@{ silence_thresh_dbfs = -40; min_silence_len_ms = 400; keep_silence_ms = 100 }
        video        = [ordered]@{ fps = 24; codec = 'libx264'; threads = 4 }
        learning     = [ordered]@{ enabled = $true }
        notifications= [ordered]@{ script_ready = $true; images_detected = $true; voice_done = $true; audio_done = $true; render_done = $true }
    }
}

function Get-Config {
    param([string]$Path = "$ROOT\config\config.json")

    # ── Defaults (source of truth for schema) ─────────────────────────────────
    $defaults = Get-ConfigDefaults

    # ── Create fresh config if missing ────────────────────────────────────────
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
        $defaults | ConvertTo-Json -Depth 6 | Set-Content $Path -Encoding UTF8
        return $defaults | ConvertTo-Json -Depth 6 | ConvertFrom-Json
    }

    # ── Load and auto-migrate ─────────────────────────────────────────────────
    $cfg     = Get-Content $Path -Raw | ConvertFrom-Json
    $changed = $false

    # Safe property existence check — never throws under StrictMode
    $hasProp = { param($o,$n); $null -ne $o.PSObject.Properties[$n] }

    # Top-level blocks
    foreach ($key in $defaults.Keys) {
        if (-not (& $hasProp $cfg $key)) {
            $cfg | Add-Member -MemberType NoteProperty -Name $key `
                -Value ($defaults[$key] | ConvertTo-Json -Depth 6 | ConvertFrom-Json) -Force
            $changed = $true
        }
    }

    # Nested: ai sub-objects (ensure these exist before migrating nested keys)
    foreach ($sub in @('openai','gemini','huggingface')) {
        if (-not (& $hasProp $cfg.ai $sub)) {
            $cfg.ai | Add-Member -MemberType NoteProperty -Name $sub `
                -Value ($defaults.ai[$sub] | ConvertTo-Json | ConvertFrom-Json) -Force
            $changed = $true
        }
    }

    # Nested: property migrations for specific blocks
    foreach ($key in $defaults.ai.gemini.Keys) {
        if (-not (& $hasProp $cfg.ai.gemini $key)) {
            $cfg.ai.gemini | Add-Member -MemberType NoteProperty -Name $key -Value $defaults.ai.gemini[$key] -Force
            $changed = $true
        }
    }

    foreach ($key in $defaults.ai.huggingface.Keys) {
        if (-not (& $hasProp $cfg.ai.huggingface $key)) {
            $cfg.ai.huggingface | Add-Member -MemberType NoteProperty -Name $key -Value $defaults.ai.huggingface[$key] -Force
            $changed = $true
        }
    }

    # Migrate legacy 'codex' backend references to 'openai'
    foreach ($prop in @('primary', 'fallback')) {
        if (& $hasProp $cfg.ai $prop) {
            $normalized = Normalize-AIBackend "$($cfg.ai.$prop)"
            if ($normalized -ne "$($cfg.ai.$prop)") {
                $cfg.ai.$prop = $normalized
                $changed = $true
            }
        }
    }
    if (& $hasProp $cfg.ai 'codex') {
        $legacyModel = if (& $hasProp $cfg.ai.codex 'model') { $cfg.ai.codex.model } else { '' }
        if ($legacyModel -and -not [string]::IsNullOrWhiteSpace($legacyModel)) {
            if (-not (& $hasProp $cfg.ai.openai 'model') -or [string]::IsNullOrWhiteSpace($cfg.ai.openai.model)) {
                $cfg.ai.openai.model = $legacyModel
                $changed = $true
            }
        }
    }

    # Nested: api key additions from later versions
    foreach ($key in @('gemini','pollinations','huggingface')) {
        if (-not (& $hasProp $cfg.api_keys $key)) {
            $cfg.api_keys | Add-Member -MemberType NoteProperty -Name $key -Value '' -Force
            $changed = $true
        }
    }

    if (-not (& $hasProp $cfg.voice 'model_id')) {
        $cfg.voice | Add-Member -MemberType NoteProperty -Name 'model_id' -Value 'eleven_flash_v2_5' -Force
        $changed = $true
    }

    if (-not (& $hasProp $cfg.voice 'social_media_only')) {
        $cfg.voice | Add-Member -MemberType NoteProperty -Name 'social_media_only' -Value $false -Force
        $changed = $true
    }

    if (-not (& $hasProp $cfg.voice 'provider')) {
        $cfg.voice | Add-Member -MemberType NoteProperty -Name 'provider' -Value 'elevenlabs' -Force
        $changed = $true
    }

    if (-not (& $hasProp $cfg.voice 'edge_voice')) {
        $cfg.voice | Add-Member -MemberType NoteProperty -Name 'edge_voice' -Value 'en-US-ChristopherNeural' -Force
        $changed = $true
    }

    if (-not (& $hasProp $cfg 'runtime')) {
        $cfg | Add-Member -MemberType NoteProperty -Name 'runtime' -Value ($defaults.runtime | ConvertTo-Json -Depth 6 | ConvertFrom-Json) -Force
        $changed = $true
    }
    foreach ($key in $defaults.runtime.Keys) {
        if (-not (& $hasProp $cfg.runtime $key)) {
            $cfg.runtime | Add-Member -MemberType NoteProperty -Name $key -Value $defaults.runtime[$key] -Force
            $changed = $true
        }
    }

    foreach ($key in $defaults.images.Keys) {
        if (-not (& $hasProp $cfg.images $key)) {
            $cfg.images | Add-Member -MemberType NoteProperty -Name $key -Value $defaults.images[$key] -Force
            $changed = $true
        }
    }

    if ($changed) {
        $cfg | ConvertTo-Json -Depth 6 | Set-Content $Path -Encoding UTF8
        Write-Host '  [INFO] config.json upgraded with new defaults.' -ForegroundColor DarkYellow
    }

    return $cfg
}

function Test-ConfigReady {
    # Returns list of missing critical keys
    param([object]$Config)
    $m = @()
    $hp = { param($o,$n); $null -ne $o.PSObject.Properties[$n] }
    if (-not (& $hp $Config.api_keys 'openai')     -or [string]::IsNullOrWhiteSpace($Config.api_keys.openai))     { $m += 'OpenAI API key' }
    if (-not (& $hp $Config.api_keys 'elevenlabs') -or [string]::IsNullOrWhiteSpace($Config.api_keys.elevenlabs)) { $m += 'ElevenLabs API key' }
    return $m
}

# ══════════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════════

function Format-UiText {
    param($Text, [int]$Max = 70)
    $s = if ($null -eq $Text) { '' } else { "$Text" }
    $s = ($s -replace '\s+', ' ').Trim()
    if ($s.Length -le $Max) { return $s }
    return $s.Substring(0, [Math]::Max(0, $Max - 3)) + '...'
}

function Get-UiTheme {
    param([object]$Config = $null)
    $preset = 'soft_dark'
    try {
        if ($Config -and $Config.PSObject.Properties['runtime'] -and $Config.runtime.PSObject.Properties['theme']) {
            $preset = "$($Config.runtime.theme)"
        }
    } catch {}

    if ($preset -eq 'auto') {
        try {
            $bg = $Host.UI.RawUI.BackgroundColor
            $darkBackgrounds = @('Black','DarkBlue','DarkGreen','DarkCyan','DarkRed','DarkMagenta','DarkYellow','DarkGray')
            $preset = if ($darkBackgrounds -contains "$bg") { 'soft_dark' } else { 'light' }
        } catch {
            $preset = 'soft_dark'
        }
    }

    switch ($preset) {
        'dark' {
            return [PSCustomObject]@{ Accent='Cyan'; Text='White'; Note='Gray'; Muted='DarkGray'; Success='Green'; Warning='Yellow' }
        }
        'light' {
            return [PSCustomObject]@{ Accent='Blue'; Text='Black'; Note='DarkGray'; Muted='DarkGray'; Success='DarkGreen'; Warning='DarkYellow' }
        }
        'high_contrast' {
            return [PSCustomObject]@{ Accent='Yellow'; Text='White'; Note='Cyan'; Muted='Gray'; Success='Green'; Warning='Yellow' }
        }
        default {
            return [PSCustomObject]@{ Accent='Cyan'; Text='Gray'; Note='DarkGray'; Muted='DarkGray'; Success='Green'; Warning='DarkYellow' }
        }
    }
}

function Write-ControlBlock {
    param([string]$Text, [object]$Config = $null)
    $theme = Get-UiTheme -Config $Config
    Write-Host ''
    Write-Host "  Controls: $Text" -ForegroundColor $theme.Note
}

function Write-StatusBlock {
    param([object]$Config)
    $theme = Get-UiTheme -Config $Config
    $be    = if ($script:ActiveBackend) { $script:ActiveBackend } else { $Config.ai.primary }
    $fb    = $Config.ai.fallback
    $elSet = -not [string]::IsNullOrWhiteSpace($Config.api_keys.elevenlabs)
    $elStr = if ($elSet) { 'ready' } else { 'missing' }
    $elCol = if ($elSet) { $theme.Success } else { $theme.Warning }
    Write-Host ''
    Write-Host '  STATUS' -ForegroundColor $theme.Accent
    Write-Host ("  AI: {0}   Fallback: {1}   ElevenLabs: " -f $be, $fb) -NoNewline -ForegroundColor $theme.Text
    Write-Host $elStr -ForegroundColor $elCol
}

function Show-Banner {
    param([object]$Config)
    Clear-Host

    Write-Host ''
    $theme = Get-UiTheme -Config $Config
    Write-Host '  ╔══════════════════════════════════════╗' -ForegroundColor $theme.Accent
    Write-Host '  ║      AI VIDEO FACTORY  vA0.1         ║' -ForegroundColor $theme.Accent
    Write-Host '  ╚══════════════════════════════════════╝' -ForegroundColor $theme.Accent
    Write-StatusBlock -Config $Config
}

function Show-MainMenu {
    param([object]$Config)
    Show-Banner -Config $Config
    $theme = Get-UiTheme -Config $Config
    Write-Host ''
    Write-Host '  MAIN MENU' -ForegroundColor $theme.Accent
    Write-Host ''
    Write-Host '  [1] Create New Video'    -ForegroundColor $theme.Text
    Write-Host '  [2] Settings'            -ForegroundColor $theme.Text
    Write-Host '  [3] Check Dependencies'  -ForegroundColor $theme.Text
    Write-Host '  [4] Resume Unfinished Video' -ForegroundColor $theme.Text
    Write-Host '  [Q] Quit'                -ForegroundColor $theme.Text
    Write-ControlBlock -Text '[number] Select option   [Q] Quit' -Config $Config
}

# ══════════════════════════════════════════════════════════════════════════════
# PIPELINE
# ══════════════════════════════════════════════════════════════════════════════

# Maps phase name → numeric order for resume logic
$PHASE_ORDER = @{ script=1; prompts=2; images=3; voice=4; audio=5; render=6 }

function Invoke-ResumeMenu {
    param(
        [ValidateNotNull()][object]$Config,
        [string]$ConfigPath
    )

    $incomplete = @(Find-IncompleteProjects -OutputFolder $Config.paths.output_folder)
    Show-Banner -Config $Config

    if ($incomplete.Count -eq 0) {
        Write-Host '  No unfinished videos found.' -ForegroundColor Yellow
        Read-Host '  Press Enter to return'
        return
    }

    Write-Host ''
    $theme = Get-UiTheme -Config $Config
    Write-Host "  UNFINISHED VIDEOS ($($incomplete.Count))" -ForegroundColor $theme.Accent
    Write-Host ''
    for ($i = 0; $i -lt $incomplete.Count; $i++) {
        Write-Host ("  [{0}] {1,-42} phase: {2,-8} {3}" -f `
            ($i+1), (Format-UiText $incomplete[$i].Topic 42), $incomplete[$i].Phase, $incomplete[$i].Age) -ForegroundColor $theme.Text
    }
    Write-ControlBlock -Text '[number] Resume video   [B] Back' -Config $Config

    $pick = (Read-Host '  Resume which?').Trim().ToUpper()
    if ($pick -eq 'B' -or [string]::IsNullOrWhiteSpace($pick)) { return }
    if ($pick -match '^\d+$') {
        $idx = [int]$pick - 1
        if ($idx -ge 0 -and $idx -lt $incomplete.Count) {
            Start-VideoPipeline -Config $Config -ConfigPath $ConfigPath -ResumeState $incomplete[$idx]
            return
        }
    }

    Write-Host '  Invalid selection.' -ForegroundColor Red
    Start-Sleep 1
}

function Start-VideoPipeline {
    param(
        [ValidateNotNull()][object]$Config,
        [string]$ConfigPath,
        [PSCustomObject]$ResumeState = $null
    )

    # ── Setup ─────────────────────────────────────────────────────────────────
    $topic       = ''
    $projectPath = ''
    $startFrom   = 1

    if ($ResumeState) {
        $projectPath = $ResumeState.ProjectPath
        $topic       = $ResumeState.Topic
        $startFrom   = if ($PHASE_ORDER.ContainsKey($ResumeState.Phase)) { $PHASE_ORDER[$ResumeState.Phase] } else { 1 }
        Show-Banner -Config $Config
        Write-Host "  Resuming: '$topic'" -ForegroundColor Yellow
        Write-Host "  Starting from phase: $($ResumeState.Phase) ($startFrom/6)`n" -ForegroundColor White
    } else {
        Show-Banner -Config $Config
        Write-Host ''
        $theme = Get-UiTheme -Config $Config
        Write-Host '  CREATE NEW VIDEO' -ForegroundColor $theme.Accent
        Write-ControlBlock -Text '[B] Back   [Q] Quit' -Config $Config
        Write-Host ''
        $topic = (Read-Host '  Video topic').Trim()
        switch ($topic.ToUpper()) { 'Q' { return } 'B' { return } }
        if ([string]::IsNullOrWhiteSpace($topic)) {
            Write-Host '  Topic cannot be empty.' -ForegroundColor Red
            Start-Sleep 1; return
        }
        $projectPath = New-VideoProject -Topic $topic -Config $Config
        Write-Host "  Project: $projectPath`n" -ForegroundColor DarkGray
    }

    $logPath         = "$projectPath\session.log"
    $scriptPath      = "$projectPath\script_draft.txt"
    $rejectionReason = ''
    $totalTimer      = [Diagnostics.Stopwatch]::StartNew()

    Write-Log -Level INFO -Message "Pipeline started: topic='$topic' startFrom=$startFrom" -LogPath $logPath

    # ── Phase 1: Script ───────────────────────────────────────────────────────
    if ($startFrom -le 1) {
        Write-Host '[1/6] Script generation' -ForegroundColor Cyan

        $approved = $false
        while (-not $approved) {
            $sw         = [Diagnostics.Stopwatch]::StartNew()
            $scriptPath = Invoke-ScriptGeneration -Topic $topic -ProjectPath $projectPath `
                              -Config $Config -Root $ROOT -RejectionReason $rejectionReason

            Send-Toast -Title 'Video Factory' -Message 'Review script. Close editor when done.' -Config $Config -Key 'script_ready'

            $editor = Get-PreferredEditor
            $eArgs  = $editor.Args + @($scriptPath)
            Write-Host "    Opening in $($editor.Name)..." -ForegroundColor DarkGray

            $orig = Get-Content $scriptPath -Raw          # capture BEFORE user edits
            (Start-Process -FilePath $editor.Cmd -ArgumentList $eArgs -PassThru).WaitForExit()
            $edited = Get-Content $scriptPath -Raw        # capture AFTER user closes editor

            if ($orig -ne $edited -and $Config.learning.enabled) {
                Write-Host '    Changes detected — updating context files...' -ForegroundColor DarkYellow
                Invoke-Learning -Original $orig -Edited $edited -Config $Config -Root $ROOT
            }

            $choice = (Read-Host '    [A]pprove / [R]eject').Trim().ToUpper()
            if ($choice -eq 'A') {
                $approved = $true
                Write-Host ("    Approved  [{0:mm\:ss}]" -f $sw.Elapsed) -ForegroundColor DarkGray
                Write-Log -Level INFO -Message "Script approved after $([int]$sw.Elapsed.TotalSeconds)s" -LogPath $logPath
            } else {
                $rejectionReason = (Read-Host '    Reason? (Enter to skip)').Trim()
                Write-Host '    Regenerating...' -ForegroundColor DarkGray
                Write-Log -Level INFO -Message "Script rejected: '$rejectionReason'" -LogPath $logPath
            }
        }
        Set-PipelineState -ProjectPath $projectPath -Phase 'prompts'
    }

    # ── Phase 2: Prompts ──────────────────────────────────────────────────────
    if ($startFrom -le 2) {
        Write-Host "`n[2/6] Extracting image prompts" -ForegroundColor Cyan
        $sw = [Diagnostics.Stopwatch]::StartNew()
        Invoke-PromptExtraction -ProjectPath $projectPath -Config $Config -Root $ROOT
        Write-Host ("    Done  [{0:mm\:ss}]" -f $sw.Elapsed) -ForegroundColor DarkGray
        Set-PipelineState -ProjectPath $projectPath -Phase 'images'
    }

    # ── Phase 3: Images ───────────────────────────────────────────────────────
    if ($startFrom -le 3) {
        Write-Host "`n[3/6] Images" -ForegroundColor Cyan
        $scriptContent = Get-Content $scriptPath -Raw
        $expectedCount = @([regex]::Matches($scriptContent, '\[\d{2}:\d{2}')).Count
        if ($expectedCount -eq 0) { $expectedCount = 5 }

        Write-Host "    Expecting: $expectedCount image(s)" -ForegroundColor DarkGray
        Write-Host "    Folder:    $projectPath\images\" -ForegroundColor Yellow
        $imageResult = Invoke-ImageGeneration -ProjectPath $projectPath -Config $Config -ExpectedCount $expectedCount

        if ($imageResult.Completed) {
            Write-Host "    $($imageResult.Indexed) generated image(s) accepted. index.json written." -ForegroundColor Green
            Write-Log -Level INFO -Message "Images generated: $($imageResult.Indexed)" -LogPath $logPath
        } else {
            $fallback = if ($Config.PSObject.Properties['images'] -and $Config.images.PSObject.Properties['fallback_to_manual']) { [bool]$Config.images.fallback_to_manual } else { $true }
            if (-not $fallback) {
                if ($imageResult.PSObject.Properties['FatalError'] -and -not [string]::IsNullOrWhiteSpace($imageResult.FatalError)) {
                    throw "Automatic image generation stopped: $($imageResult.FatalError)"
                }
                throw "Automatic image generation did not complete and manual fallback is disabled."
            }
            Write-Host '    Waiting for manual image fixes...' -ForegroundColor Yellow
            Send-Toast -Title 'Video Factory' -Message "Drop/fix $expectedCount image(s) in the images folder." -Config $Config -Key 'images_detected'
            if ($imageResult.Failed -eq 0 -and $imageResult.Generated -ge $expectedCount) {
                Read-Host '    Press Enter after replacing any images you want to fix'
            }
            $n = Wait-ForImages -ProjectPath $projectPath -ExpectedCount $expectedCount
            Write-Host "    $n image(s) accepted. index.json written." -ForegroundColor Green
            Write-Log -Level INFO -Message "Images received manually: $n" -LogPath $logPath
        }
        Set-PipelineState -ProjectPath $projectPath -Phase 'voice'
    }

    # ── Phase 4: Voice ────────────────────────────────────────────────────────
    if ($startFrom -le 4) {
        Write-Host "`n[4/6] Generating voiceover" -ForegroundColor Cyan
        Invoke-VoiceGeneration -ProjectPath $projectPath -Config $Config
        Send-Toast -Title 'Video Factory' -Message 'Voiceover generated.' -Config $Config -Key 'voice_done'
        Set-PipelineState -ProjectPath $projectPath -Phase 'audio'
    }

    # ── Phase 5: Audio ────────────────────────────────────────────────────────
    if ($startFrom -le 5) {
        Write-Host "`n[5/6] Removing silences" -ForegroundColor Cyan
        Invoke-AudioProcessing -ProjectPath $projectPath -Config $Config -Root $ROOT
        Send-Toast -Title 'Video Factory' -Message 'Audio cleaned.' -Config $Config -Key 'audio_done'
        Set-PipelineState -ProjectPath $projectPath -Phase 'render'
    }

    # ── Phase 6: Render ───────────────────────────────────────────────────────
    Write-Host "`n[6/6] Rendering video" -ForegroundColor Cyan
    Invoke-VideoRender -ProjectPath $projectPath -Config $Config -Root $ROOT
    $totalTimer.Stop()

    Set-PipelineState -ProjectPath $projectPath -Phase 'complete'
    Send-Toast -Title 'Video Ready' -Message "$projectPath\master_output.mp4" -Config $Config -Key 'render_done'
    Write-Log -Level INFO -Message "Pipeline complete: $($totalTimer.Elapsed.ToString('mm\:ss'))" -LogPath $logPath

    # ── Completion screen ─────────────────────────────────────────────────────
    Write-Host ''
    Write-Host '  ╔══════════════════════════════════════╗' -ForegroundColor Green
    Write-Host '  ║  DONE — master_output.mp4 ready      ║' -ForegroundColor Green
    Write-Host '  ╚══════════════════════════════════════╝' -ForegroundColor Green
    Write-Host ("  Total time: {0}" -f $totalTimer.Elapsed.ToString('mm\:ss')) -ForegroundColor White
    Write-Host "  $projectPath\master_output.mp4" -ForegroundColor White
    Write-ControlBlock -Text '[O] Open folder   [P] Play video   [Enter] Back to menu' -Config $Config

    $action = (Read-Host '  Select').Trim().ToUpper()
    switch ($action) {
        'O' { Start-Process explorer.exe $projectPath }
        'P' { Start-Process "$projectPath\master_output.mp4" }
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

try {
    $configPath = "$ROOT\config\config.json"
    $config     = Get-Config -Path $configPath
    $startupChecks = if ($config.PSObject.Properties['runtime'] -and $config.runtime.PSObject.Properties['startup_checks']) {
        [bool]$config.runtime.startup_checks
    } else {
        $true
    }

    # ── Direct settings flag ──────────────────────────────────────────────────
    if ($Settings) {
        . "$ROOT\settings_menu.ps1"
        Invoke-SettingsMenu -Config $config -ConfigPath $configPath
        exit 0
    }

    # ── First-run: guide user to settings if keys missing ────────────────────
    $missing = @()
    if ($startupChecks) { $missing = @(Test-ConfigReady -Config $config) }
    if ($startupChecks -and @($missing).Count -gt 0) {
        Show-Banner -Config $config
        Write-Host "  Welcome! Setup required before your first video." -ForegroundColor Yellow
        Write-Host "  Missing: $($missing -join ', ')`n" -ForegroundColor Red
        if ((Read-Host '  Open settings now? [Y/N]') -match '^[Yy]') {
            . "$ROOT\settings_menu.ps1"
            Invoke-SettingsMenu -Config $config -ConfigPath $configPath
            $config  = Get-Config -Path $configPath
            $missing = @(Test-ConfigReady -Config $config)
        }
        if (@($missing).Count -gt 0) {
            Write-Host "`n  Still missing: $($missing -join ', ')." -ForegroundColor Red
            Write-Host '  Run main.ps1 again when ready.' -ForegroundColor DarkGray
            Read-Host '  Press Enter to exit'; exit 1
        }
        Show-Banner -Config $config
        Write-Host '  All set. Ready to make videos.' -ForegroundColor Green
        Start-Sleep 1
    }

    New-Item -ItemType Directory -Force -Path $config.paths.output_folder | Out-Null
    # ── Resume detection ──────────────────────────────────────────────────────
    if ($startupChecks) {
        $incomplete = @(Find-IncompleteProjects -OutputFolder $config.paths.output_folder)
        if ($incomplete.Count -gt 0) {
            Invoke-ResumeMenu -Config $config -ConfigPath $configPath
        }
    }

    # ── Main menu loop ────────────────────────────────────────────────────────
    $running = $true
    while ($running) {
        Show-MainMenu -Config $config
        $choice = (Read-Host '  Select').Trim().ToUpper()
        switch ($choice) {
            '1' {
                Start-VideoPipeline -Config $config -ConfigPath $configPath
                $config = Get-Config -Path $configPath   # reload in case settings changed
            }
            '2' {
                . "$ROOT\settings_menu.ps1"
                Invoke-SettingsMenu -Config $config -ConfigPath $configPath
                $config = Get-Config -Path $configPath
            }
            '3' {
                Show-Banner -Config $config
                Write-Host '  Checking dependencies...' -ForegroundColor Cyan
                Invoke-DepCheck -Config $config
                Read-Host '  Press Enter to return'
            }
            '4' {
                Invoke-ResumeMenu -Config $config -ConfigPath $configPath
                $config = Get-Config -Path $configPath
            }
            'Q' { $running = $false }
            default {
                Write-Host '  Invalid option.' -ForegroundColor Red
                Start-Sleep 1
            }
        }
    }

} catch {
    $msg = $_.Exception.Message
    $stk = $_.ScriptStackTrace
    try { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $msg`n$stk`n" | Add-Content -Path $ERRORLOG -Encoding UTF8 } catch {}
    Write-Host "`n  [ERROR] $msg" -ForegroundColor Red
    Write-Host "  Full detail saved to: $ERRORLOG" -ForegroundColor DarkGray
    if ($env:VAF_DEBUG) { Write-Host $stk -ForegroundColor DarkRed }
    cmd /c pause
    exit 1
}
