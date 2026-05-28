# =============================================================================
# images.ps1
# Automatic image generation + manual fallback support
# =============================================================================

function Get-VafProp {
    param([object]$Obj, [string]$Name, $Default = '')
    if ($null -eq $Obj) { return $Default }
    if (-not $Obj.PSObject.Properties[$Name]) { return $Default }
    $v = $Obj.$Name
    if ($null -eq $v) { return $Default }
    return $v
}

function Get-CompositeLayoutParts {
    param([object]$Settings)

    $layout = ''
    if ($Settings -and $Settings.PSObject.Properties['CompositeLayout']) { $layout = "$($Settings.CompositeLayout)" }
    if ([string]::IsNullOrWhiteSpace($layout) -and $Settings -and $Settings.PSObject.Properties['CompositeGrid']) {
        $grid = [Math]::Max(1, [int]$Settings.CompositeGrid)
        $layout = "${grid}x${grid}"
    }
    if ([string]::IsNullOrWhiteSpace($layout)) { $layout = '1x1' }
    $match = [regex]::Match($layout, '^(\d+)x(\d+)$')
    if (-not $match.Success) {
        $layout = '1x1'
        $match = [regex]::Match($layout, '^(\d+)x(\d+)$')
    }

    $rows = [Math]::Max(1, [int]$match.Groups[1].Value)
    $cols = [Math]::Max(1, [int]$match.Groups[2].Value)
    $rows = [Math]::Min(2, $rows)
    $cols = [Math]::Min(2, $cols)
    return [PSCustomObject]@{
        Layout = "${rows}x${cols}"
        Rows   = $rows
        Cols   = $cols
        Count  = $rows * $cols
    }
}

function Get-ImageSettings {
    param([object]$Config)
    $img = Get-VafProp $Config 'images' $null
    return [PSCustomObject]@{
        Mode             = Get-VafProp $img 'mode' 'auto_review'
        Provider         = Get-VafProp $img 'provider' 'openai'
        Model            = Get-VafProp $img 'model' 'gpt-image-1.5'
        Size             = Get-VafProp $img 'size' '1536x1024'
        Quality          = Get-VafProp $img 'quality' 'medium'
        AspectRatio      = Get-VafProp $img 'aspect_ratio' '16:9'
        ImageSize        = Get-VafProp $img 'image_size' '1K'
        Parallel         = [Math]::Max(1, [int](Get-VafProp $img 'parallel' 1))
        Retries          = [Math]::Max(0, [int](Get-VafProp $img 'retries' 2))
        FallbackToManual = [bool](Get-VafProp $img 'fallback_to_manual' $true)
        AutoProviderFallback = [bool](Get-VafProp $img 'auto_provider_fallback' $false)
        PollinationsWidth = [Math]::Max(256, [int](Get-VafProp $img 'pollinations_width' 1536))
        PollinationsHeight = [Math]::Max(256, [int](Get-VafProp $img 'pollinations_height' 864))
        PollinationsSeed = [int](Get-VafProp $img 'pollinations_seed' -1)
        PollinationsEnhance = [bool](Get-VafProp $img 'pollinations_enhance' $false)
        PollinationsSafe = [bool](Get-VafProp $img 'pollinations_safe' $true)
        PollinationsNegativePrompt = Get-VafProp $img 'pollinations_negative_prompt' 'text, watermark, logo, blurry, low quality'
        CompositeGrid    = [Math]::Min(2, [Math]::Max(1, [int](Get-VafProp $img 'composite_grid' 1)))
        CompositeLayout  = Get-VafProp $img 'composite_layout' ''
    }
}

function Get-ImagePrompts {
    param([ValidateNotNullOrEmpty()][string]$ProjectPath)

    $path = Join-Path $ProjectPath 'prompts.txt'
    if (-not (Test-Path $path)) { throw "[IMAGES] prompts.txt not found." }

    $raw = (Get-Content $path -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "[IMAGES] prompts.txt is empty." }

    if ($raw.StartsWith('[')) {
        try {
            $json = $raw | ConvertFrom-Json
            $i = 0
            return @($json | ForEach-Object {
                $i++
                $prompt = if ($_.PSObject.Properties['prompt']) { "$($_.prompt)" } else { "$_" }
                if (-not [string]::IsNullOrWhiteSpace($prompt)) {
                    $indices = @()
                    if ($_.PSObject.Properties['indices']) {
                        $indices = @($_.indices | ForEach-Object { [int]$_ } | Where-Object { $_ -gt 0 })
                    } elseif ($_.PSObject.Properties['index']) {
                        $indices = @([int]$_.index)
                    }
                    $index = if ($indices.Count -gt 0) { $indices[0] } else { $i }
                    [PSCustomObject]@{ Index=$index; Prompt=$prompt.Trim(); Indices=$indices; BatchIndex=$i }
                }
            })
        } catch {
            Write-Log -Level WARN -Message "prompts.txt looked like JSON but could not be parsed; falling back to numbered lines." -LogPath (Join-Path $ProjectPath 'session.log')
        }
    }

    $items = @()
    $index = 0
    foreach ($line in Get-Content $path) {
        $prompt = ($line -replace '^\s*(?:[-*]|\d+[\.\)])\s*', '').Trim()
        if ([string]::IsNullOrWhiteSpace($prompt)) { continue }
        $index++
        $items += [PSCustomObject]@{ Index=$index; Prompt=$prompt }
    }
    return @($items)
}

function Save-Base64Image {
    param(
        [ValidateNotNullOrEmpty()][string]$Base64,
        [ValidateNotNullOrEmpty()][string]$Path
    )
    $bytes = [Convert]::FromBase64String($Base64)
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function Split-CompositeImage {
    param(
        [ValidateNotNullOrEmpty()][string]$CompositePath,
        [ValidateNotNullOrEmpty()][string]$OutDir,
        [ValidateNotNull()][int[]]$Indices,
        [int]$Rows = 2,
        [int]$Cols = 2
    )

    Add-Type -AssemblyName System.Drawing
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($CompositePath)
        $Rows = [Math]::Max(1, $Rows)
        $Cols = [Math]::Max(1, $Cols)
        $tileW = [Math]::Floor($bitmap.Width / $Cols)
        $tileH = [Math]::Floor($bitmap.Height / $Rows)
        if ($tileW -lt 16 -or $tileH -lt 16) { throw "Composite image is too small to split safely." }

        $trimX = [Math]::Min(8, [Math]::Floor($tileW * 0.015))
        $trimY = [Math]::Min(8, [Math]::Floor($tileH * 0.015))
        for ($tile = 0; $tile -lt $Indices.Count; $tile++) {
            $row = [Math]::Floor($tile / $Cols)
            $col = $tile % $Cols
            $x = [int]($col * $tileW + $trimX)
            $y = [int]($row * $tileH + $trimY)
            $w = [int]($tileW - ($trimX * 2))
            $h = [int]($tileH - ($trimY * 2))
            if ($w -lt 16 -or $h -lt 16) { throw "Composite crop area is too small." }

            $rect = [System.Drawing.Rectangle]::new($x, $y, $w, $h)
            $crop = $bitmap.Clone($rect, $bitmap.PixelFormat)
            try {
                $outPath = Join-Path $OutDir ('{0:D3}.png' -f [int]$Indices[$tile])
                $crop.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
            } finally {
                if ($crop) { $crop.Dispose() }
            }
        }
    } finally {
        if ($bitmap) { $bitmap.Dispose() }
    }
}

function Test-ValidGeneratedImage {
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
    } catch {
        return $false
    }
}

function Get-ApiErrorMessage {
    param($ErrorRecord)
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
        return $ErrorRecord.ErrorDetails.Message
    }
    try {
        $response = $ErrorRecord.Exception.Response
        if ($response) {
            $stream = $response.GetResponseStream()
            if ($stream) {
                $reader = [System.IO.StreamReader]::new($stream)
                try {
                    $body = $reader.ReadToEnd()
                    if (-not [string]::IsNullOrWhiteSpace($body)) { return $body }
                } finally {
                    $reader.Dispose()
                }
            }
        }
    } catch {}
    return $ErrorRecord.Exception.Message
}

function Get-CompactApiErrorMessage {
    param([string]$Message)
    if ([string]::IsNullOrWhiteSpace($Message)) { return 'unknown error' }
    $trimmed = $Message.Trim()
    try {
        $json = $trimmed | ConvertFrom-Json
        if ($json.error -and $json.error.message) { return "$($json.error.message)" }
        if ($json.detail -and $json.detail.message) { return "$($json.detail.message)" }
    } catch {}
    $oneLine = ($trimmed -replace '\s+', ' ').Trim()
    if ($oneLine.Length -gt 180) { return $oneLine.Substring(0, 180) + '...' }
    return $oneLine
}

function Get-ImageOutputExtension {
    param([object]$Settings)
    if ($Settings.Provider -eq 'gemini') { return 'jpg' }
    return 'png'
}

function Get-ExistingGeneratedImage {
    param(
        [ValidateNotNullOrEmpty()][string]$Dir,
        [int]$Index
    )
    $prefix = '{0:D3}' -f $Index
    return @(
        Get-ChildItem $Dir -File -EA SilentlyContinue |
        Where-Object {
            $_.BaseName -eq $prefix -and
            $_.Extension -match '^\.(png|jpg|jpeg)$' -and
            (Test-ValidGeneratedImage $_.FullName)
        } |
        Sort-Object Name |
        Select-Object -First 1
    )
}

function Get-ImageWorkItems {
    param(
        [object[]]$Prompts,
        [object]$Settings,
        [int]$ExpectedCount = 0
    )

    $layout = Get-CompositeLayoutParts -Settings $Settings
    if ($layout.Count -le 1) {
        return @($Prompts | ForEach-Object {
            $indices = if ($_.PSObject.Properties['Indices'] -and @($_.Indices).Count -gt 0) { @($_.Indices) } else { @([int]$_.Index) }
            [PSCustomObject]@{ Index=[int]$indices[0]; BatchIndex=[int]$indices[0]; Prompt=$_.Prompt; Indices=$indices; IsComposite=$false }
        })
    }

    $providedComposite = @($Prompts | Where-Object { $_.PSObject.Properties['Indices'] -and @($_.Indices).Count -gt 1 })
    if ($providedComposite.Count -gt 0) {
        $batch = 0
        return @($Prompts | ForEach-Object {
            $batch++
            $indices = if ($_.PSObject.Properties['Indices'] -and @($_.Indices).Count -gt 0) { @($_.Indices | ForEach-Object { [int]$_ }) } else { @([int]$_.Index) }
            if ($ExpectedCount -gt 0) { $indices = @($indices | Where-Object { $_ -le $ExpectedCount }) }
            if ($indices.Count -gt 0) {
                [PSCustomObject]@{ Index=$batch; BatchIndex=$batch; Prompt=$_.Prompt; Indices=$indices; IsComposite=($indices.Count -gt 1 -or $layout.Count -gt 1) }
            }
        })
    }

    $items = @()
    $batchIndex = 0
    $chunkSize = $layout.Count
    for ($i = 0; $i -lt $Prompts.Count; $i += $chunkSize) {
        $batchIndex++
        $chunk = @($Prompts | Select-Object -Skip $i -First $chunkSize)
        $indices = @($chunk | ForEach-Object { [int]$_.Index })
        $items += [PSCustomObject]@{
            Index       = $batchIndex
            BatchIndex  = $batchIndex
            Prompt      = New-CompositeImagePrompt -Items $chunk -Rows $layout.Rows -Cols $layout.Cols
            Indices     = $indices
            IsComposite = $true
        }
    }
    return @($items)
}

function New-CompositeImagePrompt {
    param(
        [object[]]$Items,
        [int]$Rows = 2,
        [int]$Cols = 2
    )

    $labels = if ($Rows -eq 1 -and $Cols -eq 2) {
        @('left','right')
    } elseif ($Rows -eq 2 -and $Cols -eq 1) {
        @('top','bottom')
    } else {
        @('top-left','top-right','bottom-left','bottom-right')
    }
    $parts = @()
    $panelCount = $Rows * $Cols
    for ($i = 0; $i -lt $panelCount; $i++) {
        $label = if ($i -lt $labels.Count) { $labels[$i] } else { "panel $($i + 1)" }
        if ($i -lt $Items.Count) {
            $parts += "$label panel: $($Items[$i].Prompt)"
        } else {
            $parts += "$label panel: simple empty matching background, no subject"
        }
    }
    return "Create one clean ${Rows}x${Cols} image grid with exactly $panelCount equal rectangular panels and thin clear separation lines. Each panel is a separate scene. No text, no labels, no numbers, no logos. $($parts -join '; ')."
}

function Test-FinalImagesExist {
    param(
        [ValidateNotNullOrEmpty()][string]$Dir,
        [int[]]$Indices
    )

    foreach ($idx in $Indices) {
        $existing = @(Get-ExistingGeneratedImage -Dir $Dir -Index $idx)
        if ($existing.Count -eq 0) { return $false }
    }
    return $true
}

function Test-ImageQuotaError {
    param([string]$Message)
    if ([string]::IsNullOrWhiteSpace($Message)) { return $false }
    $patterns = @(
        'quota','rate[_ -]?limit','429','too many requests','limit exceeded',
        'rate_limit_exceeded','RESOURCE_EXHAUSTED','quota exceeded',
        'insufficient_quota','not enough quota','enough quota',
        'credit','credits','balance','billing','payment required','402',
        'upgrade your account','paid plans','pollen','token limit','tokens exhausted'
    )
    foreach ($pattern in $patterns) {
        if ($Message -imatch $pattern) { return $true }
    }
    return $false
}

function Test-ImageBillingError {
    param([string]$Message)
    if ([string]::IsNullOrWhiteSpace($Message)) { return $false }
    $patterns = @(
        'billing','payment required','402','hard limit',
        'credit','credits','balance','paid plans','upgrade your account',
        'pollen','insufficient_quota','not enough quota','not enough credits'
    )
    foreach ($pattern in $patterns) {
        if ($Message -imatch $pattern) { return $true }
    }
    return $false
}

function Test-HardImageProviderError {
    param([string]$Message)
    if ([string]::IsNullOrWhiteSpace($Message)) { return $false }
    if (Test-ImageQuotaError -Message $Message) { return $true }
    return ($Message -match 'Model .* not found|model_not_found|not found|unsupported|invalid_request|invalid model|does not exist|not available|unauthorized|401|403|forbidden|permission')
}

function Test-CanFallbackToOpenAIImages {
    param([object]$Config)
    $key = Get-VafProp $Config.api_keys 'openai' ''
    return (-not [string]::IsNullOrWhiteSpace($key))
}

function New-OpenAIImageFallbackSettings {
    param([object]$CurrentSettings)
    return [PSCustomObject]@{
        Mode             = $CurrentSettings.Mode
        Provider         = 'openai'
        Model            = 'gpt-image-1.5'
        Size             = if ($CurrentSettings.PSObject.Properties['Size']) { $CurrentSettings.Size } else { '1536x1024' }
        Quality          = if ($CurrentSettings.PSObject.Properties['Quality']) { $CurrentSettings.Quality } else { 'medium' }
        AspectRatio      = if ($CurrentSettings.PSObject.Properties['AspectRatio']) { $CurrentSettings.AspectRatio } else { '16:9' }
        ImageSize        = if ($CurrentSettings.PSObject.Properties['ImageSize']) { $CurrentSettings.ImageSize } else { '1K' }
        Parallel         = if ($CurrentSettings.PSObject.Properties['Parallel']) { $CurrentSettings.Parallel } else { 1 }
        Retries          = if ($CurrentSettings.PSObject.Properties['Retries']) { $CurrentSettings.Retries } else { 2 }
        FallbackToManual = if ($CurrentSettings.PSObject.Properties['FallbackToManual']) { $CurrentSettings.FallbackToManual } else { $true }
        AutoProviderFallback = if ($CurrentSettings.PSObject.Properties['AutoProviderFallback']) { $CurrentSettings.AutoProviderFallback } else { $false }
        CompositeGrid    = if ($CurrentSettings.PSObject.Properties['CompositeGrid']) { $CurrentSettings.CompositeGrid } else { 1 }
        CompositeLayout  = if ($CurrentSettings.PSObject.Properties['CompositeLayout']) { $CurrentSettings.CompositeLayout } else { '1x1' }
    }
}

function Invoke-OpenAIImageGeneration {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$OutPath,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNull()][object]$Settings
    )

    $key = Get-VafProp $Config.api_keys 'openai' ''
    if ([string]::IsNullOrWhiteSpace($key)) { throw "OpenAI API key is missing." }

    $request = @{
        model           = $Settings.Model
        prompt          = $Prompt
        n               = 1
        size            = $Settings.Size
        quality         = $Settings.Quality
    }

    try {
        $body = $request | ConvertTo-Json -Depth 6
        $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/images/generations' -Method POST `
            -Headers @{ Authorization = "Bearer $key" } `
            -ContentType 'application/json' -Body $body -TimeoutSec 180 -EA Stop
    } catch {
        $msg = Get-ApiErrorMessage -ErrorRecord $_
        if ($msg -match "Unknown parameter: 'quality'|unsupported.*quality|quality.*not supported") {
            $request.Remove('quality')
            $body = $request | ConvertTo-Json -Depth 6
            $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/images/generations' -Method POST `
                -Headers @{ Authorization = "Bearer $key" } `
                -ContentType 'application/json' -Body $body -TimeoutSec 180 -EA Stop
        } else {
            throw
        }
    }

    $b64 = $null
    $url = $null
    if ($res.data -and @($res.data).Count -gt 0) {
        $first = @($res.data)[0]
        if ($first.PSObject.Properties['b64_json']) { $b64 = $first.b64_json }
        if ($first.PSObject.Properties['url']) { $url = $first.url }
    }
    if (-not [string]::IsNullOrWhiteSpace($b64)) {
        Save-Base64Image -Base64 $b64 -Path $OutPath
        return
    }
    if (-not [string]::IsNullOrWhiteSpace($url)) {
        Invoke-WebRequest -Uri $url -OutFile $OutPath -TimeoutSec 180 -EA Stop
        return
    }
    throw "OpenAI returned no image data."
}

function Invoke-GeminiImageGeneration {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$OutPath,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNull()][object]$Settings
    )

    $auth = Get-GeminiRestAuth -Config $Config

    $modelId = $Settings.Model -replace '^models/', ''
    $body = @{
        instances = @(
            @{ prompt = $Prompt }
        )
        parameters = @{
            sampleCount = 1
            aspectRatio = $Settings.AspectRatio
            outputMimeType = 'image/jpeg'
        }
    } | ConvertTo-Json -Depth 8

    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$([uri]::EscapeDataString($modelId)):predict"
    $res = Invoke-RestMethod -Uri $uri -Method POST `
        -Headers $auth.Headers `
        -ContentType 'application/json' -Body $body -TimeoutSec 180 -EA Stop

    $b64 = $null
    if ($res.predictions -and @($res.predictions).Count -gt 0) {
        $first = @($res.predictions)[0]
        if ($first.bytesBase64Encoded) { $b64 = $first.bytesBase64Encoded }
        elseif ($first.imageBytes) { $b64 = $first.imageBytes }
        elseif ($first.PSObject.Properties['image'] -and $first.image.PSObject.Properties['imageBytes']) { $b64 = $first.image.imageBytes }
    }
    
    if ([string]::IsNullOrWhiteSpace($b64)) { throw "Gemini API returned no image data." }
    Save-Base64Image -Base64 $b64 -Path $OutPath
}

function Invoke-PollinationsImageGeneration {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$OutPath,
        [ValidateNotNull()][object]$Config,
        [ValidateNotNull()][object]$Settings
    )

    $model = if ([string]::IsNullOrWhiteSpace($Settings.Model)) { 'flux' } else { $Settings.Model }
    $query = @{
        model           = $model
        width           = [int]$Settings.PollinationsWidth
        height          = [int]$Settings.PollinationsHeight
        seed            = [int]$Settings.PollinationsSeed
        enhance         = ([bool]$Settings.PollinationsEnhance).ToString().ToLower()
        safe            = ([bool]$Settings.PollinationsSafe).ToString().ToLower()
        negative_prompt = $Settings.PollinationsNegativePrompt
    }
    $pairs = @()
    foreach ($key in $query.Keys) {
        $value = "$($query[$key])"
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $pairs += "$([uri]::EscapeDataString($key))=$([uri]::EscapeDataString($value))"
        }
    }

    $uri = "https://gen.pollinations.ai/image/$([uri]::EscapeDataString($Prompt))?$($pairs -join '&')"
    $headers = @{}
    $key = Get-VafProp $Config.api_keys 'pollinations' ''
    if (-not [string]::IsNullOrWhiteSpace($key)) { $headers['Authorization'] = "Bearer $key" }

    Invoke-WebRequest -Uri $uri -Method GET -Headers $headers -OutFile $OutPath -TimeoutSec 240 -EA Stop | Out-Null
}

function Invoke-HuggingFaceImageGeneration {
    param(
        [ValidateNotNullOrEmpty()][string]$Prompt,
        [ValidateNotNullOrEmpty()][string]$OutPath,
        [ValidateNotNull()][object]$Config,
        [object]$Settings
    )

    $key = $Config.api_keys.huggingface
    if ([string]::IsNullOrWhiteSpace($key)) { throw "Hugging Face API key is missing." }

    $model = $Settings.Model
    if (-not $model -or $model -eq 'auto' -or $model -match '^(gpt|gemini|flux)') { $model = 'stabilityai/stable-diffusion-xl-base-1.0' }

    $uri = "https://router.huggingface.co/hf-inference/models/$model"
    $headers = @{
        'Authorization'    = "Bearer $key"
        'Content-Type'     = 'application/json'
        'Accept'           = 'image/png'
        'x-wait-for-model' = 'true'
    }
    $body = @{
        inputs = $Prompt
    } | ConvertTo-Json -Compress

    $resp = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $body -TimeoutSec 240 -EA Stop
    $contentType = [string]($resp.Headers['Content-Type'] | Select-Object -First 1)
    if ($contentType -and $contentType -notmatch '^image/') {
        $detail = try { [System.Text.Encoding]::UTF8.GetString([byte[]]$resp.Content) } catch { '' }
        throw "Hugging Face returned no image (Content-Type: $contentType). $detail".Trim()
    }
    [System.IO.File]::WriteAllBytes($OutPath, [byte[]]$resp.Content)
}

function Get-RepairedImagePrompt {
    param([string]$Prompt)
    $clean = ($Prompt -replace '\b(?:copyrighted|trademarked|celebrity|photorealistic likeness)\b', '').Trim()
    if ($clean.Length -gt 1800) { $clean = $clean.Substring(0, 1800) }
    return "$clean. Simple safe visual scene, no text, no logos."
}

function Write-ImageIndexFromFolder {
    param(
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [int]$ExpectedCount = 0
    )

    $dir = Join-Path $ProjectPath 'images'
    $images = @(
        Get-ChildItem $dir -File -EA SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(png|jpg|jpeg)$' -and (Test-ValidGeneratedImage $_.FullName) } |
        Sort-Object Name |
        ForEach-Object { "images\$($_.Name)" }
    )

    if ($ExpectedCount -gt 0) { $images = @($images | Select-Object -First $ExpectedCount) }
    if ($images.Count -eq 0) { throw "No valid PNG/JPEG images found in $dir" }

    $images | ConvertTo-Json | Set-Content (Join-Path $ProjectPath 'index.json') -Encoding UTF8
    return $images.Count
}

function Invoke-ImageGeneration {
    param(
        [ValidateNotNullOrEmpty()][string]$ProjectPath,
        [ValidateNotNull()][object]$Config,
        [int]$ExpectedCount = 0
    )

    $settings = Get-ImageSettings -Config $Config
    if ($settings.Mode -eq 'manual') {
        return [PSCustomObject]@{ Completed=$false; NeedsManual=$true; Generated=0; Failed=0; Expected=$ExpectedCount }
    }

    $logPath = Join-Path $ProjectPath 'session.log'
    $dir = Join-Path $ProjectPath 'images'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $prompts = @(Get-ImagePrompts -ProjectPath $ProjectPath)
    if ($ExpectedCount -gt 0) { $prompts = @($prompts | Select-Object -First $ExpectedCount) }
    if ($prompts.Count -eq 0) { throw "[IMAGES] No prompts available for image generation." }

    $workItems = @(Get-ImageWorkItems -Prompts $prompts -Settings $settings -ExpectedCount $ExpectedCount)
    $targetCount = if ($ExpectedCount -gt 0) { $ExpectedCount } else { @($prompts | ForEach-Object { [int]$_.Index } | Measure-Object -Maximum).Maximum }
    if (-not $targetCount -or $targetCount -lt 1) { $targetCount = $prompts.Count }

    $layout = Get-CompositeLayoutParts -Settings $settings
    Write-Log -Level INFO -Message "Image generation started: provider=$($settings.Provider), model=$($settings.Model), prompts=$($prompts.Count), workItems=$($workItems.Count), compositeLayout=$($layout.Layout)" -LogPath $logPath
    $generated = @()
    $failed = @()
    $fatalError = ''

    foreach ($item in $workItems) {
        if (-not [string]::IsNullOrWhiteSpace($fatalError)) { break }
        $indices = @($item.Indices | ForEach-Object { [int]$_ } | Where-Object { $_ -gt 0 -and ($_ -le $targetCount) })
        if ($indices.Count -eq 0) { continue }

        if (Test-FinalImagesExist -Dir $dir -Indices $indices) {
            $label = if ($item.IsComposite) { "batch {0:D3}" -f $item.BatchIndex } else { "{0:D3}" -f $indices[0] }
            Write-Host ("    ✓ {0} already exists" -f $label) -ForegroundColor DarkGray
            $generated += @($indices | ForEach-Object { '{0:D3}.png' -f $_ })
            continue
        }

        $attempt = 0
        $ok = $false
        $lastError = ''
        $fileName = ''
        while (-not $ok -and $attempt -le $settings.Retries) {
            $attempt++
            $extension = Get-ImageOutputExtension -Settings $settings
            if ($item.IsComposite) {
                $compositeDir = Join-Path $dir '_composites'
                New-Item -ItemType Directory -Force -Path $compositeDir | Out-Null
                $fileName = 'batch_{0:D3}.{1}' -f $item.BatchIndex, $extension
                $outPath = Join-Path $compositeDir $fileName
            } else {
                $fileName = '{0:D3}.{1}' -f $indices[0], $extension
                $outPath = Join-Path $dir $fileName
            }
            $prompt = if ($attempt -eq 1) { $item.Prompt } else { Get-RepairedImagePrompt -Prompt $item.Prompt }
            $label = if ($item.IsComposite) { "Batch $($item.BatchIndex)/$($workItems.Count)" } else { "Image $($indices[0])/$targetCount" }
            $spin = Start-Spinner ("{0} ({1}, attempt {2}/{3})" -f $label, $settings.Provider, $attempt, ($settings.Retries + 1))
            try {
                switch ($settings.Provider) {
                    'openai'       { Invoke-OpenAIImageGeneration -Prompt $prompt -OutPath $outPath -Config $Config -Settings $settings }
                    'gemini'       { Invoke-GeminiImageGeneration -Prompt $prompt -OutPath $outPath -Config $Config -Settings $settings }
                    'pollinations' { Invoke-PollinationsImageGeneration -Prompt $prompt -OutPath $outPath -Config $Config -Settings $settings }
                    'huggingface'  { Invoke-HuggingFaceImageGeneration -Prompt $prompt -OutPath $outPath -Config $Config -Settings $settings }
                    default  { throw "Unknown image provider '$($settings.Provider)'." }
                }
                if (-not (Test-ValidGeneratedImage -Path $outPath)) { throw "Provider returned a file that is not a valid image." }
                if ($item.IsComposite) {
                    Split-CompositeImage -CompositePath $outPath -OutDir $dir -Indices $indices -Rows $layout.Rows -Cols $layout.Cols
                    if (-not (Test-FinalImagesExist -Dir $dir -Indices $indices)) { throw "Composite split did not create every expected tile." }
                }
                Stop-Spinner $spin
                $doneText = if ($item.IsComposite) {
                    "{0} split into {1}" -f $fileName, (($indices | ForEach-Object { '{0:D3}.png' -f $_ }) -join ', ')
                } else {
                    $fileName
                }
                Write-Host ("    ✓ {0}" -f $doneText) -ForegroundColor Green
                $generated += @($indices | ForEach-Object { '{0:D3}.png' -f $_ })
                $ok = $true
            } catch {
                Stop-Spinner $spin -Failed
                $lastError = Get-ApiErrorMessage -ErrorRecord $_
                Write-Log -Level WARN -Message "Image $fileName failed on attempt $attempt`: $lastError" -LogPath $logPath
                if (Test-Path $outPath) { Remove-Item -LiteralPath $outPath -Force -EA SilentlyContinue }

                if (Test-ImageBillingError -Message $lastError) {
                    $fatalError = Get-CompactApiErrorMessage -Message $lastError
                    Write-Log -Level ERROR -Message "Fatal image provider billing error: $fatalError" -LogPath $logPath
                    $attempt = $settings.Retries + 1
                    break
                }

                if ((Test-HardImageProviderError -Message $lastError) -and $settings.Provider -ne 'openai' -and $settings.AutoProviderFallback -and (Test-CanFallbackToOpenAIImages -Config $Config)) {
                    Write-Host '    Switching image generation to OpenAI fallback...' -ForegroundColor Yellow
                    Write-Log -Level WARN -Message "Switching image generation fallback to OpenAI after provider error: $(Get-CompactApiErrorMessage -Message $lastError)" -LogPath $logPath
                    $settings = New-OpenAIImageFallbackSettings -CurrentSettings $settings
                    $attempt = 0
                    continue
                }

                if (Test-ImageQuotaError -Message $lastError) {
                    $fatalError = Get-CompactApiErrorMessage -Message $lastError
                    Write-Log -Level ERROR -Message "Fatal image provider quota/rate error: $fatalError" -LogPath $logPath
                    $attempt = $settings.Retries + 1
                    break
                }

                if (Test-HardImageProviderError -Message $lastError) {
                    $fatalError = Get-CompactApiErrorMessage -Message $lastError
                    Write-Log -Level ERROR -Message "Fatal image provider error: $fatalError" -LogPath $logPath
                    $attempt = $settings.Retries + 1
                    break
                }
            }
        }

        if (-not $ok) {
            Write-Host ("    ✗ {0} failed" -f $fileName) -ForegroundColor Yellow
            Write-Host ("      {0}" -f (Get-CompactApiErrorMessage -Message $lastError)) -ForegroundColor DarkYellow
            $failed += [PSCustomObject]@{ Index=$item.Index; Indices=$indices; File=$fileName; Prompt=$item.Prompt; Error=$lastError }
        }

        if (-not [string]::IsNullOrWhiteSpace($fatalError)) { break }
    }

    if ($failed.Count -gt 0) {
        $failed | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $ProjectPath 'failed_images.json') -Encoding UTF8
    } elseif (Test-Path (Join-Path $ProjectPath 'failed_images.json')) {
        Remove-Item (Join-Path $ProjectPath 'failed_images.json') -Force -EA SilentlyContinue
    }

    $indexCount = 0
    if ($generated.Count -gt 0) {
        $indexCount = Write-ImageIndexFromFolder -ProjectPath $ProjectPath -ExpectedCount $targetCount
    }

    $accepted = $true
    if ($settings.Mode -eq 'auto_review' -and $failed.Count -eq 0) {
        Start-Process explorer.exe $dir
        $choice = (Read-Host '    Review generated images. [A]ccept / [M]anual fix').Trim().ToUpper()
        if ($choice -eq 'M') { $accepted = $false }
    }

    return [PSCustomObject]@{
        Completed   = ($failed.Count -eq 0 -and $accepted)
        NeedsManual = ($failed.Count -gt 0 -or -not $accepted)
        Generated   = $generated.Count
        Failed      = $failed.Count
        Expected    = $prompts.Count
        Indexed     = $indexCount
        FatalError  = $fatalError
    }
}
