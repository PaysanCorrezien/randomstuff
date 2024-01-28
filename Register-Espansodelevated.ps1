<#
.SYNOPSIS
Registers a new elevated scheduled task for Espansod.

.DESCRIPTION
This function creates and registers a new scheduled task for the Espansod application with specified parameters like task name, user domain, user name, and triggers.

.PARAMETER AppName
The name of the application to be run by the scheduled task. Default is 'espansod.exe'.

.PARAMETER TaskName
The name of the scheduled task.

.PARAMETER UserDomain
The domain of the user under which the task should run. Default is the domain of the current user.

.PARAMETER UserName
The name of the user under which the task should run. Default is the username of the current user.

.EXAMPLE
Register-EspansodElevated -TaskName "Espanso SVKO Task Elevated"

.NOTES
Version:        1.0
#>

function Register-EspansodElevated
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [string]$AppName = 'espansod.exe',

    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [string]$UserDomain = "$env:USERDOMAIN",

    [Parameter(Mandatory = $false)]
    [string]$UserName = "$env:USERNAME"
  )

  try
  {
    # Define the application path
    $AppPath = "$env:USERPROFILE\AppData\Local\Programs\Espanso\$AppName"

    # Verify if the application exists
    if (-not (Test-Path -Path $AppPath))
    {
      throw "The application path '$AppPath' does not exist."
    }

    # Task action
    $Action = New-ScheduledTaskAction -Execute "$AppPath" -Argument "launcher"

    # Task trigger (at logon)
    $Trigger = New-ScheduledTaskTrigger -AtLogon

    # Task principal (run with highest privileges)
    $Principal = New-ScheduledTaskPrincipal -UserID "$UserDomain\$UserName" -LogonType ServiceAccount -RunLevel Highest

    # Task settings (allow running on battery)
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd

    # Create the task
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal

    # Register the task
    Register-ScheduledTask -TaskName "$TaskName" -InputObject $Task -Force

    Write-Output "The task '$TaskName' has been registered successfully."
  } catch
  {
    Write-Error "An error occurred: $_"
  }
}
