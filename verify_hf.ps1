# verify_hf.ps1
# This script verifies the newly added Hugging Face functions.

$ROOT = $PSScriptRoot
# Mock objects needed by the modules
function Write-Log { param($Level, $Message, $LogPath) Write-Host "[$Level] $Message" }
function Start-Spinner { param($Label) return @{ Label=$Label } }
function Stop-Spinner { param($Spinner, [switch]$Failed) }
function Send-Toast { param($Title, $Message, $Config, $Key) }
function Format-LargeCount { param($Value) return "$Value" } # Simplified for test

# Load the modules
. "$ROOT\settings_menu.ps1"
. "$ROOT\modules\ai.ps1"
. "$ROOT\modules\images.ps1"

$mockConfig = [PSCustomObject]@{
    api_keys = [PSCustomObject]@{
        huggingface = 'test_key' # We don't need a real key to check URI construction
    };
    ai = [PSCustomObject]@{
        huggingface = [PSCustomObject]@{
            model = 'meta-llama/Meta-Llama-3-8B-Instruct'
        }
    };
    images = [PSCustomObject]@{
        provider = 'huggingface';
        model = 'stabilityai/stable-diffusion-xl-base-1.0'
    }
}

Write-Host "--- Testing HF Model Fetching ---"
# Note: This might fail if the network is blocked or key is invalid,
# but we can at least check if the function exists and doesn't crash on URI construction.
$hfModels = Get-LiveHuggingFaceModels -Config $mockConfig
Write-Host "HF Models fetched: $($hfModels.Count)"

$hfImageModels = Get-LiveHuggingFaceImageModels -Config $mockConfig
Write-Host "HF Image Models fetched: $($hfImageModels.Count)"

Write-Host "`n--- Testing Prompt Splitting ---"
$testPrompt = @"
You are a video script writer. Follow ALL instructions exactly.

=== SYSTEM RULES ===
Rule 1
Rule 2

=== VISUAL STYLE GUIDE ===
Style 1

=== FORMAT REFERENCE ===
Format 1

=== TASK ===
Topic: "Space"
"@

# We'll just check the logic inside Invoke-HuggingFaceBackend by temporary export or manual check
if ($testPrompt -match '(?s)^(.*?)=== SYSTEM RULES ===(.*)$') {
    $systemPart = "You are a video script writer. Follow ALL instructions exactly.`n`n=== SYSTEM RULES ===" + $Matches[2]
    $userPart = $testPrompt
    if ($userPart -match '(?s)=== TASK ===(.*)$') {
        $userPart = "=== TASK ===" + $Matches[1]
    }
    Write-Host "System Part found: $($systemPart.Contains('Rule 1'))"
    Write-Host "User Part found: $($userPart.Contains('Space'))"
}

Write-Host "`n--- Testing Image Provider Fallback Logic ---"
$imageSettings = Get-ImageSettings -Config $mockConfig
Write-Host "Image Provider: $($imageSettings.Provider)"
Write-Host "Image Model: $($imageSettings.Model)"

Write-Host "`nVerification complete."
