function Get-FunctionTemplateV5 {
  <#
      .SYNOPSIS
  
      .DESCRIPTION
  
      .PARAMETER ComputerName
  
      .EXAMPLE
  
      .INPUTS
    
      .OUTPUTS
  
  #>
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromPipeline=$True,
        Mandatory=$True,
    ValueFromPipelineByPropertyName=$True)]
    [string[]]
    $ComputerName
  )

  Begin{
    Write-Information "Starting $($MyInvocation.MyCommand) " -Tags Process
    Write-Information "Execution Metadata:" -Tags Meta
    Write-Information "User = $($env:userdomain)\$($env:USERNAME)" -Tags Meta
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $IsAdmin = [System.Security.Principal.WindowsPrincipal]::new($id).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Information "Is Admin = $IsAdmin" -Tags Meta
    Write-Information "Computername = $env:COMPUTERNAME" -Tags Meta
    Write-Information "Host = $($host.Name)" -Tags Meta
    Write-Information "PSVersion = $($PSVersionTable.PSVersion)" -Tags Meta
    Write-Information "Runtime = $(Get-Date)" -Tags Meta
    Write-Verbose "[$((get-date).TimeOfDay.ToString()) BEGIN   ] Starting: $($MyInvocation.Mycommand)"
  }

  Process{
    ForEach ($computer in $ComputerName){
      Write-Verbose "[$((get-date).TimeOfDay.ToString()) PROCESS ] Processing {$computer}"
    }

  }

  End {
    Write-Verbose "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Information "Ending $($MyInvocation.MyCommand) " -Tags Process
  }

}