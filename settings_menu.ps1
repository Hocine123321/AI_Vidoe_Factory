# =============================================================================
# settings_menu.ps1
# Sections: HELPERS | DISPLAY | HANDLERS | ENTRY
# =============================================================================

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# HELPERS  Ã¢â‚¬â€ StrictMode-safe property access for PSCustomObjects from JSON
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

function Set-Prop {
    param([ValidateNotNull()][object]$Obj, [ValidateNotNullOrEmpty()][string]$Name, $Value)
    $Obj | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
}

function Get-Prop {
    param([object]$Obj, [string]$Name, $Default = '')
    if ($null -eq $Obj)                          { return $Default }
    if (-not $Obj.PSObject.Properties[$Name])    { return $Default }
    $v = $Obj.$Name
    if ($null -eq $v)                            { return $Default }
    return $v
}

function Normalize-AIBackend {
    param([string]$Backend)
    if ([string]::IsNullOrWhiteSpace($Backend)) { return 'openai' }
    switch ($Backend.ToLower()) {
        'codex' { return 'openai' }
        'gpt3'  { return 'openai' }
        default { return $Backend.ToLower() }
    }
}

function Mask-Key {
    param([string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) { return '[NOT SET]' }
    if ($Key.Length -le 8)                  { return '****' }
    return $Key.Substring(0,4) + '****' + $Key.Substring($Key.Length - 4)
}

function New-MenuItem {
    param(
        [string]$Key,
        [string]$Label,
        $Value = '',
        [string]$Hint = ''
    )
    return [PSCustomObject]@{ Key=$Key; Label=$Label; Value=$Value; Hint=$Hint }
}

function New-MenuHeader {
    param([string]$Label)
    return [PSCustomObject]@{ Key='__header'; Label=$Label; Value=''; Hint='' }
}

function Format-MenuText {
    param($Text, [int]$Max = 44)
    $s = if ($null -eq $Text) { '' } else { "$Text" }
    $s = ($s -replace '\s+', ' ').Trim()
    if ($s.Length -le $Max) { return $s }
    return $s.Substring(0, [Math]::Max(0, $Max - 3)) + '...'
}

function Get-CompositeLayoutLabel {
    param($Value)
    $layout = if ([string]::IsNullOrWhiteSpace("$Value")) { '1x1' } else { "$Value" }
    switch ($layout) {
        '1x1' { return 'Level 0 normal, 1 scene per image' }
        '1x2' { return 'Level 1 saver, 1x2, 2 scenes per image' }
        '2x1' { return 'Level 1 saver, 2x1, 2 scenes per image' }
        '2x2' { return 'Level 2 heavy saver, 2x2, 4 scenes per image' }
        default { return $layout }
    }
}

function Get-CompositePanelCount {
    param($Value)
    $layout = if ([string]::IsNullOrWhiteSpace("$Value")) { '1x1' } else { "$Value" }
    if ($layout -notmatch '^(\d+)x(\d+)$') { return 1 }
    return ([Math]::Max(1, [int]$Matches[1]) * [Math]::Max(1, [int]$Matches[2]))
}

function Get-ImageTokenText {
    param([object]$Config)
    $provider = Get-Prop $Config.images 'provider' 'openai'
    $model = Get-Prop $Config.images 'model' ''
    $layout = Get-Prop $Config.images 'composite_layout' '1x1'
    $panels = Get-CompositePanelCount $layout

    if ($provider -eq 'gemini') {
        $size = Get-Prop $Config.images 'image_size' '1K'
        $tokens = switch -Regex ($size) {
            '^(512px|0\.5K)$' { 747; break }
            '^1K$' { if ($model -match '2\.5') { 1290 } else { 1120 }; break }
            '^2K$' { 1680; break }
            '^4K$' { if ($model -match 'pro') { 2000 } else { 2520 }; break }
            default { 1120 }
        }
        $perScene = [Math]::Ceiling($tokens / [Math]::Max(1, $panels))
        if ($panels -gt 1) {
            return "Tokens: ~$tokens per generated image (~$perScene per scene)"
        }
        return "Tokens: ~$tokens per image"
    }

    if ($provider -eq 'pollinations') {
        return 'Tokens: n/a, Pollinations uses provider credits'
    }

    if ($provider -eq 'huggingface') {
        return 'Tokens: n/a — Hugging Face Inference API (per model)'
    }

    return 'Tokens: reported by OpenAI after generation'
}

function Get-MenuPanelLayout {
    param([switch]$WideModelList)

    $inner = 71
    try {
        $consoleW = $Host.UI.RawUI.WindowSize.Width
        if ($consoleW -gt 84) { $inner = [Math]::Min(116, $consoleW - 8) }
    } catch {}

    if ($WideModelList) {
        $hintW = 24
        $labelW = 14
        $numW = 5
        $valueW = [Math]::Max(40, $inner - $numW - $labelW - $hintW - 2)
        return [PSCustomObject]@{ Inner = $inner; NumW = $numW; LabelW = $labelW; ValueW = $valueW; HintW = $hintW }
    }

    $hintW = 18
    $labelW = 16
    $numW = 5
    $valueW = [Math]::Max(28, $inner - $numW - $labelW - $hintW - 2)
    return [PSCustomObject]@{ Inner = $inner; NumW = $numW; LabelW = $labelW; ValueW = $valueW; HintW = $hintW }
}

function Fit-MenuField {
    param([string]$Text, [int]$Width)
    $s = if ($null -eq $Text) { '' } else { ("$Text" -replace '\s+', ' ').Trim() }
    if ($Width -le 0) { return '' }
    if ($s.Length -le $Width) { return $s }
    if ($Width -le 3) { return $s.Substring(0, $Width) }
    return $s.Substring(0, $Width - 3) + '...'
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
        'dark' { return [PSCustomObject]@{ Accent='Cyan'; Text='White'; Note='Gray'; Muted='DarkGray'; Success='Green'; Warning='Yellow' } }
        'light' { return [PSCustomObject]@{ Accent='Blue'; Text='Black'; Note='DarkGray'; Muted='DarkGray'; Success='DarkGreen'; Warning='DarkYellow' } }
        'high_contrast' { return [PSCustomObject]@{ Accent='Yellow'; Text='White'; Note='Cyan'; Muted='Gray'; Success='Green'; Warning='Yellow' } }
        default { return [PSCustomObject]@{ Accent='Cyan'; Text='Gray'; Note='DarkGray'; Muted='DarkGray'; Success='Green'; Warning='DarkYellow' } }
    }
}

function Get-MenuControlsText {
    param(
        [int]$PageCount,
        [switch]$AllowSave,
        [switch]$AllowQuit,
        [switch]$AllowManual
    )
    $actions = @('[B] Back')
    if ($PageCount -gt 1) { $actions = @('[A] Prev page', '[D] Next page') + $actions }
    if ($AllowSave) { $actions += '[S] Save' }
    if ($AllowManual) { $actions += '[M] Manual' }
    if ($AllowQuit) { $actions += '[Q] Quit' }
    return ($actions -join '   ')
}

function Write-MenuControls {
    param([string]$Text, [object]$Config = $null, [int]$Page = 0, [int]$PageCount = 1)
    $uiTheme = Get-UiTheme -Config $Config
    Write-Host ("  Controls: {0}" -f $Text) -ForegroundColor $uiTheme.Note -NoNewline
    if ($PageCount -gt 1) { Write-Host ("    (Page {0}/{1})" -f ($Page + 1), $PageCount) -ForegroundColor $uiTheme.Muted } else { Write-Host "" }
}

function Write-SettingsMenuPanel {
    param(
        [string]$Title,
        [string]$Subtitle,
        [object[]]$Rows,
        [object]$UiTheme,
        [object]$Layout = $null
    )
    if (-not $Layout) { $Layout = Get-MenuPanelLayout }
    $border = '-' * $Layout.Inner
    $titleFmt = "  | {0,-$($Layout.Inner)} |"
    Write-Host "  +$border+" -ForegroundColor $UiTheme.Note
    Write-Host ($titleFmt -f $Title.ToUpper()) -ForegroundColor $UiTheme.Accent
    if ($Subtitle) {
        Write-Host ($titleFmt -f (Fit-MenuField $Subtitle $Layout.Inner)) -ForegroundColor $UiTheme.Muted
    }
    Write-Host "  +$border+" -ForegroundColor $UiTheme.Note
    foreach ($row in $Rows) {
        if ($row.IsHeader) {
            Write-Host ($titleFmt -f (Fit-MenuField $row.Label.ToUpper() $Layout.Inner)) -ForegroundColor $UiTheme.Accent
            continue
        }
        $label = Fit-MenuField $row.Label $Layout.LabelW
        $value = Fit-MenuField $row.Value $Layout.ValueW
        $hint  = Fit-MenuField $row.Hint $Layout.HintW
        Write-Host '  |' -NoNewline -ForegroundColor $UiTheme.Note
        Write-Host ("{0,$($Layout.NumW)} " -f $row.Number) -ForegroundColor $UiTheme.Accent -NoNewline
        Write-Host ("{0,-$($Layout.LabelW)}" -f $label) -ForegroundColor $UiTheme.Text -NoNewline
        Write-Host ' ' -NoNewline
        Write-Host ("{0,-$($Layout.ValueW)}" -f $value) -ForegroundColor $UiTheme.Note -NoNewline
        Write-Host (" {0,-$($Layout.HintW)}" -f $hint) -ForegroundColor $UiTheme.Muted -NoNewline
        Write-Host ' |' -ForegroundColor $UiTheme.Note
    }
    Write-Host "  +$border+" -ForegroundColor $UiTheme.Note
}

function Invoke-NumberedMenu {
    param(
        [string]$Title,
        [object[]]$Items,
        [string]$Subtitle = '',
        [int]$PageSize = 12,
        [switch]$AllowSave,
        [switch]$AllowQuit,
        [switch]$AllowManual,
        [object]$Config = $null
    )
    if (-not $Items -or $Items.Count -eq 0) { return $null }

    $page = 0
    $pageCount = [Math]::Max(1, [Math]::Ceiling($Items.Count / $PageSize))
    $controls = Get-MenuControlsText -PageCount $pageCount -AllowSave:$AllowSave -AllowQuit:$AllowQuit -AllowManual:$AllowManual
    $panelLayout = Get-MenuPanelLayout -WideModelList:($Title -match 'MODELS')
    while ($true) {
        $uiTheme = Get-UiTheme -Config $Config
        Show-SettingsBanner

        $start = $page * $PageSize
        $end = [Math]::Min($Items.Count - 1, $start + $PageSize - 1)
        $selectable = @()
        $rows = [System.Collections.Generic.List[object]]::new()
        $local = 1

        for ($i = $start; $i -le $end; $i++) {
            $item = $Items[$i]
            if ($item.Key -eq '__header') {
                $rows.Add([PSCustomObject]@{ IsHeader = $true; Label = $item.Label })
                continue
            }
            $rows.Add([PSCustomObject]@{
                IsHeader = $false
                Number   = "[$local]"
                Label    = $item.Label
                Value    = $item.Value
                Hint     = $item.Hint
            })
            $selectable += $item
            $local++
        }

        Write-SettingsMenuPanel -Title $Title -Subtitle $Subtitle -Rows @($rows) -UiTheme $uiTheme -Layout $panelLayout
        Write-MenuControls -Text $controls -Config $Config -Page $page -PageCount $pageCount
        $pick = (Read-Host '  Select').Trim().ToUpper()
        if ($pick -eq 'B' -or $pick -eq '') { return $null }
        if ($AllowSave -and $pick -eq 'S') { return (New-MenuItem -Key '__save' -Label 'Save') }
        if ($AllowManual -and $pick -eq 'M') { return (New-MenuItem -Key '__manual' -Label 'Manual') }
        if ($AllowQuit -and $pick -eq 'Q') { return (New-MenuItem -Key '__quit' -Label 'Quit') }
        if ($pick -eq 'A') {
            if ($page -gt 0) { $page-- }
            continue
        }
        if ($pick -eq 'D') {
            if ($page -lt $pageCount - 1) { $page++ }
            continue
        }
        if ($pick -match '^\d+$') {
            $idx = [int]$pick - 1
            if ($idx -ge 0 -and $idx -lt $selectable.Count) { return $selectable[$idx] }
        }
        Write-Host '  Invalid option.' -ForegroundColor Red
        Start-Sleep 1
    }
}

function Select-Choice {
    param(
        [string]$Title,
        [object[]]$Choices,
        $CurrentValue = $null,
        [object]$Config = $null
    )
    $items = @(
        $Choices | ForEach-Object {
            $mark = if ($_.Value -eq $CurrentValue) { 'current' } else { '' }
            New-MenuItem -Key $_.Value -Label $_.Label -Hint $mark
        }
    )
    $selected = Invoke-NumberedMenu -Title $Title -Items $items -Config $Config
    if (-not $selected) { return $CurrentValue }
    return $selected.Key
}

function Get-FallbackModelCatalog {
    return [ordered]@{
        openai  = @(
            [PSCustomObject]@{ Id='o4-mini'; Label='o4-mini'; Note='default script writer' },
            [PSCustomObject]@{ Id='o3'; Label='o3'; Note='deeper reasoning' }
        )
        gemini = @(
            [PSCustomObject]@{ Id='gemini-2.5-flash'; Label='gemini-2.5-flash'; Note='fast, stable default' },
            [PSCustomObject]@{ Id='gemini-2.5-pro'; Label='gemini-2.5-pro'; Note='stronger reasoning' },
            [PSCustomObject]@{ Id='gemini-2.5-flash-lite'; Label='gemini-2.5-flash-lite'; Note='lighter/faster' },
            [PSCustomObject]@{ Id='gemini-3-flash-preview'; Label='gemini-3-flash-preview'; Note='preview, may vary by account' },
            [PSCustomObject]@{ Id='gemini-3-pro-preview'; Label='gemini-3-pro-preview'; Note='preview, may vary by account' }
        )
        huggingface = @(
            [PSCustomObject]@{ Id='meta-llama/Meta-Llama-3-8B-Instruct'; Label='Llama-3-8B'; Note='fast, efficient' },
            [PSCustomObject]@{ Id='mistralai/Mistral-7B-Instruct-v0.3'; Label='Mistral-7B'; Note='balanced performance' },
            [PSCustomObject]@{ Id='meta-llama/Meta-Llama-3.1-70B-Instruct'; Label='Llama-3.1-70B'; Note='complex reasoning' },
            [PSCustomObject]@{ Id='Qwen/Qwen2.5-72B-Instruct'; Label='Qwen-2.5-72B'; Note='strong multi-lingual' }
        )
    }
}

function Get-LiveGeminiModels {
    param([object]$Config)

    try {
        $key = Get-Prop $Config.api_keys 'gemini' ''
        if ([string]::IsNullOrWhiteSpace($key)) { return @() }
        $uri = "https://generativelanguage.googleapis.com/v1beta/models?key=$([uri]::EscapeDataString($key))"
        $res = Invoke-RestMethod -Uri $uri -Method GET -TimeoutSec 20 -EA Stop
        return @(
            $res.models |
            Where-Object {
                $_.name -and
                $_.supportedGenerationMethods -and
                @($_.supportedGenerationMethods) -contains 'generateContent'
            } |
            ForEach-Object {
                $id = $_.name -replace '^models/', ''
                [PSCustomObject]@{ Id=$id; Label=$id; Note='live from Gemini API' }
            } |
            Where-Object { $_.Id -notmatch 'image|imagen|embedding|audio|tts|veo|vision' } |
            Sort-Object Id -Unique
        )
    } catch {
        return @()
    }
}

function Get-LiveOpenAIModels {
    param([object]$Config)
    $key = Get-Prop $Config.api_keys 'openai' ''
    if ([string]::IsNullOrWhiteSpace($key)) { return @() }

    try {
        $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/models' -Method GET `
            -Headers @{ Authorization = "Bearer $key" } -TimeoutSec 20 -EA Stop
        $blocked = 'audio|tts|transcribe|whisper|embedding|moderation|image|dall|sora|realtime'
        return @(
            $res.data |
            Where-Object {
                $_.id -and
                $_.id -notmatch $blocked -and
                $_.id -match '^(gpt-|o\d|o\d-|openai)'
            } |
            Sort-Object created -Descending |
            ForEach-Object {
                [PSCustomObject]@{ Id=$_.id; Label=$_.id; Note='live from OpenAI API' }
            }
        )
    } catch {
        return @()
    }
}

function Get-LiveHuggingFaceModels {
    param([object]$Config)
    try {
        $amp = [char]38
        $uri = "https://huggingface.co/api/models?pipeline_tag=text-generation${amp}sort=downloads${amp}direction=-1${amp}limit=20"
        $res = Invoke-RestMethod -Uri $uri -Method GET -TimeoutSec 20 -EA Stop
        return @(
            $res | ForEach-Object {
                $dl = Get-Prop $_ 'downloads' 0
                $dlStr = Format-LargeCount $dl
                [PSCustomObject]@{
                    Id    = $_.modelId
                    Label = $_.modelId
                    Note  = ('HF | {0} downloads' -f $dlStr)
                }
            }
        )
    } catch {
        return @()
    }
}

function Get-ModelOptions {
    param(
        [ValidateSet('openai','gemini','huggingface')][string]$Backend,
        [object]$Config
    )

    $Backend = Normalize-AIBackend $Backend
    $live = switch ($Backend) {
        'gemini'      { Get-LiveGeminiModels -Config $Config }
        'huggingface' { Get-LiveHuggingFaceModels -Config $Config }
        default       { Get-LiveOpenAIModels -Config $Config }
    }

    if (@($live).Count -gt 0) {
        return [PSCustomObject]@{ Source='live'; Models=@($live) }
    }

    return [PSCustomObject]@{ Source='fallback'; Models=@((Get-FallbackModelCatalog)[$Backend]) }
}

function Select-FirstModelMatch {
    param(
        [object[]]$Models,
        [string[]]$Patterns,
        [string[]]$ExcludeIds = @()
    )

    foreach ($pattern in $Patterns) {
        $found = @(
            $Models | Where-Object {
                $_.Id -and
                @($ExcludeIds) -notcontains $_.Id -and
                (("$($_.Id) $($_.Label) $($_.Note)") -match $pattern)
            } | Select-Object -First 1
        )
        if (@($found).Count -gt 0) { return $found[0] }
    }

    return $null
}

function Get-SuggestedAIModels {
    param(
        [ValidateSet('openai','gemini','huggingface')][string]$Backend,
        [object[]]$Models
    )

    $suggestions = @()
    $used = @()

    if ($Backend -eq 'gemini') {
        $defs = @(
            [PSCustomObject]@{ Slot='Fast';    Patterns=@('gemini-3(\.\d+)?-flash(?!-lite)', 'gemini-2\.5-flash(?!-lite)', 'flash(?!-lite)') },
            [PSCustomObject]@{ Slot='Lite';    Patterns=@('flash-lite', 'lite') },
            [PSCustomObject]@{ Slot='Complex'; Patterns=@('gemini-3(\.\d+)?-pro', 'gemini-2\.5-pro', 'pro') }
        )
    } elseif ($Backend -eq 'huggingface') {
        $defs = @(
            [PSCustomObject]@{ Slot='Fast';    Patterns=@('llama.*-8b', 'mistral.*-7b', '8b', '7b') },
            [PSCustomObject]@{ Slot='Balanced'; Patterns=@('mistral.*-7b', 'gemma.*-7b', '7b') },
            [PSCustomObject]@{ Slot='Complex'; Patterns=@('llama.*-70b', 'qwen.*-72b', '70b', '72b') }
        )
    } else {
        $defs = @(
            [PSCustomObject]@{ Slot='Fast';    Patterns=@('gpt-5.*mini', 'gpt-4.*mini', 'o\d.*mini', 'mini') },
            [PSCustomObject]@{ Slot='Lite';    Patterns=@('nano', 'lite', 'mini') },
            [PSCustomObject]@{ Slot='Complex'; Patterns=@('pro', '^gpt-5($|-|\.)(?!.*(mini|nano|lite))', '^gpt-4\.1($|-)(?!.*(mini|nano|lite))', '^o\d($|-)') }
        )
    }

    foreach ($def in $defs) {
        $model = Select-FirstModelMatch -Models $Models -Patterns $def.Patterns -ExcludeIds $used
        if ($null -ne $model) {
            $used += $model.Id
            $suggestions += [PSCustomObject]@{
                Slot  = $def.Slot
                Id    = $model.Id
                Label = $model.Label
                Note  = $model.Note
            }
        }
    }

    return @($suggestions)
}

function New-ModelPickerItems {
    param(
        [ValidateSet('openai','gemini','huggingface')][string]$Backend,
        [object[]]$Models,
        [string]$CurrentModel = ''
    )

    $suggested = @(Get-SuggestedAIModels -Backend $Backend -Models $Models)
    $suggestedIds = @($suggested | ForEach-Object { $_.Id })
    $items = @()

    if ($suggested.Count -gt 0) { $items += New-MenuHeader -Label 'Suggested' }
    foreach ($item in $suggested) {
        $hint = if ($item.Id -eq $CurrentModel) { 'current' } else { $item.Note }
        $items += New-MenuItem -Key $item.Id -Label "Suggested $($item.Slot)" -Value $item.Label -Hint $hint
    }

    if ($Models.Count -gt $suggested.Count) { $items += New-MenuHeader -Label 'All Models' }
    foreach ($model in @($Models | Where-Object { @($suggestedIds) -notcontains $_.Id })) {
        $hint = if ($model.Id -eq $CurrentModel) { 'current' } else { $model.Note }
        $items += New-MenuItem -Key $model.Id -Label $model.Label -Hint $hint
    }

    return @($items)
}

function Get-LiveElevenLabsVoices {
    param([object]$Config)
    $key = Get-Prop $Config.api_keys 'elevenlabs' ''
    if ([string]::IsNullOrWhiteSpace($key)) { return @() }

    try {
        $res = Invoke-RestMethod -Uri 'https://api.elevenlabs.io/v1/voices' `
            -Headers @{ 'xi-api-key' = $key } -TimeoutSec 20 -EA Stop
        return @(
            $res.voices |
            ForEach-Object {
                $category = if ($_.category) { $_.category } else { 'voice' }
                $owned = if ($_.PSObject.Properties['is_owner'] -and $_.is_owner) { 'owned' } else { 'library/shared' }
                $labels = @()
                if ($_.labels) {
                    foreach ($name in @('gender','age','accent','use_case','descriptive','language')) {
                        if ($_.labels.PSObject.Properties[$name] -and $_.labels.$name) { $labels += $_.labels.$name }
                    }
                }
                $planHint = if ($category -eq 'professional' -and $owned -ne 'owned') { 'may require paid API plan' } else { $owned }
                $note = (@($category, $planHint) + $labels | Where-Object { $_ }) -join ' | '
                [PSCustomObject]@{
                    Id    = $_.voice_id
                    Label = $_.name
                    Note  = $note
                    UseCase = if ($_.labels -and $_.labels.PSObject.Properties['use_case']) { $_.labels.use_case } else { '' }
                }
            } |
            Sort-Object Label -Unique
        )
    } catch {
        return @()
    }
}

function Get-VoiceSocialScore {
    param([object]$Voice)

    $text = "$($Voice.Label) $($Voice.Note) $($Voice.UseCase)"
    $score = 0
    if ($text -match 'social[_ -]?media') { $score += 10 }
    if ($text -match 'premade|owned') { $score += 3 }
    if ($text -match 'warm|confident|engaging|narrat|creator|social|energetic|conversational') { $score += 2 }
    if ($text -match 'professional|paid API plan') { $score -= 8 }
    return $score
}

function Format-LargeCount {
    param($Value)
    if ($null -eq $Value -or "$Value" -eq '') { return '' }
    $n = [double]$Value
    if ($n -ge 1000000000) { return ('{0:N1}B' -f ($n / 1000000000)) }
    if ($n -ge 1000000) { return ('{0:N1}M' -f ($n / 1000000)) }
    if ($n -ge 1000) { return ('{0:N1}K' -f ($n / 1000)) }
    return "$Value"
}

function Get-LiveElevenLabsSharedSocialVoices {
    param([object]$Config)
    $key = Get-Prop $Config.api_keys 'elevenlabs' ''
    if ([string]::IsNullOrWhiteSpace($key)) { return @() }

    try {
        $uri = 'https://api.elevenlabs.io/v1/shared-voices?page_size=50&use_cases=social_media&sort=usage_character_count_1y'
        $res = Invoke-RestMethod -Uri $uri -Headers @{ 'xi-api-key' = $key } -TimeoutSec 20 -EA Stop
        return @(
            $res.voices |
            Where-Object { $_.voice_id } |
            Sort-Object @{Expression={ if ($_.usage_character_count_1y) { [double]$_.usage_character_count_1y } else { 0 } }; Descending=$true} |
            Select-Object -First 3 |
            ForEach-Object {
                $used = Format-LargeCount -Value $_.usage_character_count_1y
                $noteBits = @('shared library', 'social_media')
                if ($used) { $noteBits += "used $used chars/year" }
                $noteBits += 'may require paid API plan'
                [PSCustomObject]@{
                    Id = $_.voice_id
                    Label = $_.name
                    Note = ($noteBits -join ' | ')
                    UseCase = 'social_media'
                }
            }
        )
    } catch {
        return @()
    }
}

function Get-SuggestedSocialVoices {
    param([object[]]$Voices)

    return @(
        $Voices |
        Where-Object { $_.UseCase -match 'social[_ -]?media' -or $_.Note -match 'social[_ -]?media' } |
        ForEach-Object {
            [PSCustomObject]@{
                Id = $_.Id
                Label = $_.Label
                Note = $_.Note
                UseCase = $_.UseCase
                Score = Get-VoiceSocialScore -Voice $_
            }
        } |
        Sort-Object @{Expression='Score'; Descending=$true}, Label |
        Select-Object -First 3
    )
}

function New-VoicePickerItems {
    param(
        [object[]]$Voices,
        [string]$CurrentVoiceId = '',
        [object[]]$SuggestedVoices = @()
    )

    $suggested = @($SuggestedVoices)
    if ($suggested.Count -eq 0) { $suggested = @(Get-SuggestedSocialVoices -Voices $Voices) }
    $suggestedIds = @($suggested | ForEach-Object { $_.Id })
    $items = @()
    $rank = 1

    if ($suggested.Count -gt 0) { $items += New-MenuHeader -Label 'Top Social Media Voices' }
    foreach ($voice in $suggested) {
        $hint = if ($voice.Id -eq $CurrentVoiceId) { 'current' } else { $voice.Note }
        $items += New-MenuItem -Key $voice.Id -Label "Suggested Social $rank" -Value $voice.Label -Hint $hint
        $rank++
    }

    if ($Voices.Count -gt $suggested.Count) { $items += New-MenuHeader -Label 'All Voices' }
    foreach ($voice in @($Voices | Where-Object { @($suggestedIds) -notcontains $_.Id })) {
        $hint = if ($voice.Id -eq $CurrentVoiceId) { 'current' } else { $voice.Note }
        $items += New-MenuItem -Key $voice.Id -Label $voice.Label -Hint $hint
    }

    return @($items)
}

function Get-FallbackTtsModelCatalog {
    return @(
        [PSCustomObject]@{ Id='eleven_v3'; Label='eleven_v3'; Note='complex, expressive TTS' },
        [PSCustomObject]@{ Id='eleven_multilingual_v2'; Label='eleven_multilingual_v2'; Note='complex, stable long-form TTS' },
        [PSCustomObject]@{ Id='eleven_flash_v2_5'; Label='eleven_flash_v2_5'; Note='fast, low-latency TTS' },
        [PSCustomObject]@{ Id='eleven_turbo_v2_5'; Label='eleven_turbo_v2_5'; Note='balanced speed and quality' },
        [PSCustomObject]@{ Id='eleven_flash_v2'; Label='eleven_flash_v2'; Note='lite/fast English TTS' },
        [PSCustomObject]@{ Id='eleven_turbo_v2'; Label='eleven_turbo_v2'; Note='older balanced TTS' },
        [PSCustomObject]@{ Id='eleven_monolingual_v1'; Label='eleven_monolingual_v1'; Note='legacy English TTS' }
    )
}

function Get-LiveElevenLabsTtsModels {
    param([object]$Config)
    $key = Get-Prop $Config.api_keys 'elevenlabs' ''

    try {
        $headers = @{ 'Content-Type' = 'application/json' }
        if (-not [string]::IsNullOrWhiteSpace($key)) { $headers['xi-api-key'] = $key }
        $res = Invoke-RestMethod -Uri 'https://api.elevenlabs.io/v1/models' `
            -Headers $headers -TimeoutSec 20 -EA Stop
        return @(
            $res |
            Where-Object { $_.model_id -and $_.can_do_text_to_speech } |
            ForEach-Object {
                $languages = if ($_.languages) { "$(@($_.languages).Count) languages" } else { '' }
                $cost = if ($_.model_rates -and $_.model_rates.PSObject.Properties['character_cost_multiplier']) { "cost x$($_.model_rates.character_cost_multiplier)" } elseif ($_.PSObject.Properties['token_cost_factor']) { "cost x$($_.token_cost_factor)" } else { '' }
                $note = @($_.description, $languages, $cost) | Where-Object { $_ } | Select-Object -First 3
                [PSCustomObject]@{
                    Id = $_.model_id
                    Label = if ($_.name) { $_.name } else { $_.model_id }
                    Note = ($note -join ' | ')
                }
            } |
            Sort-Object Id -Unique
        )
    } catch {
        return @()
    }
}

function Get-TtsModelOptions {
    param([object]$Config)

    $live = @(Get-LiveElevenLabsTtsModels -Config $Config)
    if (@($live).Count -gt 0) {
        return [PSCustomObject]@{ Source='live'; Models=$live }
    }
    return [PSCustomObject]@{ Source='fallback'; Models=@(Get-FallbackTtsModelCatalog) }
}

function Get-FallbackImageModelCatalog {
    param([ValidateSet('openai','gemini','huggingface','pollinations')][string]$Provider)
    if ($Provider -eq 'pollinations') {
        return @(
            [PSCustomObject]@{ Id='flux'; Label='flux'; Note='Pollinations default' },
            [PSCustomObject]@{ Id='turbo'; Label='turbo'; Note='faster Pollinations model' },
            [PSCustomObject]@{ Id='gptimage'; Label='gptimage'; Note='Pollinations GPT image model' },
            [PSCustomObject]@{ Id='kontext'; Label='kontext'; Note='Pollinations image model' },
            [PSCustomObject]@{ Id='seedream'; Label='seedream'; Note='Pollinations image model' },
            [PSCustomObject]@{ Id='nanobanana'; Label='nanobanana'; Note='Pollinations image model' },
            [PSCustomObject]@{ Id='nanobanana-pro'; Label='nanobanana-pro'; Note='Pollinations pro image model' }
        )
    }
    if ($Provider -eq 'gemini') {
        return @(
            [PSCustomObject]@{ Id='gemini-3.1-flash-image-preview'; Label='gemini-3.1-flash-image-preview'; Note='Gemini image generation' },
            [PSCustomObject]@{ Id='gemini-3-flash-image-preview'; Label='gemini-3-flash-image-preview'; Note='Gemini image preview' },
            [PSCustomObject]@{ Id='imagen-4.0-fast-generate-001'; Label='imagen-4.0-fast-generate-001'; Note='Imagen, saves as JPEG' },
            [PSCustomObject]@{ Id='imagen-4.0-generate-001'; Label='imagen-4.0-generate-001'; Note='Imagen, saves as JPEG' }
        )
    }
    if ($Provider -eq 'huggingface') {
        return @(
            [PSCustomObject]@{ Id='stabilityai/stable-diffusion-xl-base-1.0'; Label='SDXL Base 1.0'; Note='reliable balanced choice' },
            [PSCustomObject]@{ Id='black-forest-labs/FLUX.1-schnell'; Label='FLUX.1-schnell'; Note='fast high quality' },
            [PSCustomObject]@{ Id='black-forest-labs/FLUX.1-dev'; Label='FLUX.1-dev'; Note='very high quality' },
            [PSCustomObject]@{ Id='runwayml/stable-diffusion-v1-5'; Label='SD v1.5'; Note='legacy fast choice' }
        )
    }
    return @(
        [PSCustomObject]@{ Id='gpt-image-1.5'; Label='gpt-image-1.5'; Note='best current image generator' },
        [PSCustomObject]@{ Id='gpt-image-1'; Label='gpt-image-1'; Note='stable image generator' },
        [PSCustomObject]@{ Id='gpt-image-1-mini'; Label='gpt-image-1-mini'; Note='lighter/faster image generator' },
        [PSCustomObject]@{ Id='dall-e-3'; Label='dall-e-3'; Note='legacy image generator' }
    )
}

function Get-LiveOpenAIImageModels {
    param([object]$Config)
    $key = Get-Prop $Config.api_keys 'openai' ''
    if ([string]::IsNullOrWhiteSpace($key)) { return @() }

    try {
        $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/models' -Method GET `
            -Headers @{ Authorization = "Bearer $key" } -TimeoutSec 20 -EA Stop
        return @(
            $res.data |
            Where-Object { $_.id -match '^(gpt-image|dall-e)' } |
            Sort-Object created -Descending |
            ForEach-Object { [PSCustomObject]@{ Id=$_.id; Label=$_.id; Note='live from OpenAI API' } }
        )
    } catch {
        return @()
    }
}

function Get-LiveGeminiImageModels {
    param([object]$Config)

    try {
        $key = Get-Prop $Config.api_keys 'gemini' ''
        if ([string]::IsNullOrWhiteSpace($key)) { return @() }
        $uri = "https://generativelanguage.googleapis.com/v1beta/models?key=$([uri]::EscapeDataString($key))"
        $res = Invoke-RestMethod -Uri $uri -Method GET -TimeoutSec 20 -EA Stop
        return @(
            $res.models |
            Where-Object { $_.name -and $_.name -match 'image|imagen' } |
            ForEach-Object {
                $id = $_.name -replace '^models/', ''
                [PSCustomObject]@{ Id=$id; Label=$id; Note='live from Gemini API' }
            } |
            Sort-Object Id -Unique
        )
    } catch {
        return @()
    }
}

function Get-LivePollinationsImageModels {
    param([object]$Config)

    try {
        $headers = @{}
        $key = Get-Prop $Config.api_keys 'pollinations' ''
        if (-not [string]::IsNullOrWhiteSpace($key)) { $headers['Authorization'] = "Bearer $key" }
        $res = Invoke-RestMethod -Uri 'https://gen.pollinations.ai/image/models' -Method GET `
            -Headers $headers -TimeoutSec 20 -EA Stop
        return @(
            $res |
            Where-Object {
                $_.name -and (
                    -not $_.PSObject.Properties['output_modalities'] -or
                    @($_.output_modalities) -contains 'image'
                )
            } |
            ForEach-Object {
                $price = ''
                if ($_.pricing -and $_.pricing.PSObject.Properties['image']) {
                    $currency = if ($_.pricing.PSObject.Properties['currency']) { $_.pricing.currency } else { 'pollen' }
                    $price = "cost $($_.pricing.image) $currency"
                }
                $note = @($_.description, $price) | Where-Object { $_ } | Select-Object -First 2
                [PSCustomObject]@{
                    Id = $_.name
                    Label = $_.name
                    Note = ($note -join ' | ')
                }
            } |
            Sort-Object Id -Unique
        )
    } catch {
        return @()
    }
}

function Get-LiveHuggingFaceImageModels {
    param([object]$Config)
    try {
        $amp = [char]38
        $uri = "https://huggingface.co/api/models?pipeline_tag=text-to-image${amp}sort=downloads${amp}direction=-1${amp}limit=20"
        $res = Invoke-RestMethod -Uri $uri -Method GET -TimeoutSec 20 -EA Stop
        $list = @($res)
        return @(
            $list | ForEach-Object {
                $dl = Get-Prop $_ 'downloads' 0
                $dlStr = Format-LargeCount $dl
                $modelId = Get-Prop $_ 'modelId' ''
                if ([string]::IsNullOrWhiteSpace($modelId)) { $modelId = Get-Prop $_ 'id' '' }
                [PSCustomObject]@{
                    Id    = $modelId
                    Label = $modelId
                    Note  = ('HF | {0} downloads' -f $dlStr)
                }
            } | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Id) }
        )
    } catch {
        return @()
    }
}

function Get-ImageModelOptions {
    param(
        [ValidateSet('openai','gemini','huggingface','pollinations')][string]$Provider,
        [object]$Config
    )

    $live = switch ($Provider) {
        'gemini'       { Get-LiveGeminiImageModels -Config $Config }
        'pollinations' { Get-LivePollinationsImageModels -Config $Config }
        'huggingface'  { Get-LiveHuggingFaceImageModels -Config $Config }
        default        { Get-LiveOpenAIImageModels -Config $Config }
    }

    if (@($live).Count -gt 0) {
        return [PSCustomObject]@{ Source='live'; Models=@($live) }
    }
    return [PSCustomObject]@{ Source='fallback'; Models=@(Get-FallbackImageModelCatalog -Provider $Provider) }
}

function Select-ImageModel {
    param(
        [object]$Config,
        [ValidateSet('openai','gemini','huggingface','pollinations')][string]$Provider,
        [string]$CurrentModel = ''
    )

    $options = Get-ImageModelOptions -Provider $Provider -Config $Config
    $sourceText = if ($options.Source -eq 'live') { 'Live provider list' } else { 'Built-in fallback list' }
    $items = @(
        $options.Models | ForEach-Object {
            $hint = if ($_.Id -eq $CurrentModel) { 'current' } else { $_.Note }
            $short = if ($_.Label -match '/') { ($_.Label -split '/')[-1] } else { $_.Label }
            New-MenuItem -Key $_.Id -Label $short -Value $_.Label -Hint $hint
        }
    )

    $selected = Invoke-NumberedMenu -Title "$($Provider.ToUpper()) Image Models" -Subtitle "Current: $CurrentModel  |  Source: $sourceText" -Items $items -PageSize 8 -AllowManual -Config $Config
    if (-not $selected) { return $CurrentModel }
    if ($selected.Key -eq '__manual') {
        Show-SettingsBanner
        Write-Host '  Image model' -ForegroundColor Cyan
        Write-Host "  Current: $CurrentModel" -ForegroundColor DarkGray
        $manual = (Read-Host '  Model ID').Trim()
        if ($manual) { return $manual }
        return $CurrentModel
    }
    return $selected.Key
}

function Get-SuggestedTtsModels {
    param([object[]]$Models)

    $defs = @(
        [PSCustomObject]@{ Slot='Fast';    Patterns=@('eleven_flash_v2_5', 'flash') },
        [PSCustomObject]@{ Slot='Lite';    Patterns=@('eleven_flash_v2($|[^_])', 'flash') },
        [PSCustomObject]@{ Slot='Complex'; Patterns=@('eleven_v3', 'multilingual_v2', 'multilingual') }
    )

    $suggestions = @()
    $used = @()
    foreach ($def in $defs) {
        $model = Select-FirstModelMatch -Models $Models -Patterns $def.Patterns -ExcludeIds $used
        if ($null -ne $model) {
            $used += $model.Id
            $suggestions += [PSCustomObject]@{
                Slot = $def.Slot
                Id = $model.Id
                Label = $model.Label
                Note = $model.Note
            }
        }
    }
    return @($suggestions)
}

function New-TtsModelPickerItems {
    param(
        [object[]]$Models,
        [string]$CurrentModel = ''
    )

    $suggested = @(Get-SuggestedTtsModels -Models $Models)
    $suggestedIds = @($suggested | ForEach-Object { $_.Id })
    $items = @()

    if ($suggested.Count -gt 0) { $items += New-MenuHeader -Label 'Suggested' }
    foreach ($model in $suggested) {
        $hint = if ($model.Id -eq $CurrentModel) { 'current' } else { $model.Note }
        $items += New-MenuItem -Key $model.Id -Label "Suggested $($model.Slot)" -Value $model.Label -Hint $hint
    }

    if ($Models.Count -gt $suggested.Count) { $items += New-MenuHeader -Label 'All TTS Models' }
    foreach ($model in @($Models | Where-Object { @($suggestedIds) -notcontains $_.Id })) {
        $hint = if ($model.Id -eq $CurrentModel) { 'current' } else { $model.Note }
        $items += New-MenuItem -Key $model.Id -Label $model.Label -Hint $hint
    }

    return @($items)
}

function Select-ElevenLabsVoice {
    param([object]$Config, [string]$CurrentVoiceId = '')
    $voices = @(Get-LiveElevenLabsVoices -Config $Config)
    $socialOnly = [bool](Get-Prop $Config.voice 'social_media_only' $false)
    if ($socialOnly) {
        $voices = @($voices | Where-Object {
            $_.UseCase -match 'social[_ -]?media' -or $_.Note -match 'social[_ -]?media'
        })
    }
    $source = if ($voices.Count -gt 0) { 'live ElevenLabs voice list' } else { 'manual entry only' }
    $filterText = if ($socialOnly) { ' | filter: social media only' } else { '' }
    $sharedSuggested = @(Get-LiveElevenLabsSharedSocialVoices -Config $Config)

    $items = @()
    if ($voices.Count -gt 0) {
        $items += New-VoicePickerItems -Voices $voices -CurrentVoiceId $CurrentVoiceId -SuggestedVoices $sharedSuggested
    } elseif ($sharedSuggested.Count -gt 0) {
        $items += New-VoicePickerItems -Voices @() -CurrentVoiceId $CurrentVoiceId -SuggestedVoices $sharedSuggested
    }
    $selected = Invoke-NumberedMenu -Title 'ElevenLabs Voices' -Subtitle "Current: $CurrentVoiceId  |  Source: $source$filterText" -Items $items -PageSize 10 -AllowManual -Config $Config
    if (-not $selected) { return $CurrentVoiceId }
    if ($selected.Key -eq '__manual') {
        Show-SettingsBanner
        Write-Host '  ElevenLabs voice ID' -ForegroundColor Cyan
        Write-Host "  Current: $CurrentVoiceId" -ForegroundColor DarkGray
        $manual = (Read-Host '  New voice ID').Trim()
        if ($manual) { return $manual }
        return $CurrentVoiceId
    }
    return $selected.Key
}

function Select-ElevenLabsTtsModel {
    param([object]$Config, [string]$CurrentModel = '')

    $options = Get-TtsModelOptions -Config $Config
    $models = @($options.Models)
    $sourceText = if ($options.Source -eq 'live') { 'Live ElevenLabs model list' } else { 'Built-in fallback list' }
    $items = @(New-TtsModelPickerItems -Models $models -CurrentModel $CurrentModel)

    $selected = Invoke-NumberedMenu -Title 'ElevenLabs TTS Models' -Subtitle "Current: $CurrentModel  |  Source: $sourceText" -Items $items -PageSize 10 -AllowManual -Config $Config
    if (-not $selected) { return $CurrentModel }
    if ($selected.Key -eq '__manual') {
        Show-SettingsBanner
        Write-Host '  ElevenLabs TTS model' -ForegroundColor Cyan
        Write-Host "  Current: $CurrentModel" -ForegroundColor DarkGray
        $manual = (Read-Host '  Model ID').Trim()
        if ($manual) { return $manual }
        return $CurrentModel
    }
    return $selected.Key
}

function Select-ModelFromList {
    param(
        [ValidateSet('openai','gemini','huggingface')][string]$Backend,
        [string]$CurrentModel = '',
        [object]$Config
    )
    $Backend = Normalize-AIBackend $Backend
    $options = Get-ModelOptions -Backend $Backend -Config $Config
    $models = @($options.Models)
    $sourceText = if ($options.Source -eq 'live') { 'Live provider list' } else { 'Built-in fallback list' }
    $items = @(New-ModelPickerItems -Backend $Backend -Models $models -CurrentModel $CurrentModel)
    $selected = Invoke-NumberedMenu -Title "$($Backend.ToUpper()) Models" -Subtitle "Current: $CurrentModel  |  Source: $sourceText" -Items $items -PageSize 8 -AllowManual -Config $Config
    if (-not $selected) { return $CurrentModel }
    if ($selected.Key -eq '__manual') {
        Show-SettingsBanner
        Write-Host "  $($Backend.ToUpper()) model" -ForegroundColor Cyan
        $manual = (Read-Host '  Model name').Trim()
        if ($manual) { return $manual }
        return $CurrentModel
    }
    return $selected.Key
}

function Invoke-ModelCheck {
    param([object]$Config, [switch]$NoPause)
    Write-Host "`n  Ã¢â‚¬â€ Model Check Ã¢â‚¬â€`n" -ForegroundColor Cyan
    foreach ($backend in @('openai','gemini','huggingface')) {
        $current = Get-Prop $Config.ai.$backend 'model' ''
        $options = Get-ModelOptions -Backend $backend -Config $Config
        $known   = @(@($options.Models) | Where-Object { $_.Id -eq $current }).Count -gt 0
        $source  = if ($options.Source -eq 'live') { 'live' } else { 'fallback' }
        $icon    = if ($current -and $known) { 'OK' } elseif ($current) { 'CUSTOM' } else { 'MISSING' }
        $color   = if ($current -and $known) { 'Green' } elseif ($current) { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-6} {1,-7} {2}  ({3})" -f $icon, $backend, $(if ($current) { $current } else { '[not set]' }), $source) -ForegroundColor $color
    }

    $imageProvider = Get-Prop $Config.images 'provider' 'openai'
    if ($imageProvider -in @('openai','gemini','huggingface','pollinations')) {
        $currentImage = Get-Prop $Config.images 'model' ''
        $imageOptions = Get-ImageModelOptions -Provider $imageProvider -Config $Config
        $knownImage = @(@($imageOptions.Models) | Where-Object { $_.Id -eq $currentImage }).Count -gt 0
        $imageSource = if ($imageOptions.Source -eq 'live') { 'live' } else { 'fallback' }
        $imageIcon = if ($currentImage -and $knownImage) { 'OK' } elseif ($currentImage) { 'CUSTOM' } else { 'MISSING' }
        $imageColor = if ($currentImage -and $knownImage) { 'Green' } elseif ($currentImage) { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-6} image   {1}/{2}  ({3})" -f $imageIcon, $imageProvider, $(if ($currentImage) { $currentImage } else { '[not set]' }), $imageSource) -ForegroundColor $imageColor
    }

    Write-Host ''
    Write-Host '  Live checks use your configured API keys. If a provider cannot be reached,' -ForegroundColor DarkGray
    Write-Host '  settings falls back to a small built-in list so the app still works offline.' -ForegroundColor DarkGray
    if (-not $NoPause) { Read-Host "`n  Press Enter to continue" }
}

function Initialize-MissingModels {
    param([object]$Config)
    $changed = $false

    if ([string]::IsNullOrWhiteSpace((Get-Prop $Config.ai.openai 'model' ''))) {
        $chosen = Select-ModelFromList -Backend openai -CurrentModel 'o4-mini' -Config $Config
        Set-Prop $Config.ai.openai 'model' $chosen
        $changed = $true
    }

    if ([string]::IsNullOrWhiteSpace((Get-Prop $Config.ai.gemini 'model' ''))) {
        $chosen = Select-ModelFromList -Backend gemini -CurrentModel 'gemini-2.5-flash' -Config $Config
        Set-Prop $Config.ai.gemini 'model' $chosen
        $changed = $true
    }

    return $changed
}

function Test-ModelMissingBeforeShape {
    param([object]$Config)
    if ($null -eq $Config) { return $true }
    if (-not $Config.PSObject.Properties['ai']) { return $true }
    foreach ($backend in @('openai','gemini','huggingface')) {
        if (-not $Config.ai.PSObject.Properties[$backend]) { return $true }
        if (-not $Config.ai.$backend.PSObject.Properties['model']) { return $true }
        if ([string]::IsNullOrWhiteSpace($Config.ai.$backend.model)) { return $true }
    }
    return $false
}

# Ensure all expected nested objects exist before any read/write
function Assert-ConfigShape {
    param([object]$Config)
    
    if (-not (Get-Command Get-ConfigDefaults -ErrorAction SilentlyContinue)) { return }
    $defaults = Get-ConfigDefaults

    foreach ($k in $defaults.Keys) {
        if (-not $Config.PSObject.Properties[$k]) {
            Set-Prop $Config $k ($defaults[$k] | ConvertTo-Json -Depth 6 | ConvertFrom-Json)
        } else {
            $sub = $defaults[$k]
            if ($sub -is [System.Collections.IDictionary]) {
                foreach ($subK in $sub.Keys) {
                    if (-not $Config.$k.PSObject.Properties[$subK]) {
                        Set-Prop $Config.$k $subK $sub[$subK]
                    }
                }
            }
        }
    }
    
    foreach ($backend in @('openai','gemini','huggingface')) {
        if (-not $Config.ai.PSObject.Properties[$backend]) {
            Set-Prop $Config.ai $backend ($defaults.ai[$backend] | ConvertTo-Json | ConvertFrom-Json)
        } else {
            foreach ($bk in $defaults.ai[$backend].Keys) {
                if (-not $Config.ai.$backend.PSObject.Properties[$bk]) {
                    Set-Prop $Config.ai.$backend $bk $defaults.ai[$backend][$bk]
                }
            }
        }
    }
    
    if (-not $Config.images.PSObject.Properties['composite_layout']) {
        $grid = [Math]::Min(2, [Math]::Max(1, [int](Get-Prop $Config.images 'composite_grid' 1)))
        Set-Prop $Config.images 'composite_layout' "${grid}x${grid}"
    }

    foreach ($prop in @('primary', 'fallback')) {
        $backend = Normalize-AIBackend (Get-Prop $Config.ai $prop '')
        if ($backend -ne (Get-Prop $Config.ai $prop '')) {
            Set-Prop $Config.ai $prop $backend
        }
    }

    if ($Config.ai.PSObject.Properties['codex']) {
        $legacyModel = Get-Prop $Config.ai.codex 'model' ''
        if ($legacyModel -and [string]::IsNullOrWhiteSpace((Get-Prop $Config.ai.openai 'model' ''))) {
            Set-Prop $Config.ai.openai 'model' $legacyModel
        }
    }
}

# Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ 
# DISPLAY  Ã¢â‚¬â€ Render each settings section
# Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ Ã¢â€¢ 

function Show-SettingsBanner {
    Clear-Host
    Write-Host ''
    $border = '-' * 71
    Write-Host "  +$border+" -ForegroundColor Cyan
    Write-Host '  |                        VIDEO FACTORY - SETTINGS                         |' -ForegroundColor Cyan
    Write-Host "  +$border+" -ForegroundColor Cyan
    Write-Host ''
}

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# HANDLERS  Ã¢â‚¬â€ One function per settings section
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

function Edit-ApiKeys {
    param([object]$Config)
    while ($true) {
        $items = @(
            New-MenuItem -Key 'openai' -Label 'OpenAI API key' -Value (Mask-Key (Get-Prop $Config.api_keys 'openai')) -Hint 'API key required'
            New-MenuItem -Key 'elevenlabs' -Label 'ElevenLabs API key' -Value (Mask-Key (Get-Prop $Config.api_keys 'elevenlabs')) -Hint 'API key required'
            New-MenuItem -Key 'gemini_key' -Label 'Gemini API key' -Value (Mask-Key (Get-Prop $Config.api_keys 'gemini')) -Hint 'API key required'
            New-MenuItem -Key 'pollinations_key' -Label 'Pollinations API key' -Value (Mask-Key (Get-Prop $Config.api_keys 'pollinations')) -Hint 'optional for image generation'
            New-MenuItem -Key 'huggingface_key' -Label 'Hugging Face API key' -Value (Mask-Key (Get-Prop $Config.api_keys 'huggingface')) -Hint 'API key required'
            New-MenuItem -Key 'login_info' -Label 'Account login status' -Value 'not available for API calls'
            New-MenuItem -Key 'open_openai' -Label 'Open OpenAI key page'
            New-MenuItem -Key 'open_gemini' -Label 'Open Gemini key page'
            New-MenuItem -Key 'open_elevenlabs' -Label 'Open ElevenLabs keys'
            New-MenuItem -Key 'open_pollinations' -Label 'Open Pollinations'
        )
        $selected = Invoke-NumberedMenu -Title 'API Keys' -Subtitle 'Provider account login cannot power these API calls directly; use API keys.' -Items $items -Config $Config
        if (-not $selected) { return }

        Show-SettingsBanner
        switch ($selected.Key) {
            'openai' {
                $k = (Read-Host '  OpenAI API key').Trim()
                if ($k) { Set-Prop $Config.api_keys 'openai' $k }
            }
            'elevenlabs' {
                $k = (Read-Host '  ElevenLabs API key').Trim()
                if ($k) {
                    Set-Prop $Config.api_keys 'elevenlabs' $k
                    Write-Host '    Validating...' -NoNewline -ForegroundColor DarkGray
                    $ok = try {
                        Invoke-RestMethod -Uri 'https://api.elevenlabs.io/v1/user' `
                            -Headers @{'xi-api-key'=$k} -EA Stop | Out-Null; $true
                    } catch { $false }
                    Write-Host $(if ($ok) { ' OK Valid' } else { ' Unreachable or invalid' }) `
                        -ForegroundColor $(if ($ok) { 'Green' } else { 'Yellow' })
                    Start-Sleep 1
                }
            }
            'gemini_key' {
                $k = (Read-Host '  Gemini API key').Trim()
                if ($k) { Set-Prop $Config.api_keys 'gemini' $k }
            }
            'pollinations_key' {
                $k = (Read-Host '  Pollinations API key (blank = keep current)').Trim()
                if ($k) { Set-Prop $Config.api_keys 'pollinations' $k }
            }
            'huggingface_key' {
                $k = (Read-Host '  Hugging Face API key (blank = keep current)').Trim()
                if ($k) { Set-Prop $Config.api_keys 'huggingface' $k }
            }
            'login_info' {
                Write-Host '  Account login is different from API access.' -ForegroundColor Cyan
                Write-Host ''
                Write-Host '  OpenAI: ChatGPT account login cannot be linked to normal API calls.' -ForegroundColor White
                Write-Host '  Gemini: browser login requires Google OAuth app setup or Google Cloud CLI.' -ForegroundColor White
                Write-Host '  ElevenLabs: API calls use API keys.' -ForegroundColor White
                Write-Host '  Pollinations: image calls use public mode or an API key.' -ForegroundColor White
                Write-Host ''
                Write-Host '  The stable no-extra-dependency option is API keys.' -ForegroundColor Yellow
                Read-Host '  Press Enter to continue'
            }
            'open_openai' {
                Start-Process 'https://platform.openai.com/api-keys'
            }
            'open_gemini' {
                Start-Process 'https://aistudio.google.com/apikey'
            }
            'open_elevenlabs' {
                Start-Process 'https://elevenlabs.io/app/settings/api-keys'
            }
            'open_pollinations' {
                Start-Process 'https://enter.pollinations.ai/'
            }
        }
    }
}

function Edit-AIBackend {
    param([object]$Config)
    while ($true) {
        $primary = Get-Prop $Config.ai 'primary' 'openai'
        $items = @(
            New-MenuItem -Key 'primary'       -Label 'Primary backend'     -Value (Get-Prop $Config.ai 'primary' 'openai')
            New-MenuItem -Key 'fallback'      -Label 'Fallback backend'    -Value (Get-Prop $Config.ai 'fallback' 'gemini')
            New-MenuItem -Key 'auto_fallback' -Label 'Auto fallback'       -Value (Get-Prop $Config.ai 'auto_fallback' $true)
        )
        if ($primary -eq 'gemini') {
            $items += @(
                New-MenuHeader -Label 'Selected Gemini Settings'
                New-MenuItem -Key 'gemini_model'  -Label 'Gemini model'        -Value (Get-Prop $Config.ai.gemini 'model' 'gemini-2.5-flash')
                New-MenuItem -Key 'gemini_approval' -Label 'Gemini approval'   -Value (Get-Prop $Config.ai.gemini 'approval_mode' 'auto_edit')
                New-MenuItem -Key 'gemini_timeout'-Label 'Gemini timeout'      -Value "$(Get-Prop $Config.ai.gemini 'timeout_seconds' 300)s"
                New-MenuItem -Key 'gemini_cli'    -Label 'Gemini CLI path'     -Value (Get-Prop $Config.ai.gemini 'cli_path' 'gemini')
            )
        } elseif ($primary -eq 'huggingface') {
            $items += @(
                New-MenuHeader -Label 'Selected Hugging Face Settings'
                New-MenuItem -Key 'hf_model' -Label 'HF model' -Value (Get-Prop $Config.ai.huggingface 'model' 'meta-llama/Meta-Llama-3-8B-Instruct')
            )
        } else {
            $items += @(
                New-MenuHeader -Label 'Selected openai Settings'
                New-MenuItem -Key 'openai_model'   -Label 'openai model'         -Value (Get-Prop $Config.ai.openai 'model' 'o4-mini')
                New-MenuItem -Key 'openai_approval'-Label 'openai approval'      -Value (Get-Prop $Config.ai.openai 'approval_mode' 'full-auto')
            )
        }
        $items += New-MenuItem -Key 'model_check' -Label 'Check/select selected model' -Hint 'live provider list'

        $selected = Invoke-NumberedMenu -Title 'Main AI' -Subtitle "Only showing settings for selected backend: $primary." -Items $items -Config $Config
        if (-not $selected) { return }

        switch ($selected.Key) {
            'primary' {
                $v = Select-Choice -Title 'Primary Backend' -CurrentValue (Get-Prop $Config.ai 'primary' 'openai') -Choices @(
                    [PSCustomObject]@{ Label='openai'; Value='openai' },
                    [PSCustomObject]@{ Label='Gemini'; Value='gemini' },
                    [PSCustomObject]@{ Label='Hugging Face'; Value='huggingface' }
                )
                Set-Prop $Config.ai 'primary' $v
            }
            'fallback' {
                $v = Select-Choice -Title 'Fallback Backend' -CurrentValue (Get-Prop $Config.ai 'fallback' 'gemini') -Choices @(
                    [PSCustomObject]@{ Label='openai'; Value='openai' },
                    [PSCustomObject]@{ Label='Gemini'; Value='gemini' },
                    [PSCustomObject]@{ Label='Hugging Face'; Value='huggingface' }
                )
                Set-Prop $Config.ai 'fallback' $v
            }
            'auto_fallback' {
                Set-Prop $Config.ai 'auto_fallback' (-not [bool](Get-Prop $Config.ai 'auto_fallback' $true))
            }
            'openai_model' {
                Set-Prop $Config.ai.openai 'model' (Select-ModelFromList -Backend openai -CurrentModel (Get-Prop $Config.ai.openai 'model' 'o4-mini') -Config $Config)
            }
            'openai_approval' {
                $v = Select-Choice -Title 'openai Approval' -CurrentValue (Get-Prop $Config.ai.openai 'approval_mode' 'full-auto') -Choices @(
                    [PSCustomObject]@{ Label='Full auto'; Value='full-auto' },
                    [PSCustomObject]@{ Label='Suggest'; Value='suggest' }
                )
                Set-Prop $Config.ai.openai 'approval_mode' $v
            }
            'hf_model' {
                Set-Prop $Config.ai.huggingface 'model' (Select-ModelFromList -Backend huggingface -CurrentModel (Get-Prop $Config.ai.huggingface 'model' 'meta-llama/Meta-Llama-3-8B-Instruct') -Config $Config)
            }
            'gemini_model' {
                Set-Prop $Config.ai.gemini 'model' (Select-ModelFromList -Backend gemini -CurrentModel (Get-Prop $Config.ai.gemini 'model' 'gemini-2.5-flash') -Config $Config)
            }
            'gemini_approval' {
                $v = Select-Choice -Title 'Gemini Approval' -CurrentValue (Get-Prop $Config.ai.gemini 'approval_mode' 'auto_edit') -Choices @(
                    [PSCustomObject]@{ Label='Default'; Value='default' },
                    [PSCustomObject]@{ Label='Auto edit'; Value='auto_edit' },
                    [PSCustomObject]@{ Label='Yolo'; Value='yolo' },
                    [PSCustomObject]@{ Label='Plan'; Value='plan' }
                )
                Set-Prop $Config.ai.gemini 'approval_mode' $v
            }
            'gemini_timeout' {
                Show-SettingsBanner
                Write-Host '  Gemini timeout seconds' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.ai.gemini 'timeout_seconds' 300)" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d+$') { Set-Prop $Config.ai.gemini 'timeout_seconds' ([int]$v) }
            }
            'gemini_cli' {
                Show-SettingsBanner
                Write-Host '  Gemini CLI path' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.ai.gemini 'cli_path' 'gemini')" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v) { Set-Prop $Config.ai.gemini 'cli_path' $v }
            }
            'model_check' {
                Edit-Models -Config $Config
            }
        }
    }
}

function Edit-Models {
    param([object]$Config)
    while ($true) {
        $storedPrimary = Get-Prop $Config.ai 'primary' 'openai'
        $storedFallback = Get-Prop $Config.ai 'fallback' 'gemini'
        $primary = Normalize-AIBackend $storedPrimary
        $fallback = Normalize-AIBackend $storedFallback
        if ($primary -ne $storedPrimary) { Set-Prop $Config.ai 'primary' $primary }
        if ($fallback -ne $storedFallback) { Set-Prop $Config.ai 'fallback' $fallback }
        $primaryOptions = Get-ModelOptions -Backend $primary -Config $Config
        $items = @(
            New-MenuItem -Key 'primary_model' -Label "Select $primary model" -Value (Get-Prop $Config.ai.$primary 'model' '') -Hint $primaryOptions.Source
            New-MenuItem -Key 'check' -Label 'Show model check'
        )
        if ($fallback -and $fallback -ne $primary) {
            $items += New-MenuItem -Key 'fallback_model' -Label "Select fallback $fallback model" -Value (Get-Prop $Config.ai.$fallback 'model' '') -Hint 'optional'
        }
        $items += New-MenuItem -Key 'change_fallback' -Label 'Change Fallback Provider' -Value $fallback -Hint 'toggle'
        $selected = Invoke-NumberedMenu -Title 'Main AI Models' -Subtitle "Selected backend: $primary. Live provider lists are used when keys are available." -Items $items -Config $Config
        if (-not $selected) { return }

        switch ($selected.Key) {
            'primary_model' { Set-Prop $Config.ai.$primary 'model' (Select-ModelFromList -Backend $primary -CurrentModel (Get-Prop $Config.ai.$primary 'model' '') -Config $Config) }
            'fallback_model' { Set-Prop $Config.ai.$fallback 'model' (Select-ModelFromList -Backend $fallback -CurrentModel (Get-Prop $Config.ai.$fallback 'model' '') -Config $Config) }
            'change_fallback' {
                $v = Select-Choice -Title 'Fallback Backend' -CurrentValue (Get-Prop $Config.ai 'fallback' 'gemini') -Choices @(
                    [PSCustomObject]@{ Label='OpenAI'; Value='openai' },
                    [PSCustomObject]@{ Label='Gemini'; Value='gemini' },
                    [PSCustomObject]@{ Label='Hugging Face'; Value='huggingface' }
                )
                Set-Prop $Config.ai 'fallback' $v
            }
            'check' {
                Show-SettingsBanner
                Invoke-ModelCheck -Config $Config
            }
        }
    }
}

function Edit-VoiceSettings {
    param([object]$Config)
    while ($true) {
        $provider = Get-Prop $Config.voice 'provider' 'elevenlabs'
        $items = @(
            New-MenuHeader -Label 'Voice Generation'
            New-MenuItem -Key 'provider' -Label 'TTS Provider' -Value $provider
        )

        if ($provider -eq 'elevenlabs') {
            $items += @(
                New-MenuItem -Key 'voice_id' -Label 'ElevenLabs Voice ID' -Value (Get-Prop $Config.voice 'voice_id')
                New-MenuItem -Key 'social_only' -Label 'Show only social media voices' -Value (Get-Prop $Config.voice 'social_media_only' $false)
                New-MenuItem -Key 'model_id' -Label 'ElevenLabs TTS model' -Value (Get-Prop $Config.voice 'model_id' 'eleven_flash_v2_5')
                New-MenuItem -Key 'stability' -Label 'Stability' -Value (Get-Prop $Config.voice 'stability')
                New-MenuItem -Key 'similarity' -Label 'Similarity boost' -Value (Get-Prop $Config.voice 'similarity_boost')
                New-MenuItem -Key 'speed' -Label 'Speed' -Value (Get-Prop $Config.voice 'speed')
            )
        } elseif ($provider -eq 'edge-tts') {
            $items += @(
                New-MenuItem -Key 'edge_voice' -Label 'Edge TTS Voice' -Value (Get-Prop $Config.voice 'edge_voice' 'en-US-ChristopherNeural')
            )
        }

        $items += @(
            New-MenuHeader -Label 'Audio Cleanup'
            New-MenuItem -Key 'silence_thresh' -Label 'Silence threshold' -Value "$(Get-Prop $Config.audio 'silence_thresh_dbfs') dBFS"
            New-MenuItem -Key 'min_silence' -Label 'Min silence length' -Value "$(Get-Prop $Config.audio 'min_silence_len_ms') ms"
            New-MenuItem -Key 'keep_silence' -Label 'Keep padding' -Value "$(Get-Prop $Config.audio 'keep_silence_ms') ms"
        )
        $selected = Invoke-NumberedMenu -Title 'Voice / Audio' -Subtitle 'Voice choice, TTS model, and audio cleanup live together here.' -Items $items -Config $Config
        if (-not $selected) { return }

        Show-SettingsBanner
        switch ($selected.Key) {
            'provider' {
                $v = Select-Choice -Title 'TTS Provider' -CurrentValue (Get-Prop $Config.voice 'provider' 'elevenlabs') -Choices @(
                    [PSCustomObject]@{ Label='ElevenLabs (Premium)'; Value='elevenlabs' },
                    [PSCustomObject]@{ Label='Edge TTS (Free)'; Value='edge-tts' }
                )
                Set-Prop $Config.voice 'provider' $v
            }
            'edge_voice' {
                Write-Host '  Edge TTS Voice' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.voice 'edge_voice')" -ForegroundColor DarkGray
                $v = (Read-Host '  New voice name (e.g. en-US-ChristopherNeural)').Trim()
                if ($v) { Set-Prop $Config.voice 'edge_voice' $v }
            }
            'voice_id' {
                Set-Prop $Config.voice 'voice_id' (Select-ElevenLabsVoice -Config $Config -CurrentVoiceId (Get-Prop $Config.voice 'voice_id'))
            }
            'social_only' {
                Set-Prop $Config.voice 'social_media_only' (-not [bool](Get-Prop $Config.voice 'social_media_only' $false))
            }
            'model_id' {
                Set-Prop $Config.voice 'model_id' (Select-ElevenLabsTtsModel -Config $Config -CurrentModel (Get-Prop $Config.voice 'model_id' 'eleven_flash_v2_5'))
            }
            'stability' {
                Write-Host '  Stability [0.0 - 1.0]' -ForegroundColor Cyan
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d*\.?\d+$') { Set-Prop $Config.voice 'stability' ([double]$v) }
            }
            'similarity' {
                Write-Host '  Similarity boost [0.0 - 1.0]' -ForegroundColor Cyan
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d*\.?\d+$') { Set-Prop $Config.voice 'similarity_boost' ([double]$v) }
            }
            'speed' {
                Write-Host '  Speed [0.5 - 2.0]' -ForegroundColor Cyan
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d*\.?\d+$') { Set-Prop $Config.voice 'speed' ([double]$v) }
            }
            'silence_thresh' {
                Write-Host '  Silence threshold dBFS' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.audio 'silence_thresh_dbfs')" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^-?\d+$') { Set-Prop $Config.audio 'silence_thresh_dbfs' ([int]$v) }
            }
            'min_silence' {
                Write-Host '  Min silence length ms' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.audio 'min_silence_len_ms')" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d+$') { Set-Prop $Config.audio 'min_silence_len_ms' ([int]$v) }
            }
            'keep_silence' {
                Write-Host '  Keep silence padding ms' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.audio 'keep_silence_ms')" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d+$') { Set-Prop $Config.audio 'keep_silence_ms' ([int]$v) }
            }
        }
    }
}

function Edit-ImageSettings {
    param([object]$Config)
    while ($true) {
        $provider = Get-Prop $Config.images 'provider' 'openai'
        $items = @(
            New-MenuItem -Key 'mode'     -Label 'Mode'             -Value (Get-Prop $Config.images 'mode' 'auto_review')
            New-MenuItem -Key 'provider' -Label 'Provider'         -Value $provider
            New-MenuItem -Key 'model'    -Label 'Image model'      -Value (Get-Prop $Config.images 'model' 'gpt-image-1.5')
            New-MenuItem -Key 'layout'   -Label 'Composite saving level' -Value (Get-CompositeLayoutLabel (Get-Prop $Config.images 'composite_layout' '1x1'))
            New-MenuItem -Key 'tokens_info' -Label 'Tokens'        -Value (Get-ImageTokenText -Config $Config)
        )
        $providerSection = $provider
        if ($provider -eq 'gemini') {
            $items += @(
                New-MenuHeader -Label 'Selected Gemini Image Settings'
                New-MenuItem -Key 'ratio'    -Label 'Aspect ratio'     -Value (Get-Prop $Config.images 'aspect_ratio' '16:9')
                New-MenuItem -Key 'gsize'    -Label 'Image size'       -Value (Get-Prop $Config.images 'image_size' '1K')
            )
        } elseif ($provider -eq 'pollinations') {
            $items += @(
                New-MenuHeader -Label 'Selected Pollinations Settings'
                New-MenuItem -Key 'pwidth'   -Label 'Width'           -Value (Get-Prop $Config.images 'pollinations_width' 1536)
                New-MenuItem -Key 'pheight'  -Label 'Height'          -Value (Get-Prop $Config.images 'pollinations_height' 864)
                New-MenuItem -Key 'pseed'    -Label 'Seed'            -Value (Get-Prop $Config.images 'pollinations_seed' -1)
                New-MenuItem -Key 'penhance' -Label 'Enhance prompt'  -Value (Get-Prop $Config.images 'pollinations_enhance' $false)
                New-MenuItem -Key 'psafe'    -Label 'Safe mode'       -Value (Get-Prop $Config.images 'pollinations_safe' $true)
                New-MenuItem -Key 'pnegative' -Label 'Negative prompt' -Value (Get-Prop $Config.images 'pollinations_negative_prompt' '')
            )
        } elseif ($provider -eq 'openai') {
            $items += @(
                New-MenuHeader -Label 'Selected OpenAI Image Settings'
                New-MenuItem -Key 'size'     -Label 'Size'            -Value (Get-Prop $Config.images 'size' '1536x1024')
                New-MenuItem -Key 'quality'  -Label 'Quality'         -Value (Get-Prop $Config.images 'quality' 'medium')
            )
            $providerSection = 'openai'
        } else {
            $items += @(
                New-MenuHeader -Label 'Selected Hugging Face Image Settings'
                New-MenuItem -Key 'hf_info' -Label 'Inference' -Value 'HF Inference API (model repo ID)'
                New-MenuItem -Key 'hf_note' -Label 'API key' -Value (if ([string]::IsNullOrWhiteSpace((Get-Prop $Config.api_keys 'huggingface' ''))) { 'not set — add in API keys' } else { 'configured' })
            )
            $providerSection = 'huggingface'
        }
        if (-not $providerSection) { $providerSection = $provider }
        $items += @(
            New-MenuItem -Key 'retries'  -Label 'Retries'          -Value (Get-Prop $Config.images 'retries' 2)
            New-MenuItem -Key 'provider_fallback' -Label 'Provider fallback' -Value (Get-Prop $Config.images 'auto_provider_fallback' $false) -Hint 'switch failed provider to OpenAI'
            New-MenuItem -Key 'fallback' -Label 'Manual fallback'  -Value (Get-Prop $Config.images 'fallback_to_manual' $true)
        )
        $selected = Invoke-NumberedMenu -Title 'Images/AI' -Subtitle "Only showing settings for selected image provider: $provider." -Items $items -Config $Config
        if (-not $selected) { return }

        switch ($selected.Key) {
            'mode' {
                $v = Select-Choice -Title 'Image Mode' -CurrentValue (Get-Prop $Config.images 'mode' 'auto_review') -Choices @(
                    [PSCustomObject]@{ Label='Auto then review'; Value='auto_review' },
                    [PSCustomObject]@{ Label='Auto'; Value='auto' },
                    [PSCustomObject]@{ Label='Manual folder drop'; Value='manual' }
                )
                Set-Prop $Config.images 'mode' $v
            }
            'provider' {
                $v = Select-Choice -Title 'Image Provider' -CurrentValue (Get-Prop $Config.images 'provider' 'openai') -Choices @(
                    [PSCustomObject]@{ Label='OpenAI'; Value='openai' },
                    [PSCustomObject]@{ Label='Gemini'; Value='gemini' },
                    [PSCustomObject]@{ Label='Pollinations'; Value='pollinations' },
                    [PSCustomObject]@{ Label='Hugging Face'; Value='huggingface' }
                )
                Set-Prop $Config.images 'provider' $v
                if ($v -eq 'openai' -and (Get-Prop $Config.images 'model' '') -notmatch '^(gpt-image|dall-e)') {
                    Set-Prop $Config.images 'model' 'gpt-image-1.5'
                }
                if ($v -eq 'gemini' -and (Get-Prop $Config.images 'model' '') -notmatch 'image|imagen') {
                    Set-Prop $Config.images 'model' 'gemini-3.1-flash-image-preview'
                }
                if ($v -eq 'pollinations' -and (Get-Prop $Config.images 'model' '') -match '^(gpt-image|dall-e|gemini|imagen)') {
                    Set-Prop $Config.images 'model' 'flux'
                }
                if ($v -eq 'huggingface' -and (Get-Prop $Config.images 'model' '') -match '^(gpt-image|dall-e|gemini|imagen|flux|turbo|kontext|seedream|nanobanana)') {
                    Set-Prop $Config.images 'model' 'stabilityai/stable-diffusion-xl-base-1.0'
                }
            }
            'model' {
                $provider = Get-Prop $Config.images 'provider' 'openai'
                Set-Prop $Config.images 'model' (Select-ImageModel -Config $Config -Provider $provider -CurrentModel (Get-Prop $Config.images 'model' 'gpt-image-1.5'))
            }
            'layout' {
                $v = Select-Choice -Title 'Composite Saving Level' -CurrentValue (Get-Prop $Config.images 'composite_layout' '1x1') -Choices @(
                    [PSCustomObject]@{ Label='Level 0 normal, 1 scene per image'; Value='1x1' },
                    [PSCustomObject]@{ Label='Level 1 saver, 1x2, 2 scenes per image'; Value='1x2' },
                    [PSCustomObject]@{ Label='Level 1 saver, 2x1, 2 scenes per image'; Value='2x1' },
                    [PSCustomObject]@{ Label='Level 2 heavy saver, 2x2, 4 scenes per image'; Value='2x2' }
                )
                Set-Prop $Config.images 'composite_layout' $v
                if ($v -match '^(\d+)x(\d+)$') {
                    Set-Prop $Config.images 'composite_grid' ([Math]::Max([int]$Matches[1], [int]$Matches[2]))
                }
            }
            'tokens_info' {
                Show-SettingsBanner
                Write-Host '  Image token estimate' -ForegroundColor Cyan
                Write-Host "  $(Get-ImageTokenText -Config $Config)" -ForegroundColor White
                Write-Host ''
                Write-Host '  Composite saving levels reduce generated image calls, so the per-scene estimate drops when one generated image contains multiple scenes.' -ForegroundColor DarkGray
                Read-Host '  Press Enter to continue'
            }
            'hf_info' {
                Show-SettingsBanner
                Write-Host '  Hugging Face image generation' -ForegroundColor Cyan
                Write-Host '  Uses the Inference API with a model repo ID (e.g. stabilityai/stable-diffusion-xl-base-1.0).' -ForegroundColor White
                Write-Host '  Set your HF API key under Settings -> API keys.' -ForegroundColor DarkGray
                Read-Host '  Press Enter to continue'
            }
            'hf_note' {
                Show-SettingsBanner
                $hfKey = Get-Prop $Config.api_keys 'huggingface' ''
                Write-Host '  Hugging Face API key' -ForegroundColor Cyan
                if ([string]::IsNullOrWhiteSpace($hfKey)) {
                    Write-Host '  Not set. Add it under Settings -> API keys -> Hugging Face API key.' -ForegroundColor Yellow
                } else {
                    Write-Host "  Configured: $(Mask-Key $hfKey)" -ForegroundColor Green
                }
                Read-Host '  Press Enter to continue'
            }
            'size' {
                $v = Select-Choice -Title 'OpenAI Image Size' -CurrentValue (Get-Prop $Config.images 'size' '1536x1024') -Choices @(
                    [PSCustomObject]@{ Label='Landscape'; Value='1536x1024' },
                    [PSCustomObject]@{ Label='Square'; Value='1024x1024' },
                    [PSCustomObject]@{ Label='Portrait'; Value='1024x1536' }
                )
                Set-Prop $Config.images 'size' $v
            }
            'quality' {
                $v = Select-Choice -Title 'OpenAI Image Quality' -CurrentValue (Get-Prop $Config.images 'quality' 'medium') -Choices @(
                    [PSCustomObject]@{ Label='Medium'; Value='medium' },
                    [PSCustomObject]@{ Label='Low'; Value='low' },
                    [PSCustomObject]@{ Label='High'; Value='high' }
                )
                Set-Prop $Config.images 'quality' $v
            }
            'ratio' {
                $v = Select-Choice -Title 'Gemini Aspect Ratio' -CurrentValue (Get-Prop $Config.images 'aspect_ratio' '16:9') -Choices @(
                    [PSCustomObject]@{ Label='Wide'; Value='16:9' },
                    [PSCustomObject]@{ Label='Square'; Value='1:1' },
                    [PSCustomObject]@{ Label='Portrait'; Value='9:16' },
                    [PSCustomObject]@{ Label='Classic'; Value='4:3' }
                )
                Set-Prop $Config.images 'aspect_ratio' $v
            }
            'gsize' {
                $v = Select-Choice -Title 'Gemini Image Size' -CurrentValue (Get-Prop $Config.images 'image_size' '1K') -Choices @(
                    [PSCustomObject]@{ Label='1K'; Value='1K' },
                    [PSCustomObject]@{ Label='2K'; Value='2K' },
                    [PSCustomObject]@{ Label='4K'; Value='4K' }
                )
                Set-Prop $Config.images 'image_size' $v
            }
            'pwidth' {
                Show-SettingsBanner
                Write-Host '  Pollinations width' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.images 'pollinations_width' 1536)" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d+$') { Set-Prop $Config.images 'pollinations_width' ([int]$v) }
            }
            'pheight' {
                Show-SettingsBanner
                Write-Host '  Pollinations height' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.images 'pollinations_height' 864)" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d+$') { Set-Prop $Config.images 'pollinations_height' ([int]$v) }
            }
            'pseed' {
                Show-SettingsBanner
                Write-Host '  Pollinations seed' -ForegroundColor Cyan
                Write-Host '  Use -1 for random.' -ForegroundColor DarkGray
                Write-Host "  Current: $(Get-Prop $Config.images 'pollinations_seed' -1)" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^-?\d+$') { Set-Prop $Config.images 'pollinations_seed' ([int]$v) }
            }
            'penhance' {
                Set-Prop $Config.images 'pollinations_enhance' (-not [bool](Get-Prop $Config.images 'pollinations_enhance' $false))
            }
            'psafe' {
                Set-Prop $Config.images 'pollinations_safe' (-not [bool](Get-Prop $Config.images 'pollinations_safe' $true))
            }
            'pnegative' {
                Show-SettingsBanner
                Write-Host '  Pollinations negative prompt' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.images 'pollinations_negative_prompt' '')" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v) { Set-Prop $Config.images 'pollinations_negative_prompt' $v }
            }
            'retries' {
                Show-SettingsBanner
                Write-Host '  Image retries' -ForegroundColor Cyan
                Write-Host "  Current: $(Get-Prop $Config.images 'retries' 2)" -ForegroundColor DarkGray
                $v = (Read-Host '  New value').Trim()
                if ($v -match '^\d+$') { Set-Prop $Config.images 'retries' ([int]$v) }
            }
            'fallback' {
                Set-Prop $Config.images 'fallback_to_manual' (-not [bool](Get-Prop $Config.images 'fallback_to_manual' $true))
            }
            'provider_fallback' {
                Set-Prop $Config.images 'auto_provider_fallback' (-not [bool](Get-Prop $Config.images 'auto_provider_fallback' $false))
            }
        }
    }
}

function Edit-StyleLock {
    param([object]$Config)
    Write-Host "`n  Ã¢â‚¬â€ Style Lock Ã¢â‚¬â€`n" -ForegroundColor Cyan
    Write-Host "  Current: $(Get-Prop $Config 'style_lock' '')`n" -ForegroundColor DarkGray

    $v = (Read-Host '  New style string (blank = keep)').Trim()
    if ($v) { Set-Prop $Config 'style_lock' $v }
}

function Edit-Paths {
    param([object]$Config)
    Write-Host "`n  Ã¢â‚¬â€ Paths Ã¢â‚¬â€  (blank = keep current)`n" -ForegroundColor Cyan

    $v = (Read-Host '  Output folder').Trim()
    if ($v) { Set-Prop $Config.paths 'output_folder' $v }

    $v = (Read-Host '  Python executable').Trim()
    if ($v) { Set-Prop $Config.paths 'python_exe' $v }
}

function Edit-AudioSettings {
    param([object]$Config)
    Write-Host "`n  Ã¢â‚¬â€ Audio Processing Ã¢â‚¬â€  (blank = keep current)`n" -ForegroundColor Cyan

    $v = (Read-Host '  Silence threshold dBFS (e.g. -40)').Trim()
    if ($v -match '^-?\d+$') { Set-Prop $Config.audio 'silence_thresh_dbfs' ([int]$v) }

    $v = (Read-Host '  Min silence length ms (e.g. 400)').Trim()
    if ($v -match '^\d+$') { Set-Prop $Config.audio 'min_silence_len_ms' ([int]$v) }

    $v = (Read-Host '  Keep silence padding ms (e.g. 100)').Trim()
    if ($v -match '^\d+$') { Set-Prop $Config.audio 'keep_silence_ms' ([int]$v) }
}

function Edit-VideoSettings {
    param([object]$Config)
    Write-Host "`n  Ã¢â‚¬â€ Rendering Ã¢â‚¬â€  (blank = keep current)`n" -ForegroundColor Cyan

    $v = (Read-Host '  FPS (e.g. 24, 30, 60)').Trim()
    if ($v -match '^\d+$') { Set-Prop $Config.video 'fps' ([int]$v) }

    $v = (Read-Host '  Codec (e.g. libx264, libx265)').Trim()
    if ($v) { Set-Prop $Config.video 'codec' $v }

    $v = (Read-Host '  Threads (e.g. 4)').Trim()
    if ($v -match '^\d+$') { Set-Prop $Config.video 'threads' ([int]$v) }
}

function Edit-Learning {
    param([object]$Config)
    Write-Host "`n  Ã¢â‚¬â€ Learning System Ã¢â‚¬â€`n" -ForegroundColor Cyan
    Write-Host '  When enabled, the AI analyzes your script edits and updates its' -ForegroundColor DarkGray
    Write-Host '  context files to improve future generations automatically.' -ForegroundColor DarkGray
    Write-Host ''

    $v = (Read-Host '  Enable learning? [true/false]').Trim().ToLower()
    if ($v -match '^(true|false)$') { Set-Prop $Config.learning 'enabled' ([bool]::Parse($v)) }
}

function Edit-Notifications {
    param([object]$Config)
    Write-Host "`n  Ã¢â‚¬â€ Notifications Ã¢â‚¬â€  (blank = keep current)`n" -ForegroundColor Cyan
    Write-Host '  Toggle each Windows toast notification on/off:' -ForegroundColor DarkGray
    Write-Host ''

    $Config.notifications.PSObject.Properties | ForEach-Object {
        $cur = if ($_.Value) { 'ON' } else { 'off' }
        $v   = (Read-Host "  $($_.Name) [currently: $cur] (true/false)").Trim().ToLower()
        if ($v -match '^(true|false)$') { Set-Prop $Config.notifications $_.Name ([bool]::Parse($v)) }
    }
}

function Edit-RuntimeSettings {
    param([object]$Config)
    while ($true) {
        $items = @(
            New-MenuItem -Key 'admin' -Label 'Run as admin on launch' -Value (Get-Prop $Config.runtime 'run_as_admin' $false)
            New-MenuItem -Key 'startup_checks' -Label 'Startup checks' -Value (Get-Prop $Config.runtime 'startup_checks' $true) -Hint 'keys and unfinished videos'
            New-MenuItem -Key 'theme' -Label 'Theme preset' -Value (Get-Prop $Config.runtime 'theme' 'soft_dark')
        )
        $selected = Invoke-NumberedMenu -Title 'Runtime' -Subtitle 'Launch and display preferences.' -Items $items -Config $Config
        if (-not $selected) { return }

        switch ($selected.Key) {
            'admin' {
                Set-Prop $Config.runtime 'run_as_admin' (-not [bool](Get-Prop $Config.runtime 'run_as_admin' $false))
            }
            'startup_checks' {
                Set-Prop $Config.runtime 'startup_checks' (-not [bool](Get-Prop $Config.runtime 'startup_checks' $true))
            }
            'theme' {
                $v = Select-Choice -Title 'Theme Preset' -CurrentValue (Get-Prop $Config.runtime 'theme' 'soft_dark') -Choices @(
                    [PSCustomObject]@{ Label='Soft dark'; Value='soft_dark' },
                    [PSCustomObject]@{ Label='Dark'; Value='dark' },
                    [PSCustomObject]@{ Label='Light'; Value='light' },
                    [PSCustomObject]@{ Label='High contrast'; Value='high_contrast' },
                    [PSCustomObject]@{ Label='Auto detect'; Value='auto' }
                )
                Set-Prop $Config.runtime 'theme' $v
            }
        }
    }
}

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# ENTRY
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

function Invoke-SettingsMenu {
    param(
        [object]$Config,
        [string]$ConfigPath,
        [switch]$FirstRun
    )

    # Bootstrap a default config object for first-run
    if ($FirstRun -or $null -eq $Config) {
        if (Get-Command Get-ConfigDefaults -ErrorAction SilentlyContinue) {
            $Config = Get-ConfigDefaults | ConvertTo-Json -Depth 6 | ConvertFrom-Json
        }
    }

    $modelWasMissing = Test-ModelMissingBeforeShape -Config $Config

    # Guarantee all nested properties exist before any access
    Assert-ConfigShape -Config $Config

    $dirty   = $false   # track unsaved changes
    if ($modelWasMissing -or (Initialize-MissingModels -Config $Config)) {
        if (-not $modelWasMissing) {
            $dirty = $true
        } else {
            Set-Prop $Config.ai.openai 'model' (Select-ModelFromList -Backend openai -CurrentModel (Get-Prop $Config.ai.openai 'model' 'o4-mini') -Config $Config)
            Set-Prop $Config.ai.gemini 'model' (Select-ModelFromList -Backend gemini -CurrentModel (Get-Prop $Config.ai.gemini 'model' 'gemini-2.5-flash') -Config $Config)
            $dirty = $true
        }
    }
    $running = $true

    while ($running) {
        $mainBackend = Get-Prop $Config.ai 'primary' 'openai'
        $mainModel = Get-Prop $Config.ai.$mainBackend 'model' ''
        $items = @(
            New-MenuItem -Key 'api'     -Label 'API keys'       -Value "OA:$(Mask-Key (Get-Prop $Config.api_keys 'openai')) P:$(Mask-Key (Get-Prop $Config.api_keys 'pollinations')) HF:$(Mask-Key (Get-Prop $Config.api_keys 'huggingface'))"
            New-MenuItem -Key 'ai'      -Label 'Main AI'        -Value "Primary $mainBackend  model $mainModel"
            New-MenuItem -Key 'voice'   -Label 'Voice / Audio'  -Value "$(Get-Prop $Config.voice 'model_id' 'eleven_flash_v2_5')  cleanup $(Get-Prop $Config.audio 'silence_thresh_dbfs') dBFS"
            New-MenuItem -Key 'images'  -Label 'Images/AI'      -Value "$(Get-Prop $Config.images 'mode' 'auto_review')  $(Get-Prop $Config.images 'provider' 'openai')  $(Get-CompositeLayoutLabel (Get-Prop $Config.images 'composite_layout' '1x1'))"
            New-MenuItem -Key 'style'   -Label 'Style lock'     -Value 'visual prompt style'
            New-MenuItem -Key 'paths'   -Label 'Paths'          -Value (Get-Prop $Config.paths 'output_folder')
            New-MenuItem -Key 'video'   -Label 'Rendering'      -Value "$(Get-Prop $Config.video 'fps') fps  $(Get-Prop $Config.video 'codec')"
            New-MenuItem -Key 'learn'   -Label 'Learning'       -Value $(if (Get-Prop $Config.learning 'enabled' $true) { 'enabled' } else { 'disabled' })
            New-MenuItem -Key 'notify'  -Label 'Notifications'  -Value 'toast toggles'
            New-MenuItem -Key 'runtime' -Label 'Runtime'        -Value "admin $(Get-Prop $Config.runtime 'run_as_admin' $false)  checks $(Get-Prop $Config.runtime 'startup_checks' $true)  theme $(Get-Prop $Config.runtime 'theme' 'soft_dark')"
            New-MenuItem -Key 'models'  -Label 'Check/select models' -Value 'live provider list'
        )
        $dirtyText = if ($dirty) { 'Unsaved changes. ' } else { '' }
        $selected = Invoke-NumberedMenu -Title 'Settings' -Subtitle "${dirtyText}Choose a section. S saves, B goes back." -Items $items -AllowSave -AllowQuit -Config $Config
        $choice = if ($selected) { $selected.Key } else { '__quit' }

        switch ($choice) {
            'api'    { Edit-ApiKeys        -Config $Config; $dirty = $true }
            'ai'     { Edit-AIBackend      -Config $Config; $dirty = $true }
            'voice'  { Edit-VoiceSettings  -Config $Config; $dirty = $true }
            'images' { Edit-ImageSettings  -Config $Config; $dirty = $true }
            'style'  { Edit-StyleLock      -Config $Config; $dirty = $true }
            'paths'  { Edit-Paths          -Config $Config; $dirty = $true }
            'video'  { Edit-VideoSettings  -Config $Config; $dirty = $true }
            'learn'  { Edit-Learning       -Config $Config; $dirty = $true }
            'notify' { Edit-Notifications  -Config $Config; $dirty = $true }
            'runtime'{ Edit-RuntimeSettings -Config $Config; $dirty = $true }
            'models' { Edit-Models         -Config $Config; $dirty = $true }
            '__save' {
                try {
                    $Config | ConvertTo-Json -Depth 6 | Set-Content $ConfigPath -Encoding UTF8
                    $dirty   = $false
                    $running = $false
                    Write-Host "`n  [OK] Saved to $ConfigPath" -ForegroundColor Green
                    Start-Sleep 1
                } catch {
                    Write-Host "`n  [ERROR] Save failed: $_" -ForegroundColor Red
                    Read-Host '  Press Enter to continue'
                }
            }
            '__quit' {
                if ($dirty) {
                    $confirm = (Read-Host '  Unsaved changes. Discard? [Y/N]').Trim().ToUpper()
                    if ($confirm -eq 'Y') { $running = $false }
                } else {
                    $running = $false
                }
            }
        }
    }
}

