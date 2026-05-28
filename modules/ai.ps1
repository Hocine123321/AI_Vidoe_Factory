# =============================================================================
# ai.ps1
# Sections: STATE | BACKENDS | ROUTER | SCRIPT GENERATION | LEARNING
# =============================================================================

# ══════════════════════════════════════════════════════════════════════════════
# MODULE STATE
# ══════════════════════════════════════════════════════════════════════════════

$script:ActiveBackend  = $null   # session override — never written to disk
$script:QuotaKeywords  = @(
    'quota','rate_limit','rate limit','429','insufficient_quota',
    'RESOURCE_EXHAUSTED','too many requests','limit exceeded',
    'rate_limit_exceeded','quota exceeded','exceeded your current quota',
    'daily limit','usage limit','billing','payment required','402',
    'insufficient credits','not enough credits','credit balance',
    'balance','pollen','tokens exhausted','token limit'
)

# ══════════════════════════════════════════════════════════════════════════════
# BACKENDS
# ══════════════════════════════════════════════════════════════════════════════

function Get-GeminiRestAuth {
    param([ValidateNotNull()][object]$Config)
    $key = if ($Config.PSObject.Properties['api_keys'] -and $Config.api_keys.PSObject.Properties['gemini']) {
        $Config.api_keys.gemini
    } else {
        ''
    }
    if ([string]::IsNullOrWhiteSpace($key)) { throw "Gemini API key is missing." }
    return [PSCustomObject]@{
        Headers = @{ 'x-goog-api-key' = $key }
        Query   = "key=$([uri]::EscapeDataString($key))"
    }
}

function Invoke-OpenAIBackend {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$WorkDir,
        [ValidateNotNull()][object]$Config,
        [string]$Label = 'OpenAI'
    )
    $key = $Config.api_keys.openai
    if ([string]::IsNullOrWhiteSpace($key)) { return [PSCustomObject]@{ Success=$false; Output='OpenAI API key is missing.'; ExitCode=-1; Backend='openai' } }
    
    $model   = $Config.ai.openai.model
    if (-not $model) { $model = 'gpt-4o-mini' }

    Push-Location $WorkDir
    $spin = Start-Spinner "$Label ($model)"
    try {
        $uri = "https://api.openai.com/v1/chat/completions"
        $headers = @{
            'Authorization' = "Bearer $key"
            'Content-Type'  = 'application/json'
        }
        $body = @{
            model    = $model
            messages = @(
                @{ role = 'user'; content = $Prompt }
            )
        } | ConvertTo-Json -Depth 6

        $res = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body -TimeoutSec 300 -EA Stop
        
        $out = ''
        if ($res.choices -and $res.choices[0].message -and $res.choices[0].message.content) {
            $out = $res.choices[0].message.content.Trim()
        }
        
        if ([string]::IsNullOrWhiteSpace($out)) {
            throw "OpenAI returned no text."
        }

        Stop-Spinner $spin
        return [PSCustomObject]@{ Success=$true; Output=$out; ExitCode=0; Backend='openai' }
    } catch {
        Stop-Spinner $spin -Failed
        return [PSCustomObject]@{ Success=$false; Output=$_.Exception.Message; ExitCode=-1; Backend='openai' }
    } finally {
        Pop-Location
    }
}

function Invoke-GeminiBackend {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$WorkDir,
        [ValidateNotNull()][object]$Config,
        [string]$Label = 'Gemini'
    )
    $env:GEMINI_CLI_TRUST_WORKSPACE  = 'true'
    $cli   = $Config.ai.gemini.cli_path
    $model = $Config.ai.gemini.model
    $timeoutSec   = if ($Config.ai.gemini.PSObject.Properties['timeout_seconds']) { [int]$Config.ai.gemini.timeout_seconds } else { 300 }

    Push-Location $WorkDir
    $spin = Start-Spinner "$Label ($model)"
    try {
        $modelId = $model -replace '^models/', ''
        $auth = Get-GeminiRestAuth -Config $Config
        $uri = "https://generativelanguage.googleapis.com/v1beta/models/$([uri]::EscapeDataString($modelId)):generateContent"
        if ($auth.Query) { $uri += "?$($auth.Query)" }
        $body = @{
            contents = @(
                @{
                    role  = 'user'
                    parts = @(@{ text = $Prompt })
                }
            )
        } | ConvertTo-Json -Depth 8

        $res = Invoke-RestMethod -Uri $uri -Method POST -Headers $auth.Headers -ContentType 'application/json' -Body $body -TimeoutSec $timeoutSec -EA Stop
        $parts = @($res.candidates[0].content.parts | ForEach-Object { $_.text } | Where-Object { $_ })
        $out = ($parts -join "`n").Trim()
        if ([string]::IsNullOrWhiteSpace($out)) {
            $finish = if ($res.candidates -and $res.candidates[0].finishReason) { $res.candidates[0].finishReason } else { 'unknown' }
            $block  = if ($res.promptFeedback) { ($res.promptFeedback | ConvertTo-Json -Compress -Depth 5) } else { '' }
            if ($block) {
                throw "Gemini returned no text. FinishReason=$finish Feedback=$block"
            }
            throw "Gemini returned no text. FinishReason=$finish"
        }

        Stop-Spinner $spin
        return [PSCustomObject]@{ Success=$true; Output=$out; ExitCode=0; Backend='gemini' }
    } catch {
        Stop-Spinner $spin -Failed
        return [PSCustomObject]@{ Success=$false; Output=$_.Exception.Message; ExitCode=-1; Backend='gemini' }
    } finally {
        Pop-Location
    }
}

function Invoke-HuggingFaceBackend {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$WorkDir,
        [ValidateNotNull()][object]$Config,
        [string]$Label = 'Hugging Face'
    )
    $key = $Config.api_keys.huggingface
    if ([string]::IsNullOrWhiteSpace($key)) { return [PSCustomObject]@{ Success=$false; Output='Hugging Face API key is missing.'; ExitCode=-1; Backend='huggingface' } }
    
    $model   = $Config.ai.huggingface.model
    if (-not $model) { $model = 'meta-llama/Meta-Llama-3-8B-Instruct' }

    Push-Location $WorkDir
    $spin = Start-Spinner "$Label ($model)"
    try {
        $uri = "https://api-inference.huggingface.co/v1/chat/completions"
        $headers = @{
            'Authorization' = "Bearer $key"
            'Content-Type'  = 'application/json'
        }

        # Attempt to split system prompt from user prompt for better model adherence
        $messages = @()
        if ($Prompt -match '(?s)^(.*?)=== SYSTEM RULES ===(.*)$') {
            $systemPart = "You are a video script writer. Follow ALL instructions exactly.`n`n=== SYSTEM RULES ===" + $Matches[2]
            # Strip the system part from the prompt to get the user task
            $userPart = $Prompt
            if ($userPart -match '(?s)=== TASK ===(.*)$') {
                $userPart = "=== TASK ===" + $Matches[1]
            }
            $messages += @{ role = 'system'; content = $systemPart.Trim() }
            $messages += @{ role = 'user'; content = $userPart.Trim() }
        } else {
            $messages += @{ role = 'user'; content = $Prompt }
        }

        $body = @{
            model    = $model
            messages = $messages
            max_tokens = 2000
        } | ConvertTo-Json -Depth 6
        
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop
        $text = $response.choices[0].message.content
        Stop-Spinner $spin
        return [PSCustomObject]@{ Success=$true; Output=$text; ExitCode=0; Backend='huggingface' }
    } catch {
        Stop-Spinner $spin -Failed
        return [PSCustomObject]@{ Success=$false; Output=$_.Exception.Message; ExitCode=-1; Backend='huggingface' }
    } finally {
        Pop-Location
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# ROUTER  — Quota detection, session fallback, retry
# ══════════════════════════════════════════════════════════════════════════════

function Get-ActiveBackend {
    param([ValidateNotNull()][object]$Config)
    if ($script:ActiveBackend) { return $script:ActiveBackend }
    return $Config.ai.primary
}

function Test-IsQuotaError {
    param([string]$Output)
    if ([string]::IsNullOrWhiteSpace($Output)) { return $false }
    $normalized = $Output
    try {
        $json = $Output | ConvertFrom-Json
        $normalized = ($json | ConvertTo-Json -Compress -Depth 8)
    } catch {}
    foreach ($kw in $script:QuotaKeywords) {
        if ($normalized -imatch [regex]::Escape($kw)) { return $true }
    }
    return $false
}

function Invoke-AI {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$WorkDir,
        [ValidateNotNull()][object]$Config,
        [string]$Label    = 'AI',
        [string]$LogPath  = '',
        [int]$MaxRetries  = 1
    )

    $backend = Get-ActiveBackend -Config $Config
    $attempt = 0

    while ($attempt -le $MaxRetries) {
        $attempt++
        Write-Log -Level DEBUG -Message "Invoke-AI attempt $attempt via $backend — $Label" -LogPath $LogPath

        $result = switch ($backend) {
            'openai'      { Invoke-OpenAIBackend -Prompt $Prompt -WorkDir $WorkDir -Config $Config -Label $Label }
            'gemini'      { Invoke-GeminiBackend -Prompt $Prompt -WorkDir $WorkDir -Config $Config -Label $Label }
            'huggingface' { Invoke-HuggingFaceBackend -Prompt $Prompt -WorkDir $WorkDir -Config $Config -Label $Label }
            default       { throw "[AI] Unknown backend '$backend'" }
        }

        if ($result.Success) {
            Write-Log -Level INFO -Message "AI call succeeded via $backend — $Label" -LogPath $LogPath
            return $result
        }

        Write-Log -Level WARN -Message "AI call failed (exit $($result.ExitCode)) via ${backend}: $($result.Output)" -LogPath $LogPath

        # Quota path — offer fallback
        if ((Test-IsQuotaError -Output $result.Output) -and $Config.ai.auto_fallback) {
            $fallback = $Config.ai.fallback
            if ($fallback -eq $backend) { break }

            Send-Toast -Title 'Video Factory' -Message "$backend quota hit. Fallback: $fallback" -Config $Config -Key 'script_ready'
            Write-Host "`n  [!] $backend hit rate limit / quota." -ForegroundColor Yellow
            Write-Host "      Fallback available: $fallback" -ForegroundColor Cyan

            if ((Read-Host "      Switch to $fallback for this session? [Y/N]") -match '^[Yy]') {
                $script:ActiveBackend = $fallback
                $backend = $fallback
                $attempt = 0   # reset retry counter for new backend
                Write-Host "      Switched to $fallback.`n" -ForegroundColor Green
                Write-Log -Level INFO -Message "Backend switched to $fallback for session" -LogPath $LogPath
                continue
            }
        }

        # Retry on transient error (not quota)
        if ($attempt -le $MaxRetries) {
            Write-Host "    Retrying ($attempt/$MaxRetries)..." -ForegroundColor DarkGray
            Start-Sleep -Seconds (2 * $attempt)
        }
    }

    throw "[AI] $backend failed after $MaxRetries attempt(s): $($result.Output)"
}

# ══════════════════════════════════════════════════════════════════════════════
# SCRIPT GENERATION
# ══════════════════════════════════════════════════════════════════════════════

function Remove-AnsiText {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    return ($Text -replace "`e\[[0-9;?]*[ -/]*[@-~]", '').Trim()
}

function Get-ScriptTextFromAIOutput {
    param([string]$Output)
    $clean = Remove-AnsiText -Text $Output
    $lines = @(
        $clean -split "`r?`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\[\d{2}:\d{2}\s*-\s*\d{2}:\d{2}\]' }
    )
    if ($lines.Count -gt 0) { return ($lines -join "`r`n") }

    $fenced = [regex]::Match($clean, '(?s)```(?:text|txt)?\s*(.*?)```')
    if ($fenced.Success) { return $fenced.Groups[1].Value.Trim() }

    return $clean
}

function Get-PromptTextFromAIOutput {
    param([string]$Output)
    $clean = Remove-AnsiText -Text $Output
    $lines = @(
        $clean -split "`r?`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d+[\.\)]\s+' }
    )
    if ($lines.Count -gt 0) { return ($lines -join "`r`n") }

    $fenced = [regex]::Match($clean, '(?s)```(?:text|txt)?\s*(.*?)```')
    if ($fenced.Success) { return $fenced.Groups[1].Value.Trim() }

    return $clean
}

function Invoke-ScriptGeneration {
    param(
        [ValidateNotNullOrEmpty()][string]$Topic,
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNullOrEmpty()][string]$Root,
        [string]$RejectionReason = ''
    )
    $ctx        = "$Root\context"
    $scriptPath = "$ProjectPath\script_draft.txt"
    $logPath    = "$ProjectPath\session.log"

    $sysCtx   = Get-Content "$ctx\System.md"              -Raw -EA SilentlyContinue
    $sceneCtx = Get-Content "$ctx\scene_descriptions.md"  -Raw -EA SilentlyContinue
    $exCtx    = Get-Content "$ctx\script_examples.md"     -Raw -EA SilentlyContinue

    $rejSection = if ($RejectionReason.Trim()) {
        "`n=== PREVIOUS DRAFT REJECTED ===`nReason given by user: $RejectionReason`nMust address this in the new version.`n"
    } else { '' }

    $prompt = @"
You are a video script writer. Follow ALL instructions exactly.

=== SYSTEM RULES ===
$sysCtx

=== VISUAL STYLE GUIDE ===
$sceneCtx

=== FORMAT REFERENCE ===
$exCtx
$rejSection
=== TASK ===
Topic: "$Topic"

Requirements:
- Use this exact timestamp format on every line: [MM:SS - MM:SS] (Label): text
- Every block = one visual scene = approximately 3 seconds
- Total script = 30 seconds (10 scenes max)
- Total narration must be 60 to 75 words.
- Hook in the very first block — no warmup
- Do NOT include image style tags, art direction, or visual prompt text in the narration.
- Return ONLY the script text. Zero preamble, commentary, markdown, or code fences.
"@

    $result = Invoke-AI -Prompt $prompt -WorkDir $ProjectPath -Config $Config -Label 'Generating script' -LogPath $logPath
    $scriptText = Get-ScriptTextFromAIOutput -Output $result.Output
    if ($Config.PSObject.Properties['style_lock'] -and -not [string]::IsNullOrWhiteSpace($Config.style_lock)) {
        $stylePattern = [regex]::Escape($Config.style_lock)
        $scriptText = ($scriptText -replace "\s*$stylePattern\.?", '').Trim()
    }
    if (-not [string]::IsNullOrWhiteSpace($scriptText)) {
        $scriptText | Set-Content $scriptPath -Encoding UTF8
    }

    # Validate output exists and has correct format
    if (-not (Test-Path $scriptPath)) {
        throw "[SCRIPT] AI did not create script_draft.txt"
    }
    $content = Get-Content $scriptPath -Raw
    if (-not (Test-ScriptFormat -Content $content)) {
        Write-Host "    [WARN] Script may not follow timestamp format — review carefully." -ForegroundColor Yellow
        Write-Log -Level WARN -Message "Script format validation failed" -LogPath $logPath
    }

    # Stats
    $stats  = Get-ScriptStats -Content $content
    $delta  = $stats.EstSeconds - 30
    $dStr   = if ($delta -gt 5) { "+${delta}s — too long" } elseif ($delta -lt -5) { "${delta}s — too short" } else { 'on target ✓' }
    $dColor = if ([Math]::Abs($delta) -le 5) { 'Green' } else { 'Yellow' }
    Write-Host ("    Words: {0}  |  Est. duration: ~{1}s  ({2})" -f $stats.Words, $stats.EstSeconds, $dStr) -ForegroundColor $dColor
    Write-Log -Level INFO -Message "Script generated: $($stats.Words) words, ~$($stats.EstSeconds)s" -LogPath $logPath

    return $scriptPath
}

function Invoke-PromptExtraction {
    param(
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNullOrEmpty()][string]$Root
    )
    $scriptText  = Get-Content "$ProjectPath\script_draft.txt" -Raw
    $promptsPath = "$ProjectPath\prompts.txt"
    $logPath     = "$ProjectPath\session.log"
    $layoutText = '1x1'
    $rows = 1
    $cols = 1
    try {
        if ($Config.PSObject.Properties['images']) {
            if ($Config.images.PSObject.Properties['composite_layout'] -and "$($Config.images.composite_layout)" -match '^(\d+)x(\d+)$') {
                $rows = [Math]::Min(2, [Math]::Max(1, [int]$Matches[1]))
                $cols = [Math]::Min(2, [Math]::Max(1, [int]$Matches[2]))
            } elseif ($Config.images.PSObject.Properties['composite_grid']) {
                $grid = [Math]::Min(2, [Math]::Max(1, [int]$Config.images.composite_grid))
                $rows = $grid
                $cols = $grid
            }
        }
    } catch {
        $rows = 1
        $cols = 1
    }
    $layoutText = "${rows}x${cols}"
    $panelCount = $rows * $cols
    $positions = if ($rows -eq 1 -and $cols -eq 2) {
        'left, right'
    } elseif ($rows -eq 2 -and $cols -eq 1) {
        'top, bottom'
    } else {
        'top-left, top-right, bottom-left, bottom-right'
    }

    if ($panelCount -gt 1) {
        $prompt = @"
Read the following video script and create image generation prompts for composite image batches.

SCRIPT:
$scriptText

RULES:
- Each timestamp block is one final scene image.
- Group timestamp blocks in order into batches of $panelCount scenes.
- Output ONLY a JSON array. No markdown, no prose, no code fences.
- Each JSON object must have:
  - "indices": the final scene numbers included in this batch.
  - "prompt": one prompt that asks the image model to create a clean $layoutText grid.
- The prompt must clearly assign each scene to its panel position: $positions.
- If the final batch has fewer than $panelCount scenes, fill unused panels with a simple matching empty background, but do NOT include those filler panels in "indices".
- Every panel must be a separate scene with clear separation lines.
- No text, labels, numbers, logos, watermarks, or captions inside the image.
- Append this exact style tag inside every panel description: "$($Config.style_lock)"
- Keep each batch prompt concise enough for an image API URL.

Example:
[
  {
    "indices": [1,2],
    "prompt": "Create one clean $layoutText image grid with $panelCount equal panels and thin clear separation lines. Use panel positions: $positions. First panel: ... $($Config.style_lock). Second panel: ... $($Config.style_lock). No text, labels, numbers, logos, or watermarks."
  }
]
"@
    } else {
        $prompt = @"
Read the following video script and extract one image generation prompt per timestamp block.

SCRIPT:
$scriptText

RULES:
- Exactly one prompt per [MM:SS - MM:SS] block.
- Each prompt describes a single concrete visual subject — no abstract concepts, no crowds.
- Append this exact style tag to every prompt: "$($Config.style_lock)"
- Output ONLY a numbered list, one prompt per line. Example:
  1. A glowing CPU chip on a dark surface. $($Config.style_lock)
  2. A speedometer pinned to maximum. $($Config.style_lock)
- No headers, no preamble, no markdown, no extra text.
"@
    }

    $result = Invoke-AI -Prompt $prompt -WorkDir $ProjectPath -Config $Config -Label 'Extracting prompts' -LogPath $logPath
    $promptText = Get-PromptTextFromAIOutput -Output $result.Output
    if (-not [string]::IsNullOrWhiteSpace($promptText)) {
        $promptText | Set-Content $promptsPath -Encoding UTF8
    }

    if (-not (Test-Path $promptsPath)) {
        throw "[PROMPTS] AI did not create prompts.txt"
    }

    $lineCount = @(Get-Content $promptsPath -EA SilentlyContinue).Count
    Write-Host "    $lineCount prompt(s) written." -ForegroundColor DarkGray
    Write-Log -Level INFO -Message "Prompts extracted: $lineCount lines" -LogPath $logPath

    # Auto-open in preferred editor (non-blocking)
    $editor = Get-PreferredEditor
    $eArgs  = $editor.Args + @($promptsPath)
    Start-Process -FilePath $editor.Cmd -ArgumentList $eArgs -EA SilentlyContinue

    # Clipboard offer
    if ((Read-Host "    Copy all prompts to clipboard? [Y/N]") -match '^[Yy]') {
        Get-Content $promptsPath | Set-Clipboard
        Write-Host "    ✓ Copied to clipboard." -ForegroundColor Green
    }
}

# LEARNING  — Diff user edits & OpenAI rewrites context files
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-Learning {
    param(
        [string]$Original,
        [string]$Edited,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNullOrEmpty()][string]$Root
    )
    if (-not $Config.learning.enabled) { return }
    if ($Original -eq $Edited)         { return }

    # Build compact line-by-line diff
    $oLines = $Original -split "`n"
    $eLines = $Edited   -split "`n"
    $max    = [Math]::Max($oLines.Count, $eLines.Count)
    $diff   = @(for ($i = 0; $i -lt $max; $i++) {
        $o = if ($i -lt $oLines.Count) { $oLines[$i].Trim() } else { '(removed)' }
        $e = if ($i -lt $eLines.Count) { $eLines[$i].Trim() } else { '(removed)' }
        if ($o -ne $e) { "Line $($i+1):`n  - $o`n  + $e" }
    })
    if ($diff.Count -eq 0) { return }

    $ctx     = "$Root\context"
    $logPath = "$Root\learning.log"

    $prompt = @"
You are a self-improving script generation system. A human editor modified a generated script.
Your job: analyze their edits and surgically update the context files to permanently encode their preferences.

=== DIFFS (- removed, + added) ===
$($diff -join "`n")

=== CURRENT System.md ===
$(Get-Content "$ctx\System.md" -Raw -EA SilentlyContinue)

=== CURRENT scene_descriptions.md ===
$(Get-Content "$ctx\scene_descriptions.md" -Raw -EA SilentlyContinue)

=== CURRENT script_examples.md ===
$(Get-Content "$ctx\script_examples.md" -Raw -EA SilentlyContinue)

RULES:
- Update ONLY files where a genuine preference is revealed by the edits.
- Make surgical changes — do not rewrite files completely unless absolutely necessary.
- Do not add commentary, explanations, or metadata to the files.
- Save the updated file(s) directly.
"@

    Write-Log -Level INFO -Message "Learning: $($diff.Count) diff(s) detected" -LogPath $logPath
    Write-Log -Level DEBUG -Message ($diff -join ' | ') -LogPath $logPath

    Invoke-AI -Prompt $prompt -WorkDir $ctx -Config $Config -Label 'Updating context' -LogPath $logPath | Out-Null
    Write-Host "    Context files updated from your edits." -ForegroundColor DarkGreen
    Write-Log -Level INFO -Message "Context files updated" -LogPath $logPath
}
