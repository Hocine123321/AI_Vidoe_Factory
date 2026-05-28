# =============================================================================
# media.ps1
# Sections: PROCESS RUNNER | TTS | AUDIO | VIDEO
# =============================================================================

# ══════════════════════════════════════════════════════════════════════════════
# PROCESS RUNNER  — Live stdout streaming, structured result
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-PythonScript {
    param(
        [ValidateNotNullOrEmpty()][string]$PyExe,
        [ValidateNotNull()][string[]]$Arguments,
        [string]$LogPath = ''
    )
    $psi = [System.Diagnostics.ProcessStartInfo]@{
        FileName               = $PyExe
        UseShellExecute        = $false
        RedirectStandardOutput = $true
        RedirectStandardError  = $true
        CreateNoWindow         = $true
    }
    foreach ($a in $Arguments) { $psi.ArgumentList.Add("$a") }

    $proc = [System.Diagnostics.Process]@{ StartInfo = $psi }
    $proc.Start() | Out-Null

    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    $proc.WaitForExit()

    $outText = $stdoutTask.GetAwaiter().GetResult().Trim()
    $errText = $stderrTask.GetAwaiter().GetResult().Trim()

    if ($outText) {
        $outText -split "`r?`n" | Where-Object { $_ } | ForEach-Object {
            Write-Host "      $_" -ForegroundColor DarkGray
            Write-Log -Level DEBUG -Message "[python] $_" -LogPath $LogPath
        }
    }

    if ($errText) { Write-Log -Level WARN -Message "[python stderr] $errText" -LogPath $LogPath }

    return [PSCustomObject]@{
        ExitCode = $proc.ExitCode
        Error    = $errText
        Success  = ($proc.ExitCode -eq 0)
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TTS  — ElevenLabs REST with spinner + retry
# ══════════════════════════════════════════════════════════════════════════════

function Get-HttpErrorBody {
    param($Response)
    if (-not $Response) { return '' }
    try {
        $stream = $Response.GetResponseStream()
        if (-not $stream) { return '' }
        $reader = [System.IO.StreamReader]::new($stream)
        $text = $reader.ReadToEnd()
        $reader.Dispose()
        return $text
    } catch {
        return ''
    }
}

function Invoke-ElevenLabsTtsRequest {
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Body,
        [string]$OutputPath
    )
    $client = [System.Net.Http.HttpClient]::new()
    try {
        foreach ($key in $Headers.Keys) {
            if ($key -in @('Content-Type')) { continue }
            [void]$client.DefaultRequestHeaders.Remove($key)
            [void]$client.DefaultRequestHeaders.TryAddWithoutValidation($key, [string]$Headers[$key])
        }
        $content = [System.Net.Http.StringContent]::new($Body, [System.Text.Encoding]::UTF8, 'application/json')
        $response = $client.PostAsync($Uri, $content).GetAwaiter().GetResult()
        $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
        $text = ''
        if (-not $response.IsSuccessStatusCode) {
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        } else {
            [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
        }
        return [PSCustomObject]@{
            Success = $response.IsSuccessStatusCode
            Status  = [int]$response.StatusCode
            Body    = $text
        }
    } finally {
        $client.Dispose()
    }
}

function Get-ElevenLabsErrorMessage {
    param([int]$Status, [string]$Body)
    if ([string]::IsNullOrWhiteSpace($Body)) { return "HTTP $Status" }
    try {
        $json = $Body | ConvertFrom-Json
        if ($json.detail) {
            $msg = if ($json.detail.message) { $json.detail.message } else { ($json.detail | ConvertTo-Json -Compress -Depth 5) }
            $code = if ($json.detail.code) { " [$($json.detail.code)]" } else { '' }
            $req = if ($json.detail.request_id) { " Request ID: $($json.detail.request_id)" } else { '' }
            return "$msg$code.$req"
        }
    } catch {}
    return $Body
}

function Invoke-VoiceGeneration {
    param(
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [ValidateNotNull()][object]$Config
    )
    $scriptPath = "$ProjectPath\script_draft.txt"
    $outputPath = "$ProjectPath\raw_voice.mp3"
    $logPath    = "$ProjectPath\session.log"

    if (-not (Test-Path $scriptPath)) { throw "script_draft.txt not found at $scriptPath" }

    # Strip timestamp headers while keeping same-line narration.
    $cleanText = (Get-Content $scriptPath -Raw) -split "`n" |
        ForEach-Object {
            ($_ -replace '^\s*\[\d{2}:\d{2}\s*-\s*\d{2}:\d{2}\]\s*(?:\([^)]*\):\s*)?', '').Trim()
        } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Join-String -Separator ' '

    if ([string]::IsNullOrWhiteSpace($cleanText)) {
        throw "Script produced no speakable text after stripping timestamps."
    }

    $provider = if ($Config.voice.PSObject.Properties['provider'] -and $Config.voice.provider) { $Config.voice.provider } else { 'elevenlabs' }

    if ($provider -eq 'edge-tts') {
        $edgeVoice = if ($Config.voice.PSObject.Properties['edge_voice'] -and $Config.voice.edge_voice) { $Config.voice.edge_voice } else { 'en-US-ChristopherNeural' }
        $spin = Start-Spinner "Edge TTS ($edgeVoice)"
        try {
            $edgeCmd = "edge-tts"
            $out = & $edgeCmd --voice $edgeVoice --text $cleanText --write-media $outputPath 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw ($out -join "`n")
            }
            Stop-Spinner $spin
            return [PSCustomObject]@{ Success=$true }
        } catch {
            Stop-Spinner $spin -Failed
            Write-Log -Level ERROR -Message "Edge TTS failed: $($_.Exception.Message)" -LogPath $logPath
            throw "Edge TTS generation failed."
        }
    }

    $body = @{
        text           = $cleanText
        model_id       = if ($Config.voice.PSObject.Properties['model_id'] -and $Config.voice.model_id) { $Config.voice.model_id } else { 'eleven_flash_v2_5' }
        voice_settings = @{
            stability        = $Config.voice.stability
            similarity_boost = $Config.voice.similarity_boost
            speed            = $Config.voice.speed
        }
    } | ConvertTo-Json -Depth 4

    $headers = @{
        'xi-api-key'   = $Config.api_keys.elevenlabs
        'Content-Type' = 'application/json'
        'Accept'       = 'audio/mpeg'
    }

    $maxRetries = 2
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        $spin = Start-Spinner "ElevenLabs TTS (attempt $attempt/$maxRetries)"
        try {
            $tts = Invoke-ElevenLabsTtsRequest `
                -Uri "https://api.elevenlabs.io/v1/text-to-speech/$($Config.voice.voice_id)" `
                -Headers $headers `
                -Body $body `
                -OutputPath $outputPath
            if (-not $tts.Success) {
                throw ([PSCustomObject]@{
                    Status = $tts.Status
                    Body   = $tts.Body
                } | ConvertTo-Json -Compress)
            }
            Stop-Spinner $spin
            break   # success
        } catch {
            Stop-Spinner $spin -Failed
            $errObj = $_.Exception.Message | ConvertFrom-Json -EA SilentlyContinue
            $resp = if ($_.Exception.PSObject.Properties['Response']) { $_.Exception.Response } else { $null }
            $code = if ($errObj -and $errObj.PSObject.Properties['Status']) { [int]$errObj.Status } elseif ($resp) { [int]$resp.StatusCode } else { 0 }
            $detail = if ($errObj -and $errObj.Body) { $errObj.Body } else { Get-HttpErrorBody -Response $resp }
            $friendly = Get-ElevenLabsErrorMessage -Status $code -Body $detail
            $detailForLog = if ($detail) { " Detail: $detail" } else { '' }
            Write-Log -Level WARN -Message "ElevenLabs attempt $attempt failed: HTTP $code.$detailForLog" -LogPath $logPath
            if ($code -eq 401) {
                throw "ElevenLabs TTS unauthorized (401): $friendly"
            }
            if ($code -eq 402) {
                if ($friendly -match 'library voices|paid_plan|free users cannot') {
                    Write-Host '      ElevenLabs blocked this voice on your plan (library voices need a paid API tier).' -ForegroundColor Yellow
                    if ((Read-Host '      Use free Edge TTS for this video instead? [Y/N]') -match '^[Yy]') {
                        $edgeVoice = if ($Config.voice.PSObject.Properties['edge_voice'] -and $Config.voice.edge_voice) {
                            $Config.voice.edge_voice
                        } else {
                            'en-US-ChristopherNeural'
                        }
                        $spinEdge = Start-Spinner "Edge TTS ($edgeVoice)"
                        try {
                            $edgeOut = & edge-tts --voice $edgeVoice --text $cleanText --write-media $outputPath 2>&1
                            if ($LASTEXITCODE -ne 0) { throw ($edgeOut -join "`n") }
                            Stop-Spinner $spinEdge
                            if (-not (Test-Path $outputPath) -or (Get-Item $outputPath).Length -lt 1024) {
                                throw 'Edge TTS did not produce a valid audio file.'
                            }
                            $sizeMb = '{0:N2} MB' -f ((Get-Item $outputPath).Length / 1MB)
                            Write-Host "      raw_voice.mp3 via Edge TTS  ($sizeMb)" -ForegroundColor DarkGray
                            Write-Log -Level INFO -Message "TTS complete via Edge fallback: $sizeMb" -LogPath $logPath
                            return
                        } catch {
                            Stop-Spinner $spinEdge -Failed
                            throw "Edge TTS fallback failed: $($_.Exception.Message)"
                        }
                    }
                }
                throw "ElevenLabs TTS payment/plan restriction (402): $friendly"
            }
            if ($code -eq 429) { throw "ElevenLabs rate limit (429). Wait before retrying." }
            if ($attempt -ge $maxRetries) { throw "ElevenLabs failed after $maxRetries attempts: HTTP $code" }
            Write-Host "      Retrying in 3s..." -ForegroundColor DarkGray
            Start-Sleep 3
        }
    }

    if (-not (Test-Path $outputPath) -or (Get-Item $outputPath).Length -lt 1024) {
        throw "raw_voice.mp3 was not created or is empty."
    }

    $sizeMb = '{0:N2} MB' -f ((Get-Item $outputPath).Length / 1MB)
    Write-Host "      raw_voice.mp3  ($sizeMb)" -ForegroundColor DarkGray
    Write-Log -Level INFO -Message "TTS complete: $sizeMb" -LogPath $logPath
}

# ══════════════════════════════════════════════════════════════════════════════
# AUDIO PROCESSING  — Silence removal via Python
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-AudioProcessing {
    param(
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNullOrEmpty()][string]$Root
    )
    $inputFile   = "$ProjectPath\raw_voice.mp3"
    $output  = "$ProjectPath\optimized_voice.mp3"
    $logPath = "$ProjectPath\session.log"

    if (-not (Test-Path $inputFile)) { throw "raw_voice.mp3 not found at $inputFile" }

    $result = Invoke-PythonScript `
        -PyExe     $Config.paths.python_exe `
        -Arguments @(
            "$Root\python\remove_silences.py",
            $inputFile, $output,
            $Config.audio.silence_thresh_dbfs,
            $Config.audio.min_silence_len_ms,
            $Config.audio.keep_silence_ms
        ) `
        -LogPath $logPath

    if (-not $result.Success) {
        throw "remove_silences.py exited $($result.ExitCode): $($result.Error)"
    }
    if (-not (Test-Path $output) -or (Get-Item $output).Length -lt 1024) {
        throw "optimized_voice.mp3 was not created or is empty."
    }

    $inMb  = '{0:N2} MB' -f ((Get-Item $inputFile).Length  / 1MB)
    $outMb = '{0:N2} MB' -f ((Get-Item $output).Length / 1MB)
    Write-Host "      $inMb → $outMb  (silence stripped)" -ForegroundColor DarkGray
    Write-Log -Level INFO -Message "Audio processed: $inMb → $outMb" -LogPath $logPath
}

# ══════════════════════════════════════════════════════════════════════════════
# VIDEO RENDER  — Final assembly via Python
# ══════════════════════════════════════════════════════════════════════════════

function Invoke-VideoRender {
    param(
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNullOrEmpty()][string]$Root
    )
    $indexFile = "$ProjectPath\index.json"
    $audioFile = "$ProjectPath\optimized_voice.mp3"
    $outFile   = "$ProjectPath\master_output.mp4"
    $logPath   = "$ProjectPath\session.log"

    if (-not (Test-Path $indexFile)) { throw "index.json not found — image gate may not have completed." }
    if (-not (Test-Path $audioFile)) { throw "optimized_voice.mp3 not found — audio processing may have failed." }

    # Verify all images in index still exist
    $index      = Get-Content $indexFile -Raw | ConvertFrom-Json
    $missingImg = @($index | Where-Object { -not (Test-Path "$ProjectPath\$_") })
    if ($missingImg.Count -gt 0) {
        throw "Render aborted — $($missingImg.Count) image(s) in index.json not found: $($missingImg -join ', ')"
    }

    Write-Log -Level INFO -Message "Render starting: $($index.Count) images, codec=$($Config.video.codec)" -LogPath $logPath

    $result = Invoke-PythonScript `
        -PyExe     $Config.paths.python_exe `
        -Arguments @(
            "$Root\python\assemble_video.py",
            $ProjectPath,
            $Config.video.fps,
            $Config.video.codec,
            $Config.video.threads
        ) `
        -LogPath $logPath

    if (-not $result.Success) {
        throw "assemble_video.py exited $($result.ExitCode): $($result.Error)"
    }
    if (-not (Test-Path $outFile) -or (Get-Item $outFile).Length -lt 1024) {
        throw "master_output.mp4 was not created or is empty."
    }

    $sizeMb = '{0:N2} MB' -f ((Get-Item $outFile).Length / 1MB)
    Write-Host "      master_output.mp4  ($sizeMb)" -ForegroundColor DarkGray
    Write-Log -Level INFO -Message "Render complete: $sizeMb" -LogPath $logPath
}
