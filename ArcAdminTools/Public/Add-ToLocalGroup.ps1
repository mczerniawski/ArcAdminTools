function Add-ToLocalGroup {
  #requires -Version 3.0 
  <#
      .SYNOPSIS
      Adds a user or a group to local group on a remote computer. 

      .DESCRIPTION
      Will add user or groupo to a local group on a remote computer. LocalGroup parameter specifies which group it will be, i.e. Administrators, Remote Desktop Users, or others.

      .PARAMETER ComputerName
      Destination computer name where to add user or group (Identity parameter). Will accept mupltiple values.

      .PARAMETER LocalGroup
      Local group on destination computer where the Identity should be added to. 

      .PARAMETER DomainName
      Domain name - required for user/group string creation. Can be a workgroup or local computer name instead of domain name. Defaults to current $env:userdomain - can be domain or workgroup, depending on current environment.

      .PARAMETER Type
      Type of identity to add - user or group.

      .PARAMETER Identity
      Identity of a user/group to add. Provide samaccountname

      .EXAMPLE
      This will add 'someuser' to 'somecomputer' as local administrator for current default user domain
      Add-ToLocalGroup -ComputerName 'somecomputer' -Group Administrators -Type User -Identity 'someuser'
  #>

  [CmdletBinding()]             
  [OutputType([void])]
  param(                        
    [Parameter(Mandatory=$false,HelpMessage='Destination Computer name')]             
    [string[]]
    $ComputerName='localhost',

    [Parameter(Mandatory=$true,HelpMessage='Local Group to add Identity to')]
    [string]
    $LocalGroup,

    [Parameter(Mandatory=$false,HelpMessage='Domain or workgroup name')]
    [string]
    $DomainName="$env:USERDOMAIN",  
    
    [Parameter(Mandatory=$true,HelpMessage='Type of Identity to add')]
    [ValidateSet('User', 'Group')]
    [string]
    $Type,
        
    [Parameter(Mandatory=$true,HelpMessage='Identity to add')]
    [string]
    $Identity
  )
  Begin {
    Write-Verbose -Message "Starting $($MyInvocation.MyCommand) " 
    Write-Verbose -Message 'Execution Metadata:'
    Write-Verbose -Message "User = $($env:userdomain)\$($env:USERNAME)" 
    Write-Verbose -Message "Computername = $env:COMPUTERNAME" 
    Write-Verbose -Message "Host = $($host.Name)"
    Write-Verbose -Message "PSVersion = $($PSVersionTable.PSVersion)"
    Write-Verbose -Message "Runtime = $(Get-Date)" 

    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) BEGIN   ] Starting: $($MyInvocation.Mycommand)"
    
  }

  Process{
    foreach ($computer in $ComputerName) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Processing computer {$computer}"
        
      try {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Trying to use ADSI connector to access to computer {$computer} local group {$LocalGroup}"
        $Group = [ADSI]"WinNT://$computer/$LocalGroup,group"
        
        if ($Type -eq 'Group') { 
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Trying to use ADSI connector to add group {$Identity} to local group {$LocalGroup} on computer {$computer}"
          $addgroup = [ADSI]"WinNT://$DomainName/$Identity,group"
          $Group.Add($addgroup.Path)
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Successfuly added group {$Identity} to local group {$LocalGroup} on computer {$computer}"
          $status = 'Success'
        } 
        elseif ($Type -eq 'User') {
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Trying to use ADSI connector to add user {$Identity} to local group {$LocalGroup} on computer {$computer}"
          $addUser = [ADSI]"WinNT://$DomainName/$Identity,user"
          $Group.Add($addUser.Path)
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ]  Successfuly added user {$Identity} to local group {$LocalGroup} on computer {$computer}"
          $status = 'Success'
        }
        
      }
      catch {
        $scriptName = split-path ($_.InvocationInfo.ScriptName) -Leaf
        $scriptLine = $_.InvocationInfo.ScriptLineNumber
        $errorMessage = $_.Exception.InnerException.Message
        Write-Error -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] $scriptName/$scriptLine : $errorMessage "
        
        $status = 'Failure'
      }
      [PSCustomObject]@{
        Computername = $computer
        LocalGroup = $LocalGroup
        Identity = $Identity
        status = $status
          
      }
    }
  }

  End {
    Write-Verbose "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Verbose "Ending $($MyInvocation.MyCommand) " 
  }


}
