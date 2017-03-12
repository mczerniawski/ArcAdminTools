function Add-ToLocalGroup {
  #requires -Version 3.0 
  <#
      .SYNOPSIS
      Adds a user or a group to local group on a remote computer. 

      .DESCRIPTION
      Will add user or groupo to a local group on a remote computer. LocalGroup parameter specifies which group it will be, i.e. Administrators, Remote Desktop Users, or others. Output is a custom object with  computername, localgroup, identity and status of action

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
      Add-ToLocalGroup -ComputerName 'somecomputer' -Group Administrators -Type User -Identity 'someuser'
      This will add 'someuser' to 'somecomputer' as local administrator for current default user domain
      

      .EXAMPLE
      Add-ToLocalGroup -LocalGroup 'administrators' -Type User -Identity test1 -ComputerName 'somecomputer1','somecomputer2' -Verbose -DomainName 'somedomain'
      This will add somedomain\test1 user to group Administrators on both somecomputer1 and somecomputer2 providing Verbose output:
        VERBOSE: Starting Add-ToLocalGroup 
        VERBOSE: Execution Metadata:
        VERBOSE: User = SOMEDOMAIN\test1
        VERBOSE: Computername = MyMachine
        VERBOSE: Host = Windows PowerShell ISE Host
        VERBOSE: PSVersion = 5.1.14393.693
        VERBOSE: Runtime = 03/12/2017 15:22:26
        VERBOSE: [15:22:26.4476294 BEGIN   ] Starting: Add-ToLocalGroup
        VERBOSE: [15:22:26.4476294 PROCESS ] Processing computer {somecomputer1}
        VERBOSE: [15:22:26.4481291 PROCESS ] Trying to use ADSI connector to access to computer {somecomputer1} local group {administrators}
        VERBOSE: [15:22:26.4486294 PROCESS ] Trying to use ADSI connector to add user {test1} to local group {administrators} on computer {somecomputer1}
        Computername  LocalGroup     Identity status 
        ------------  ----------     -------- ------ 
        somecomputer1 administrators test1    Success
        VERBOSE: [15:22:28.7263823 PROCESS ] Processing computer {somecomputer2}
        VERBOSE: [15:22:28.7268819 PROCESS ] Trying to use ADSI connector to access to computer {somecomputer1} local group {administrators}
        VERBOSE: [15:22:28.7268819 PROCESS ] Trying to use ADSI connector to add user {test1} to local group {administrators} on computer {somecomputer1}
        Computername  LocalGroup     Identity status 
        ------------  ----------     -------- ------ 
        somecomputer2 administrators test1    Success
        VERBOSE: [15:22:30.9911669 END     ] Ending: Add-ToLocalGroup
        VERBOSE: Ending Add-ToLocalGroup 

  #>

  [CmdletBinding()]             
  [OutputType([PSObject])]
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
        $scriptName = split-path -Path ($_.InvocationInfo.ScriptName) -Leaf
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
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Verbose -Message "Ending $($MyInvocation.MyCommand)" 
  }


}
