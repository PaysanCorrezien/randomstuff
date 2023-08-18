#$env:username
$username = $env:username

Write-Host "Enabling WSL and Virtual Machine Platform..."
Start-Process -Wait -NoNewWindow -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
Start-Process -Wait -NoNewWindow -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"

Write-Host "Setting WSL 2 as the default..."
wsl --set-default-version 2

Write-Host "Installing Debian..."
wsl --install -d Debian

# Get the directory of the currently executing script
$currentDir = $PSScriptRoot

# Construct the full path to wslsetup.ps1
$wslSetupScriptPath = Join-Path -Path $currentDir -ChildPath "debiansetup.ps1"

# Check if wslsetup.ps1 exists in the directory
if (Test-Path $wslSetupScriptPath) {
Write-Host "Create AT to execute rest of install"
# Define the date-time for one day from now
$endDate = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ss")

# Register the next script to run upon startup using Task Scheduler
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $wslSetupScriptPath"
$trigger = New-ScheduledTaskTrigger -AtLogon -RepetitionDuration ([TimeSpan]::FromDays(1)) -EndBoundary $endDate
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "AfterRebootScript" -User $env:USERNAME

} else {
    Write-Host "Error: wslsetup.ps1 not found in the current directory."
    exit 1
}

Write-Host "Rebooting the system to finalize changes..."
Restart-Computer -Wait
