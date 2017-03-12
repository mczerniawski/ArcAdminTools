function New-SQLLogin {
  <#
      .SYNOPSIS
      Will create login in sql server. Optionally will add it to specified role. 

      .DESCRIPTION
      It does the following:
      1. If no SQL instance is provided it queries server for sql istances and selects if only one exists. If there are more than 1 instance - exists.
      2. Checks if login already exists on server. If not - creates one.
      3. Checks if provided SQL role is valid. If yes - checks if user is already a member of the role. if not - adds the user to specified sql role. 

      .PARAMETER ComputerName
      SQL server name.

      .PARAMETER SQLInstance
      SQL Instance name.

      .PARAMETER Identity
      User to add to SQL Server.

      .PARAMETER LoginType
      Login type in SQL. Defaults to WindowsUser.

      .PARAMETER SQLRole
      SQL role to add user to. Defaults to public. 

      .EXAMPLE
      New-SQLLogin -Computername Server1 -Username DOMAIN\user1
      It will add windows user DOMAIN\user1 on server Server1
     
      .EXAMPLE
      New-SQLLogin -Computername Server1 -SQLInstance 'SQLEXPRESS' -Username DOMAIN\user1
      It will add windows user DOMAIN\user1 on server Server1\SQLEXPRESS

      .EXAMPLE
      New-SQLLogin -Computername Server1 -SQLInstance 'SQLEXPRESS' -Username DOMAIN\user1  -LoginType WindowsUser
      It will add windows user DOMAIN\user1 on server Server1\SQLEXPRESS as WindowsUser LoginType
      
      .EXAMPLE
      New-SQLLogin -Computername Server1 -SQLInstance 'SQLEXPRESS' -Username DOMAIN\user1  -SQLRole 'sysadmin'
      It will add windows user DOMAIN\user1 on server Server1\SQLEXPRESS and add this user sysadmin role.
      
 
  #>




  [CmdletBinding()]             
  [OutputType([void])]
  
  param(
    [Parameter(Mandatory=$true,HelpMessage='Provide SQL Server name', ValueFromPipelineByPropertyName)]
    [ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })] 
       
    [string]
    $ComputerName,

    [Parameter(Mandatory=$false,HelpMessage='Provide SQL Server instance name. If none - will use default one.')]             
    [string]
    $SQLInstance,
     
    [Parameter(Mandatory=$true,HelpMessage='Provide user to grant permissions to')]             
    [string]
    $Identity,
    
    [Parameter(Mandatory=$false,HelpMessage = 'Provide LoginType')]             
    [ValidateSet('AsymmetricKey', 'Certificate', 'SqlLogin', 'WindowsGroup', 'WindowsUser')]
    [string]
    $LoginType = 'WindowsUser',
     
    [Parameter(Mandatory=$false,HelpMessage = 'Provide optional db role. If none - public role will be user')]             
    [string]
    $SQLRole = 'public'

  )
 
  begin { 
    Write-Verbose -Message "Starting $($MyInvocation.MyCommand) " 
    Write-Verbose -Message 'Execution Metadata:'
    Write-Verbose -Message "User = $($env:userdomain)\$($env:USERNAME)" 
    Write-Verbose -Message "Computername = $env:COMPUTERNAME" 
    Write-Verbose -Message "Host = $($host.Name)"
    Write-Verbose -Message "PSVersion = $($PSVersionTable.PSVersion)"
    Write-Verbose -Message "Runtime = $(Get-Date)" 
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) BEGIN   ] Starting: $($MyInvocation.Mycommand)"
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) BEGIN   ] Trying to Load SqlServer.SMO assembly"
    try { 
      [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null 
    }
    catch { 
      Write-Error -Message "[$((get-date).TimeOfDay.ToString()) BEGIN   ] $_ "
    }
  } 
    
  process {
    if (-not ($SQLInstance)) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Enumerating SQL Instances on given server {$Computername}"
      $sqlservertemp = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $Computername
      $sqlInstEnum = $sqlservertemp | Select-Object -Property InstanceName -ExpandProperty InstanceName
      if(-not ($sqlInstEnum)) {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Default instance found on server {$Computername}."
        $server = $Computername
        $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $server
      }
      elseif ($sqlInstEnum.Count -ge 2) {
        Write-Warning -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Found more than 1 instance on server {$Computername}. Please specify which one of following should be used:"
        Write-Warning -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] SQLInstance: $sqlInstEnum"
      }
      else {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Found instance {$sqlInstEnum} on server {$Computername}"
        $server = "$Computername\$sqlInstEnum"
        $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $server
      }
    }
    else {
      #ToCHeck if this is correct
      $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList "$Computername\$SQLInstance"
    }
   
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Checking if user {$Identity} exists on server {$sqlserver}"
    if($sqlserver.Logins.Contains($Identity) ) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] User {$Identity} exists on server {$sqlserver}"
    }
    else { 
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] User does not exists. Creating user {$Identity} on server {$sqlserver}"
      if ($LoginType -eq 'WindowsUser' -or $LoginType -eq 'WindowsGroup') {
        $sqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login $sqlserver, $Identity
        $SqlUser.LoginType = $LoginType
        $SqlUser.Create()
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Created user {$Identity}, type {$LoginType} on server {$sqlserver}"
      }
    }
    if($SQLRole -notcontains 'public') {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Checking if role {$SQLRole} on server {$sqlserver} is valid"
      $sqlServerRole = $sqlserver.Roles[$SQLRole]
      if(-not ($sqlServerRole) ) {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Role $SQLRole is not a valid Role on $sqlserver"
        break
      }
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Role $SQLRole is a valid Role on $sqlserver"
      if ($sqlServerRole.EnumServerRoleMembers() -contains $Identity) {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] User {$Identity} exists in role {$SQLRole} on server {$sqlserver}"
      }
      else {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Adding user {$Identity} to role {$sqlRole} on server {$sqlserver}"
        $sqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login $sqlserver, $Identity
        $sqlServerRole.AddMember("$($sqlUser.Name)")
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Added user {$Identity} to role {$sqlRole} on server {$sqlserver}"
      }
    }

  }
  End{

    Write-Verbose "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Verbose "Ending $($MyInvocation.MyCommand) " 
  }

}