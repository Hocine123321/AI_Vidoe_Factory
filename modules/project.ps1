# =============================================================================
# project.ps1
# Sections: LOGGING | ERRORS | SPINNER | NOTIFY | EDITOR | VALIDATION |
#           FILE MANAGER | IMAGE GATE | DEPS
# =============================================================================

# ══════════════════════════════════════════════════════════════════════════════
# LOGGING
# ══════════════════════════════════════════════════════════════════════════════

function Normalize-AIBackend {
    param([string]$Backend)
    if ([string]::IsNullOrWhiteSpace($Backend)) { return 'openai' }
    switch ($Backend.ToLower()) {
        'codex' { return 'openai' }
        'gpt3'  { return 'openai' }
        default { return $Backend.ToLower() }
    }
}

function Write-Log {
    param(
        [ValidateSet('INFO','WARN','ERROR','DEBUG')][string]$Level = 'INFO',
        [string]$Message,
        [string]$LogPath = ""
    )
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    if ($LogPath) {
        try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 -EA Stop }
        catch {} # log failure is never fatal
    }
    if ($Level -eq 'DEBUG' -and $env:VAF_DEBUG) {
        Write-Host "  [DBG] $Message" -ForegroundColor DarkGray
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# ERRORS  — Categorised, actionable, log-aware
# ══════════════════════════════════════════════════════════════════════════════

# Error categories used throughout the project
$script:ERR = @{
    CONFIG     = 'CONFIG'
    API        = 'API'
    FILESYSTEM = 'FILESYSTEM'
    PROCESS    = 'PROCESS'
    VALIDATION = 'VALIDATION'
    NETWORK    = 'NETWORK'
}

# Map raw exception messages to user-friendly text + fix hints
$script:ERROR_MAP = @(
    @{ Pattern='401';                     Category='API';        Hint='Check your API key in Settings → [1] API Keys.' }
    @{ Pattern='429|quota|rate.?limit|RESOURCE_EXHAUSTED|too many requests|limit exceeded';
                                          Category='API';        Hint='Rate limit hit. Wait or switch AI backend in Settings → [2].' }
    @{ Pattern='elevenlabs.*403|403.*elevenlabs';
                                          Category='API';        Hint='ElevenLabs key invalid or plan limit reached.' }
    @{ Pattern='raw_voice\.mp3';          Category='FILESYSTEM'; Hint='Voice file missing — ElevenLabs step may have failed.' }
    @{ Pattern='optimized_voice\.mp3';    Category='FILESYSTEM'; Hint='Audio processing failed — run dep check from main menu.' }
    @{ Pattern='master_output\.mp4';      Category='FILESYSTEM'; Hint='Render failed — moviepy or FFmpeg may be broken. Run dep check.' }
    @{ Pattern='script_draft\.txt';       Category='FILESYSTEM'; Hint='AI did not write script file — verify CLI is working.' }
    @{ Pattern='index\.json';             Category='FILESYSTEM'; Hint='Image index missing — image gate step did not complete.' }
    @{ Pattern='prompts\.txt';            Category='FILESYSTEM'; Hint='AI did not write prompts file — check CLI output.' }
    @{ Pattern='gemini.*(not found|not recognized|cannot be found)';
                                          Category='PROCESS';    Hint='Gemini CLI missing — see https://ai.google.dev/gemini-api/docs/gemini-cli' }
    @{ Pattern='python.*(not found|not recognized|cannot be found)';
                                          Category='PROCESS';    Hint='Python not found — update path in Settings → [5] Paths.' }
    @{ Pattern='ffmpeg.*(not found|not recognized)';
                                          Category='PROCESS';    Hint='FFmpeg missing: winget install Gyan.FFmpeg' }
    @{ Pattern='pydub|moviepy';           Category='PROCESS';    Hint='Python package missing — run dep check from main menu.' }
    @{ Pattern='Cannot find path|does not exist|not found';
                                          Category='FILESYSTEM'; Hint='Expected file or folder missing — check project folder integrity.' }
    @{ Pattern='network|connect|timeout|unreachable';
                                          Category='NETWORK';    Hint='Network issue — check internet connection.' }
)

function Resolve-AppError {
    # Takes a raw exception message, returns [category, friendly message, hint]
    param([string]$Message)
    foreach ($entry in $script:ERROR_MAP) {
        if ($Message -match $entry.Pattern) {
            return [PSCustomObject]@{
                Category = $entry.Category
                Message  = $Message
                Hint     = $entry.Hint
            }
        }
    }
    return [PSCustomObject]@{ Category = 'UNKNOWN'; Message = $Message; Hint = '' }
}

function Write-AppError {
    param([string]$Message, [string]$LogPath = "", [switch]$Fatal)
    $err = Resolve-AppError -Message $Message
    Write-Host ""
    Write-Host "  [$($err.Category)] $($err.Message)" -ForegroundColor Red
    if ($err.Hint) {
        Write-Host "  → $($err.Hint)" -ForegroundColor Yellow
    }
    Write-Log -Level ERROR -Message "[$($err.Category)] $Message" -LogPath $LogPath
    if ($Fatal) {
        Read-Host "`n  Press Enter to exit"
        exit 1
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# SPINNER  — Animated progress with elapsed timer
# ══════════════════════════════════════════════════════════════════════════════

function Start-Spinner {
    param([string]$Label)
    $sw = [Diagnostics.Stopwatch]::StartNew()

    # ThreadJob is built into PS7 — fallback for edge cases
    if (-not (Get-Command Start-ThreadJob -EA SilentlyContinue)) {
        Write-Host "  → $Label..." -ForegroundColor DarkGray
        return [PSCustomObject]@{ Job=$null; Cts=$null; Timer=$sw; Label=$Label; Fallback=$true }
    }

    $cts = [System.Threading.CancellationTokenSource]::new()
    $tok = $cts.Token
    $job = Start-ThreadJob -ScriptBlock {
        param($lbl, $tok)
        $frames = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $i  = 0
        try { [Console]::CursorVisible = $false } catch {}
        while (-not $tok.IsCancellationRequested) {
            [Console]::Write("`r    $($frames[$i % $frames.Count]) $lbl  $($sw.Elapsed.ToString('mm\:ss'))   ")
            $i++
            [System.Threading.Thread]::Sleep(80)
        }
        try { [Console]::CursorVisible = $true } catch {}
    } -ArgumentList $Label, $tok

    return [PSCustomObject]@{ Job=$job; Cts=$cts; Timer=$sw; Label=$Label; Fallback=$false }
}

function Stop-Spinner {
    param([PSCustomObject]$Spinner, [switch]$Failed)
    $elapsed = $Spinner.Timer.Elapsed.ToString('mm\:ss')
    $icon    = if ($Failed) { '✗' } else { '✓' }
    $color   = if ($Failed) { 'Red' } else { 'Green' }

    if (-not $Spinner.Fallback) {
        try { $Spinner.Cts.Cancel() } catch {}
        $Spinner.Job | Wait-Job -Timeout 2 | Out-Null
        $Spinner.Job | Remove-Job -Force -EA SilentlyContinue
        try { $Spinner.Cts.Dispose() } catch {}
    }
    Write-Host "`r    $icon $($Spinner.Label)  [$elapsed]               " -ForegroundColor $color
}

# ══════════════════════════════════════════════════════════════════════════════
# NOTIFY
# ══════════════════════════════════════════════════════════════════════════════

function Send-Toast {
    param([string]$Title, [string]$Message, [object]$Config, [string]$Key)
    # Check per-notification toggle
    if ($Config -and $Key -and $Config.PSObject.Properties['notifications']) {
        $notifs = $Config.notifications
        if ($notifs.PSObject.Properties[$Key] -and $notifs.$Key -eq $false) { return }
    }
    try {
        if (-not (Get-Module BurntToast -EA SilentlyContinue)) {
            if (-not (Get-Module -ListAvailable BurntToast -EA SilentlyContinue)) {
                Install-Module BurntToast -Force -Scope CurrentUser -EA SilentlyContinue | Out-Null
            }
            Import-Module BurntToast -EA Stop | Out-Null
        }
        New-BurntToastNotification -Text $Title, $Message -EA SilentlyContinue
    } catch {}
}

# ══════════════════════════════════════════════════════════════════════════════
# EDITOR DETECTION
# ══════════════════════════════════════════════════════════════════════════════

function Get-PreferredEditor {
    $candidates = @(
        @{ Name='VS Code';    Cmd='code';       Args=@('--wait') }
        @{ Name='Notepad++';  Cmd='notepad++';  Args=@('-multiInst','-notabbar','-nosession','-noPlugin') }
        @{ Name='Notepad';    Cmd='notepad';    Args=@() }
    )
    foreach ($e in $candidates) {
        if (Get-Command $e.Cmd -EA SilentlyContinue) { return $e }
    }
    return @{ Name='Notepad'; Cmd='notepad'; Args=@() }
}

# ══════════════════════════════════════════════════════════════════════════════
# VALIDATION
# ══════════════════════════════════════════════════════════════════════════════

function Test-ValidPng {
    param([string]$Path)
    try {
        if (-not (Test-Path $Path)) { return $false }
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        # PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
        return ($bytes.Count -ge 8 -and
                $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and
                $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47)
    } catch { return $false }
}

function Test-ValidImageFile {
    param([string]$Path)
    try {
        if (-not (Test-Path $Path)) { return $false }
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Count -lt 4) { return $false }
        $isPng = ($bytes.Count -ge 8 -and
                $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and
                $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47)
        $isJpeg = ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and
                $bytes[$bytes.Count - 2] -eq 0xFF -and $bytes[$bytes.Count - 1] -eq 0xD9)
        return ($isPng -or $isJpeg)
    } catch { return $false }
}

function Test-ScriptFormat {
    # Returns $true if script has at least one valid [MM:SS - MM:SS] block
    param([string]$Content)
    return ($Content -match '\[\d{2}:\d{2}\s*-\s*\d{2}:\d{2}\]')
}

function Get-ScriptStats {
    # Returns word count and estimated duration from script content
    param([string]$Content)
    $prose = ($Content -split "`n" |
              ForEach-Object {
                  ($_ -replace '^\s*\[\d{2}:\d{2}\s*-\s*\d{2}:\d{2}\]\s*(?:\([^)]*\):\s*)?', '').Trim()
              } |
              Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' '
    $words = @(($prose -split '\s+') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    $estSec = [Math]::Round($words / 2.5)
    return [PSCustomObject]@{ Words=$words; EstSeconds=$estSec }
}

# ══════════════════════════════════════════════════════════════════════════════
# FILE MANAGER
# ══════════════════════════════════════════════════════════════════════════════

function New-VideoProject {
    param(
        [ValidateNotNullOrEmpty()][string]$Topic,
        [ValidateNotNull()][object]$Config
    )
    $slug = ($Topic.ToLower() -replace '[^a-z0-9\s-]','' -replace '\s+','-' -replace '-{2,}','-').Trim('-')
    $slug = $slug.Substring(0, [Math]::Min($slug.Length, 40))
    $projectPath = Join-Path $Config.paths.output_folder "$(Get-Date -Format 'yyyy-MM-dd')_$slug"

    @($projectPath, "$projectPath\images") | ForEach-Object {
        New-Item -ItemType Directory -Force -Path $_ | Out-Null
    }

    # Init state file
    Set-PipelineState -ProjectPath $projectPath -Phase 'script' -Topic $Topic
    # Init session log
    $logPath = "$projectPath\session.log"
    Write-Log -Level INFO -Message "Project created: $projectPath" -LogPath $logPath
    Write-Log -Level INFO -Message "Topic: $Topic" -LogPath $logPath

    return $projectPath
}

function Set-PipelineState {
    param([string]$ProjectPath, [string]$Phase, [string]$Topic = "")
    $statePath = "$ProjectPath\pipeline_state.json"
    $state = if (Test-Path $statePath) {
        Get-Content $statePath -Raw | ConvertFrom-Json
    } else {
        [PSCustomObject]@{ topic=$Topic; project_path=$ProjectPath; phase=''; created=(Get-Date -Format 'o') }
    }
    $state | Add-Member -MemberType NoteProperty -Name phase        -Value $Phase                -Force
    $state | Add-Member -MemberType NoteProperty -Name last_updated -Value (Get-Date -Format 'o') -Force
    if ($Topic) { $state | Add-Member -MemberType NoteProperty -Name topic -Value $Topic -Force }
    $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
}

# Keep Update-PipelineState as alias for backwards compat with any stale calls
function Update-PipelineState {
    param([string]$ProjectPath, [string]$Phase)
    Set-PipelineState -ProjectPath $ProjectPath -Phase $Phase
}

function Get-PipelineState {
    param([string]$ProjectPath)
    $p = "$ProjectPath\pipeline_state.json"
    if (-not (Test-Path $p)) { return $null }
    return Get-Content $p -Raw | ConvertFrom-Json
}

function Find-IncompleteProjects {
    param([string]$OutputFolder)
    if (-not (Test-Path $OutputFolder)) { return @() }
    return @(
        Get-ChildItem $OutputFolder -Directory |
        Sort-Object LastWriteTime -Descending |   # newest first
        ForEach-Object {
            $sp = "$($_.FullName)\pipeline_state.json"
            if (Test-Path $sp) {
                $s = Get-Content $sp -Raw | ConvertFrom-Json -EA SilentlyContinue
                if ($s -and $s.PSObject.Properties['phase'] -and $s.phase -ne 'complete') {
                    $lastUpdatedProp = $s.PSObject.Properties['last_updated']
                    $createdProp     = $s.PSObject.Properties['created']
                    $topicProp       = $s.PSObject.Properties['topic']
                    $lu              = if ($lastUpdatedProp) { $lastUpdatedProp.Value } elseif ($createdProp) { $createdProp.Value } else { $null }
                    $lu              = if ($lu) { $lu } else { (Get-Date).ToString('o') }
                    $age    = New-TimeSpan -Start ([datetime]$lu) -End (Get-Date)
                    $ageStr = if ($age.TotalDays -ge 1)  { "$([int]$age.TotalDays)d ago" }
                             elseif ($age.TotalHours -ge 1) { "$([int]$age.TotalHours)h ago" }
                             else { "$([int]$age.TotalMinutes)m ago" }
                    $topic  = if ($topicProp) { $topicProp.Value } else { '(unknown)' }
                    [PSCustomObject]@{
                        ProjectPath = $_.FullName
                        Topic       = $topic
                        Phase       = $s.phase
                        Age         = $ageStr
                    }
                }
            }
        }
    )
}

# ══════════════════════════════════════════════════════════════════════════════
# IMAGE GATE
# ══════════════════════════════════════════════════════════════════════════════

function Wait-ForImages {
    param(
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [ValidateRange(1,100)][int]$ExpectedCount
    )
    $dir = "$ProjectPath\images"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    if (-not (Test-Path -LiteralPath $dir)) {
        throw "Images folder could not be created: $dir"
    }
    Start-Process explorer.exe $dir   # open folder for convenience

    # Build via constructor so Path is set before EnableRaisingEvents — a
    # hashtable initializer assigns properties in an unspecified order and can
    # enable the watcher while Path is still empty, throwing "Error reading the directory".
    $watcher = [System.IO.FileSystemWatcher]::new($dir, '*.*')
    $watcher.IncludeSubdirectories = $false
    $watcher.NotifyFilter          = [System.IO.NotifyFilters]'FileName,LastWrite'
    $watcher.EnableRaisingEvents    = $true

    $getCount = { @(Get-ChildItem $dir -File -EA SilentlyContinue | Where-Object { $_.Extension -match '^\.(png|jpg|jpeg)$' }).Count }

    while ((& $getCount) -lt $ExpectedCount) {
        $change = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]'Created,Changed', 5000)
        if (-not $change.TimedOut -and $change.Name) {
            Start-Sleep -Milliseconds 400   # let OS finish writing
            $path    = "$dir\$($change.Name)"
            if ([IO.Path]::GetExtension($path) -notmatch '^\.(png|jpg|jpeg)$') { continue }
            $valid   = Test-ValidImageFile -Path $path
            $size    = if (Test-Path $path) { '{0:N0} KB' -f ((Get-Item $path).Length / 1KB) } else { '?' }
            $current = & $getCount
            $icon    = if ($valid) { '✓' } else { '✗ INVALID' }
            $color   = if ($valid) { 'Green' } else { 'Red' }
            Write-Host ("    [{0}] {1,-30} {2,8}    [{3}/{4}]" -f $icon, $change.Name, $size, $current, $ExpectedCount) -ForegroundColor $color
        }
    }
    $watcher.Dispose()

    # Final validation sweep
    $invalid = @(Get-ChildItem $dir -File | Where-Object { $_.Extension -match '^\.(png|jpg|jpeg)$' -and -not (Test-ValidImageFile $_.FullName) })
    if ($invalid.Count -gt 0) {
        Write-Host "`n    [WARN] $($invalid.Count) invalid PNG(s) detected:" -ForegroundColor Yellow
        $invalid | ForEach-Object { Write-Host "      × $($_.Name)" -ForegroundColor Red }
        if ((Read-Host "    Continue with invalid files excluded? [Y/N]") -notmatch '^[Yy]') {
            throw "Image validation failed — user aborted."
        }
    }

    # Build index from valid files only, sorted
    $images = Get-ChildItem $dir -File |
              Where-Object { $_.Extension -match '^\.(png|jpg|jpeg)$' -and (Test-ValidImageFile $_.FullName) } |
              Sort-Object Name |
              ForEach-Object { "images\$($_.Name)" }

    if ($images.Count -eq 0) { throw "No valid PNG/JPEG images found in $dir" }

    $images | ConvertTo-Json | Set-Content "$ProjectPath\index.json" -Encoding UTF8
    return $images.Count
}

# ══════════════════════════════════════════════════════════════════════════════
# DEPENDENCY CHECK
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-DepCheck {
    param([ValidateNotNull()][object]$Config, [switch]$SilentIfOk)

    $py  = $Config.paths.python_exe
    $gem = if ($Config.PSObject.Properties['ai'] -and $Config.ai.PSObject.Properties['gemini']) {
               $Config.ai.gemini.cli_path } else { 'gemini' }

    $deps = @(
        @{ Name='Gemini CLI'; Ver={ & $gem --version 2>$null };  Check={ $? };  Install={ $null };                                                Method='manual'   }
        @{ Name='Python';     Ver={ & $py --version 2>$null };   Check={ $? };  Install={ winget install -e --id Python.Python.3.12 -h };         Method='winget'   }
        @{ Name='FFmpeg';     Ver={ (ffmpeg -version 2>$null | Select-Object -First 1) }; Check={ $? }; Install={ winget install -e --id Gyan.FFmpeg -h }; Method='winget' }
        @{ Name='pydub';      Ver={ & $py -c "import pydub; print('ok')" 2>$null };  Check={ $? }; Install={ & $py -m pip install pydub --break-system-packages -q };   Method='pip' }
        @{ Name='moviepy';    Ver={ & $py -c "import moviepy; print('ok')" 2>$null }; Check={ $? }; Install={ & $py -m pip install moviepy --break-system-packages -q }; Method='pip' }
        @{ Name='edge-tts';   Ver={ edge-tts --version 2>$null }; Check={ $? }; Install={ & $py -m pip install edge-tts --break-system-packages -q }; Method='pip' }
        @{ Name='BurntToast'; Ver={ (Get-Module -ListAvailable BurntToast -EA SilentlyContinue | Select-Object -First 1).Version }; Check={ $? }; Install={ Install-Module BurntToast -Scope CurrentUser -Force -EA SilentlyContinue }; Method='psmodule' }
    )

    Write-Host ""
    $missing = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($d in $deps) {
        $ver = try { & $d.Ver } catch { $null }
        $ok  = $null -ne $ver -and "$ver".Trim() -ne ''
        $verStr = if ($ok -and "$ver".Length -gt 0) { "  ($("$ver".Trim().Split("`n")[0]))" } else { '' }
        Write-Host ("  [{0}] {1,-14}{2}" -f $(if ($ok){'✓'}else{'✗'}), $d.Name, $verStr) `
            -ForegroundColor $(if ($ok){'Green'}else{'Red'})
        if (-not $ok) { $missing.Add($d) }
    }

    if ($missing.Count -eq 0) {
        if (-not $SilentIfOk) { Write-Host "`n  All dependencies satisfied.`n" -ForegroundColor Green }
        return
    }

    $names = ($missing | ForEach-Object { $_.Name }) -join ', '
    Write-Host "`n  Missing: $names" -ForegroundColor Yellow
    if ((Read-Host "`n  Auto-install what's possible? [Y/N]") -notmatch '^[Yy]') {
        Write-Host "  Skipped. Some features may not work.`n" -ForegroundColor DarkGray
        return
    }

    foreach ($d in $missing) {
        if ($d.Method -eq 'manual') {
            Write-Host "  [!] $($d.Name) requires manual install:" -ForegroundColor Yellow
            Write-Host "      https://ai.google.dev/gemini-api/docs/gemini-cli" -ForegroundColor DarkGray
            continue
        }
        Write-Host "  Installing $($d.Name)..." -ForegroundColor Cyan
        try {
            & $d.Install 2>&1 | Out-Null
            # Re-verify
            $ver = try { & $d.Ver } catch { $null }
            $ok  = $null -ne $ver -and "$ver".Trim() -ne ''
            Write-Host ("    {0} {1}" -f $(if ($ok){'✓ Done'}else{'✗ Failed'}), $d.Name) `
                -ForegroundColor $(if ($ok){'Green'}else{'Red'})
        } catch {
            Write-Host "    ✗ Install error: $_" -ForegroundColor Red
        }
    }
    Write-Host ""
}
