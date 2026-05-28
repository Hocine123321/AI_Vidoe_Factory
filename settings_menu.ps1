# Settings Menu - Configuration and Options
# Provides user interface for configuring the AI video generator

function Show-SettingsMenu {
    param(
        [string]$Title = "AI Video Factory - Settings Menu"
    )
    
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Video Generation Settings" -ForegroundColor Yellow
    Write-Host "2. AI Model Configuration" -ForegroundColor Yellow
    Write-Host "3. Output Preferences" -ForegroundColor Yellow
    Write-Host "4. Python Environment" -ForegroundColor Yellow
    Write-Host "5. View Logs" -ForegroundColor Yellow
    Write-Host "6. Exit" -ForegroundColor Yellow
    Write-Host ""
}

function Invoke-SettingsMenu {
    do {
        Show-SettingsMenu
        [string]$selection = Read-Host "Please make a selection"
        
        switch ($selection) {
            '1' {
                Write-Host "Opening Video Generation Settings..." -ForegroundColor Green
            }
            '2' {
                Write-Host "Opening AI Model Configuration..." -ForegroundColor Green
            }
            '3' {
                Write-Host "Opening Output Preferences..." -ForegroundColor Green
            }
            '4' {
                Write-Host "Checking Python Environment..." -ForegroundColor Green
            }
            '5' {
                Write-Host "Loading logs..." -ForegroundColor Green
            }
            '6' {
                Write-Host "Exiting..." -ForegroundColor Cyan
                exit
            }
            default {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            }
        }
        
        if ($selection -ne '6') {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    } while ($true)
}

Invoke-SettingsMenu
