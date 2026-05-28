# AI Video Factory - Main Script
# Entry point for the AI video generation application

param(
    [string]$Action = "menu"
)

# Import modules
$ModulesPath = Join-Path $PSScriptRoot "modules"
if (Test-Path $ModulesPath) {
    Get-ChildItem -Path $ModulesPath -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}

# Main logic
switch ($Action) {
    "menu" {
        . (Join-Path $PSScriptRoot "settings_menu.ps1")
    }
    default {
        Write-Host "AI Video Factory - Main Application" -ForegroundColor Cyan
        Write-Host "Run with -Action 'menu' to open settings menu"
    }
}
