function Get-FunctionTemplate {
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
    Write-Verbose "Starting $($MyInvocation.MyCommand) " 
    Write-Verbose "Execution Metadata:"
    Write-Verbose "User = $($env:userdomain)\$($env:USERNAME)" 
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $IsAdmin = [System.Security.Principal.WindowsPrincipal]::new($id).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Verbose "Is Admin = $IsAdmin"
    Write-Verbose "Computername = $env:COMPUTERNAME" 
    Write-Verbose "Host = $($host.Name)" 
    Write-Verbose "PSVersion = $($PSVersionTable.PSVersion)" 
    Write-Verbose "Runtime = $(Get-Date)"
    Write-Verbose "[$((get-date).TimeOfDay.ToString()) BEGIN   ] Starting: $($MyInvocation.Mycommand)"
  }

  Process{
    ForEach ($computer in $ComputerName){
      Write-Verbose "[$((get-date).TimeOfDay.ToString()) PROCESS ] Processing computer {$computer}"
    }
  }

  End {
    Write-Verbose "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Verbose "Ending $($MyInvocation.MyCommand) " 
  }
}