# TODO: Setlocaladmin first to do the rest and install apps on user profiles, need to use new right to install choco / wsl 
# reboot after wsl install and autolaunch rest of setup

# Initialize the userconfig directory if it doesn't exist
if (-not (Test-Path "C:\userconfig")) {
    New-Item -Path "C:\userconfig" -ItemType Directory
}

# Define variables
$dllUrl = 'https://github.com/PaysanCorrezien/randomstuff/raw/main/VirtualDesktopAccessor.dll'
$dllDest = 'C:\userconfig\VirtualDesktopAccessor.dll'
$ahkScriptPath = "C:\userconfig\dylan.ahk"
$ahkScriptUrl = 'https://github.com/PaysanCorrezien/randomstuff/raw/main/w11virtualdesktop.ahk'

$registryKeys = @(
    @{
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Value = @{
            'TaskbarAl' = 1
            'TaskbarGlomLevel' = 2
            'NavPaneShowAllFolders' = 1
            'Hidden' = 1
            'HideFileExt' = 0
        }
    },
    @{
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        Value = @{
            'TaskbarGlomming' = 0
        }
    },
    @{
        Key = 'HKCR:\*\shell\copyfullpath'
        Value = @{
            '(Default)' = 'Copy Full Path'
        }
    },
    @{
        Key = 'HKCR:\*\shell\copyfullpath\command'
        Value = @{
            '(Default)' = 'cmd /c echo %1 | clip'
        }
    },
    @{
        Key = 'HKCR:\*\shell\copyfilename'
        Value = @{
            '(Default)' = 'Copy Filename'
        }
    },
    @{
        Key = 'HKCR:\*\shell\copyfilename\command'
        Value = @{
            '(Default)' = 'cmd.exe /c "for %%A in ("%1") do @echo %%~nxA | clip"'
        }
    },
    @{
        Key = 'HKCU:\Keyboard Layout\Toggle'
        Value = @{
            'Language Hotkey' = 1
            'Layout Hotkey' = 1
        }
    }
)


function RestartAndContinue {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )

    $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    $RegName = "ContinueScript"

    # Check if path exists
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "Script path not found!"
        return
    }

    # Set the registry key for the script to run once on next login
    Set-ItemProperty -Path $RegPath -Name $RegName -Value $ScriptPath

    # Reboot the machine
    Restart-Computer -Force
}
# usage 
# RestartAndContinue -ScriptPath "C:\path\to\your\script.ps1"

function Set-ProgramInstaller {
    # Check if Chocolatey is installed
    if (!(Test-Path -Path "$env:ProgramData\Chocolatey\choco.exe")) {
        # Allow script execution for this process
        Set-ExecutionPolicy Bypass -Scope Process -Force
        # Set the Chocolatey installation location
        [Environment]::SetEnvironmentVariable('ChocolateyInstall', 'C:\chocolatey', 'Machine')
        # Install Chocolatey
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

        # Define the desired installation location
        $installDir = "C:\chocolatey"
        
        # Configure Chocolatey to use the defined directory
        choco config set cacheLocation $installDir
        choco config set chocoInstallLocation $installDir
    }
}

function Install-Program {
    param (
        [Parameter(Mandatory=$true)]
        [string]$name
    )
    # Use Chocolatey to install the provided software package globally
    choco install $name -y --global
}

function CreateMultiplesRegistryKey($registryKeys) {
    foreach ($key in $registryKeys) {
        $keyName = $key.Key
        $property = $key.Value
        $propertyType = $property.GetType().Name

        if (!(Test-Path $keyName)) {
            New-Item -Path $keyName -Force | Out-Null
        }

        foreach ($name in $property.Keys) {
            Set-ItemProperty -Path $keyName -Name $name -Value $property.$name -Type $propertyType -Force
        }
    }
}

function Set-LocalAdmin {
    # Check if the user wants to set a local admin
    $response = $null
    do {
        $response = Read-Host -Prompt "Do you want to set a local admin? (yes/no)"
    } while ($response -notin @('yes', 'no'))

    if ($response -eq 'no') {
        Write-Host "Skipping local admin setup."
        return
    }

    # Prompt for username
    $username = Read-Host -Prompt "Please enter domain\username to make as a local admin"

    # Use net localgroup to add the user to the local administrators group
    $output = net localgroup Administrateurs $username /add 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to add user. Error: $output"
    } else {
        Write-Host "User added successfully."
    }
}



function Download-And-Register-Dll($dllUrl, $dllDest) {
    # Download DLL from GitHub
    Invoke-WebRequest -Uri $dllUrl -OutFile $dllDest

    # Register DLL
    Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s $dllDest" -NoNewWindow
}

function Install-Keyboard {
    param (
        [string]$repo = "https://github.com/PaysanCorrezien/randomstuff.git"
    )

    # Ensure Git is installed
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is not installed. Please install Git first."
        return
    }

    # Ensure the destination directory exists
    $destination = "C:\userconfig"
    if (-not (Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force
    }

    # Clone the repo
    git clone $repo "$destination\randomstuff"

    # Install the MSI
    $msiPath = "$destination\randomstuff\intl-alt\intl-alt_amd64.msi"
    if (Test-Path $msiPath) {
        Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn"
    } else {
        Write-Error "MSI file not found at $msiPath"
    }
}
Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"C:\userconfig\randomstuff\intl-alt\intl-alt_amd64.msi`" /qn"


function Setup-AutoHotkey($ahkScriptPath, $ahkScriptUrl) {
    # Download the AutoHotkey script if it doesn't exist
    if (!(Test-Path $ahkScriptPath)) {
        Invoke-WebRequest -Uri $ahkScriptUrl -OutFile $ahkScriptPath
    }

    # Define the path to the Startup folder
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    # Create a shortcut to the script in the Startup folder
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$startupPath\AutoHotkey.lnk")
    $Shortcut.TargetPath = "C:\Program Files\AutoHotkey\AutoHotkey.exe"
    $Shortcut.Arguments = "`"$ahkScriptPath`""
    $Shortcut.Save()
}

# Call the function to set up program installers
Set-ProgramInstaller


# Define a list of programs to install
$programs = @("powertoys", "powershell-core", "python3", "7zip", 
              "teamviewer", "autohotkey", "dotnet3.5", 
              "sql-server-management-studio", "putty", "wireshark", "keepassxc", "brave", 
              "obsidian", "greenshot", "keepassxc", "RegShot", "TreeSizeFree",
              "procmon", "winlogbeat", "LogParser", "git", "github-desktop","pandoc","mremoteng","quicklook" )

# Call the function to install each program
foreach ($program in $programs) {
    Install-Program -name $program
}

# Refresh the current session's PATH to get access to git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Call the function with the list of registry keys
# CreateMultiplesRegistryKey -registryKeys $registryKeys

# Download the DLL
Invoke-WebRequest -Uri $dllUrl -OutFile $dllDest

# Set a user as a local admin
Set-LocalAdmin -username $localAdminUsername

# Set up an AutoHotkey script to run at startup
Setup-AutoHotkey -ahkScriptPath $ahkScriptPath -ahkScriptUrl $ahkScriptUrl

# Download layout keyboard
Install-Keyboard

# Run the provided script from the URL
# Invoke-Expression (Invoke-RestMethod -Uri https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1)
