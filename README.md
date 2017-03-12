[![Build status](https://ci.appveyor.com/api/projects/status/9fwaocaijx7tkos3?svg=true)](https://ci.appveyor.com/project/mczerniawski/arcadmintools)

ArcAdminTools
=============

PowerShell module with Admin Tools 

This is a PowerShell module with a variety of functions usefull in a day-to-day tasks or a regular SysAdmin or HelpDesk Support technician job.

Pull requests and other contributions are more than welcome!

## Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the ArcAdminTools folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module ArcAdminTools 

# Import the module.
    Import-Module ArcAdminTools #Alternatively, Import-Module \\Path\To\ArcAdminTools 

# Get commands in the module
    Get-Command -Module ArcAdminTools 

# Get help
    Get-Help about_ArcAdminTools 
```