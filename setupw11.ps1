# TODO: Setlocaladmin first to do the rest and install apps on user profiles, need to use new right to install choco / wsl 
# reboot after wsl install and autolaunch rest of setup

# Initialize the userconfig directory if it doesn't exist
if (-not (Test-Path "C:\userconfig"))
{
  New-Item -Path "C:\userconfig" -ItemType Directory
}

# Define variables
$dllUrl = 'https://github.com/PaysanCorrezien/randomstuff/raw/main/VirtualDesktopAccessor.dll'
$dllDest = 'C:\userconfig\VirtualDesktopAccessor.dll'
# $ahkScriptPath = "C:\userconfig\dylan.ahk"
# $ahkScriptUrl = 'https://github.com/PaysanCorrezien/randomstuff/raw/main/w11virtualdesktop.ahk'

#TODO: teams app removal
$registryKeys = @(
  @{
    Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Value = @{
      'TaskbarAl' = 0 # startmenu left side
      'TaskbarMn' = 0 # Chat ICON disableq
      'TaskbarGlomLevel' = 2
      'ShowTaskViewButton' = 0 # Taskview disable

      'NavPaneShowAllFolders' = 1
      'Hidden' = 1
      'HideFileExt' = 0
      'HideIcons' = 1 # hide desktop icon
    }
  },
  @{ # old explorer context menu
    Key = 'HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    Value = @{
      '(Default)' = ''
    }
  },
  @{
    Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer'
    Value = @{
      'TaskbarGlomming' = 0
    }
  },
  @{
    Key = 'HKEY_CLASSES_ROOT\*\shell\copyfullpath'
    Value = @{
      '(Default)' = 'Copy Full Path'
    }
  },
  @{
    Key = 'HKEY_CLASSES_ROOT\*\shell\copyfullpath\command'
    Value = @{
      '(Default)' = 'cmd /c echo %1 | clip'
    }
  },
  @{
    Key = 'HKEY_CLASSES_ROOT\*\shell\copyfilename'
    Value = @{
      '(Default)' = 'Copy Filename'
    }
  },
  @{
    Key = 'HKEY_CLASSES_ROOT\*\shell\copyfilename\command'
    Value = @{
      '(Default)' = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File ''C:\userconfig\copyfile.ps1'' \"\"%1\"\"'
    }
  },
  @{
    Key = 'HKEY_CURRENT_USER\Keyboard Layout\Toggle'
    Value = @{
      'Language Hotkey' = 1
      'Layout Hotkey' = 1
    }
  }
)



# Function to log information
function LogInfo
{
  param (
    [string]$Message
  )
  Write-Host "Info: $Message" -ForegroundColor Green
}

# Function to log errors
function LogError
{
  param (
    [string]$Message
  )
  Write-Host "Error: $Message" -ForegroundColor Red
}

function Remove-DefaultTeams {
    try {
        # Attempt to find and remove Microsoft Teams
        Get-AppxPackage *MicrosoftTeams* | Remove-AppxPackage
        LogInfo "Microsoft Teams has been successfully removed." -ForegroundColor Green
    } catch {
        # Catch and log any errors
        LogError "Error: $_" -ForegroundColor Red
    }
}


function Install-WingetApp {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$appNames
    )

    foreach ($appName in $appNames) {
        # Search for the application
        $searchResults = winget search $appName | Out-String -Stream | Select-Object -Skip 2

        # Count the number of found packages
        $packageCount = ($searchResults | Measure-Object).Count

        # If multiple packages are found, prompt the user to select one using Out-GridView
        if ($packageCount -gt 1) {
            $selectedPackage = $searchResults | Out-GridView -Title "Select a package to install for $appName" -OutputMode Single
            if ($selectedPackage) {
                $packageId = ($selectedPackage -split '\s+')[0]
                winget install $packageId
            }
        }
        # If only one package is found, install it directly
        elseif ($packageCount -eq 1) {
            $packageId = ($searchResults -split '\s+')[0]
            winget install $packageId
        }
        else {
            Write-Host "No packages found for $appName."
        }
    }
}

function RestartAndContinue
{
  param (
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
  )

  $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
  $RegName = "ContinueScript"

  # Check if path exists
  if (-not (Test-Path $ScriptPath))
  {
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

function Set-ProgramInstaller
{
  # Check if Chocolatey is installed
  if (!(Test-Path -Path "$env:ProgramData\Chocolatey\choco.exe"))
  {
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

function CreateMultiplesRegistryKey($registryKeys)
{
  foreach ($key in $registryKeys)
  {
    $keyName = $key.Key
    $property = $key.Value

    foreach ($name in $property.Keys)
    {
      $value = $property[$name]
            
      if ($name -eq '(Default)')
      {
        $command = "reg add `"$keyName`" /ve /d `"$value`" /f"
      } else
      {
        if ($value -is [int])
        {
          $command = "reg add `"$keyName`" /v `"$name`" /t REG_DWORD /d $value /f"
        } else
        {
          $command = "reg add `"$keyName`" /v `"$name`" /d `"$value`" /f"
        }
      }
            
      Write-Host "Executing: $command" # This will display the command
      Invoke-Expression $command
    }
  }
}


function Set-LocalAdmin
{
  # Check if the user wants to set a local admin
  $response = $null
  do
  {
    $response = Read-Host -Prompt "Do you want to set a local admin? (yes/no)"
  } while ($response -notin @('yes', 'no'))

  if ($response -eq 'no')
  {
    Write-Host "Skipping local admin setup."
    return
  }

  # Prompt for username
  $username = Read-Host -Prompt "Please enter domain\username to make as a local admin"

  # Use net localgroup to add the user to the local administrators group
  $output = net localgroup Administrateurs $username /add 2>&1

  if ($LASTEXITCODE -ne 0)
  {
    Write-Error "Failed to add user. Error: $output"
  } else
  {
    Write-Host "User added successfully."
  }
}



function Download-And-Register-Dll($dllUrl, $dllDest)
{
  # Download DLL from GitHub
  Invoke-WebRequest -Uri $dllUrl -OutFile $dllDest

  # Register DLL
  Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s $dllDest" -NoNewWindow
}

function Install-Keyboard
{
  param (
    [string]$repo = "https://github.com/PaysanCorrezien/randomstuff.git"
  )

  # Ensure Git is installed
  if (-not (Get-Command git -ErrorAction SilentlyContinue))
  {
    Write-Error "Git is not installed. Please install Git first."
    return
  }

  # Ensure the destination directory exists
  $destination = "C:\userconfig"
  if (-not (Test-Path $destination))
  {
    New-Item -ItemType Directory -Path $destination -Force
  }

  # Clone the repo
  git clone $repo "$destination\randomstuff"

  # Install the MSI
  $msiPath = "$destination\randomstuff\intl-alt\intl-alt_amd64.msi"
  if (Test-Path $msiPath)
  {
    Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn"
  } else
  {
    Write-Error "MSI file not found at $msiPath"
  }
}
Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"C:\userconfig\randomstuff\intl-alt\intl-alt_amd64.msi`" /qn"

function Install-PowershellModules
{
  param (
    [string[]]$ModuleNames
  )


  # Iterating over each module name
  foreach ($module in $ModuleNames)
  {
    try
    {
      # Try to install the module
      Install-Module -Name $module -Force -ErrorAction Stop
      LogInfo "Successfully installed module: $module"
    } catch
    {
      # Log any errors that occur
      LogError "Failed to install module: $module. Error: $_"
    }
  }
}

function Install-WingetApp {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$appNames
    )

    foreach ($appName in $appNames) {
        # Search for the application
        $searchResults = winget search $appName | Out-String -Stream | Select-Object -Skip 2

        # Count the number of found packages
        $packageCount = ($searchResults | Measure-Object).Count

        # If multiple packages are found, prompt the user to select one using Out-GridView
        if ($packageCount -gt 1) {
            $selectedPackage = $searchResults | Out-GridView -Title "Select a package to install for $appName" -OutputMode Single
            if ($selectedPackage) {
                $packageId = ($selectedPackage -split '\s+')[0]
                winget install $packageId
            }
        }
        # If only one package is found, install it directly
        elseif ($packageCount -eq 1) {
            $packageId = ($searchResults -split '\s+')[0]
            winget install $packageId
        }
        else {
            Write-Host "No packages found for $appName."
        }
    }
}

function Setup-AutoHotkey($ahkScriptPath, $ahkScriptUrl)
{
  # Download the AutoHotkey script if it doesn't exist
  if (!(Test-Path $ahkScriptPath))
  {
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
function Add-FolderPathToEnvPath
{
  param(
    [Parameter(Mandatory=$true)]
    [string]$folderPath
  )

  try
  {
    # Check if the folder path exists
    if (-Not (Test-Path -Path $folderPath))
    {
      throw "Folder path does not exist: $folderPath"
    }

    # Get the current PATH environment variable for the user
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")

    # Check if the folder path is already in the PATH
    if ($currentPath -split ';' -contains $folderPath)
    {
      Write-Host "Folder path already in PATH: $folderPath"
      return
    }

    # Add folder path to the PATH environment variable
    $newPath = $currentPath + ';' + $folderPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

    # Verify if the folder path was added
    $updatedPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($updatedPath -split ';' -contains $folderPath)
    {
      Write-Host "Folder path added to PATH successfully: $folderPath"
    } else
    {
      throw "Failed to add folder path to PATH"
    }
  } catch
  {
    Write-Error "An error occurred: $_"
  }
}
if (-not (Test-Path $env:USERPROFILE + "Documents\WindowsPowerShell\.secrets.ps1"))
{
  New-Item -Path $env:USERPROFILE + "Documents\WindowsPowerShell\.secrets.ps1" -ItemType File
  "OPENAI_API_KEY = 'sk-'" | Out-File $env:USERPROFILE + "Documents\WindowsPowerShell\.secrets.ps1"
  "GH_TOKEN = ''" | Out-File $env:USERPROFILE + "Documents\WindowsPowerShell\.secrets.ps1"
  Write-Host "Please fill the secrets file with token for openai and github"
}

# Call the function to set up program installers
Set-ProgramInstaller

$pathtoaddtoEnv = @(
"C:\Program Files\Git\usr\bin\",
$env:USERPROFILE + "\AppData\Sqllite\",
# Use the script build for that instead
"C:\Program Files\Yazi"
)
# Add the folder path to the PATH environment variable
foreach( $path in $pathtoaddtoEnv){
  Add-FolderPathToEnvPath -folderPath $path
}

# Define a list of programs to install
$programs = @(
    "powertoys", # Utilities
    "powershell-core", # Utilities
    "python4", # Programming Languages
    "7zip", # Utilities
    "teamviewer", # Remote Access
    # "autohotkey", # Utilities
    "dotnet4.5", # Programming Languages
    "mingw", # Development Tools for neovim
    "make", # Development Tools for neovim
    "temurin", # Java for neovim LSP Ltex
    "neovim", # Text Editors (Neovim specifics)
    "sql-server-management-studio", # Database Tools
    "putty", # Network Tools
    "wireshark", # Network Tools
    "keepassxc", # Security Tools
    "brave", # Web Browsers
    # "obsidian", # Productivity Tools
    "greenshot", # Utilities
    "keepassxc", # Security Tools
    "RegShot", # Utilities
    "ripgrep", # Development Tools
    "nextcloud-client", # Cloud Storage
    "procmon", # System Tools
    "fzf", # Development Tools Cli
    "zoxide", # Development Tools Cli
    "fd", # Development Tools Cli
    "bat", # Development Tools Cli
    "git", # Development Tools
    "gh" # Development Tools Github CLI
    "hyperfine", # Development Tools
    "github-desktop", # Development Tools
    "pandoc", # Productivity Tools
    "mremoteng", # Remote Access
    "fd", # Development Tools
    "nerd-fonts-firacode", # Fonts
    "forticlientvpn", # Security Tools
    "linphone", # Communication Tools
    "microsoft-teams" # Communication Tools
)

# Needed for teams PRO
Remove-DefaultTeams

# Call the function to install each program
foreach ($program in $programs)
{
 choco install $program -y --global
}

# Sqllite DLL
$dllUrl_SQL = 'https://github.com/PaysanCorrezien/randomstuff/deps/sqllite/sqlite3.dll'
$dllDest_SQL = $env:APPDATA+ "\sqlite-dll\sqlite3.dll"
Download-And-Register-Dll -dllUrl $dllUrl_SQL -dllDest $dllDest_SQL

# Refresh the current session's PATH to get access to git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Call the function with the list of registry keys
CreateMultiplesRegistryKey -registryKeys $registryKeys

# Download the DLL
Invoke-WebRequest -Uri $dllUrl -OutFile $dllDest

# Set a user as a local admin
Set-LocalAdmin -username $localAdminUsername

# Set up an AutoHotkey script to run at startup
# Setup-AutoHotkey -ahkScriptPath $ahkScriptPath -ahkScriptUrl $ahkScriptUrl

# Download layout keyboard
Install-Keyboard

$appsToInstall = @("Microsoft Visual studio code", "GlazeWM")
Install-WingetApp -appNames $appsToInstall

# Example usage
$modulesToInstall = @('PSFzf', 'PSReadLine', 'BurntToast')
Install-PowershellModules -ModuleNames $modulesToInstall

# Run the provided script from the URL
# Invoke-Expression (Invoke-RestMethod -Uri https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1)
