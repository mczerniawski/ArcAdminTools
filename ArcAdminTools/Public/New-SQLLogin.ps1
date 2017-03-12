function New-SQLLogin {
  <#
      .SYNOPSIS
      Will create login in sql server. Optionally will add it to specified role. 
      .DESCRIPTION
      It does the following:
      1. If no SQL instance is provided it queries server for sql istances and selects if only one exists. If there are more than 1 instance - exists.
      2. Checks if login already exists on server. If not - creates one.
      3. Checks if provided SQL role is valid. If yes - checks if user is already a member of the role. if not - adds the user to specified sql role. 
      .PARAMETER Computername
      SQL server name.
      .PARAMETER SQLInstance
      SQL Instance name.
      .PARAMETER Username
      User to add to SQL Server.
      .PARAMETER LoginType
      Login type in SQL. Defaults to WindowsUser.
      .PARAMETER SQLRole
      SQL role to add user to. Defaults to public. 
      .EXAMPLE
      New-SQLLogin -Computername Server1 -Username DOMAIN\user1
    
      It will add windows user DOMAIN\user1 on server Server1
      Enumerating SQL Instances on given server {Server1}
      Found instance {SQLEXPRESS} on server {Server1}
      Checking if user {DOMAIN\user1} exists on server {[Server1\SQLEXPRESS]}
      User does not exists. Creating user {DOMAIN\user1} on server {[Server1\SQLEXPRESS]}
      Created user {DOMAIN\user1}, type {WindowsUser} on server {[Server1\SQLEXPRESS]}
      .EXAMPLE
      New-SQLLogin -Computername Server1 -SQLInstance 'SQLEXPRESS' -Username DOMAIN\user1
    
      It will add windows user DOMAIN\user1 on server Server1\SQLEXPRESS
      Checking if user {DOMAIN\user1} exists on server {[Server1\SQLEXPRESS]}
      User does not exists. Creating user {DOMAIN\user1} on server {[Server1\SQLEXPRESS]}
      Created user {DOMAIN\user1}, type {WindowsUser} on server {[Server1\SQLEXPRESS]}
      .EXAMPLE
      New-SQLLogin -Computername Server1 -SQLInstance 'SQLEXPRESS' -Username DOMAIN\user1  -LoginType WindowsUser
    
      It will add windows user DOMAIN\user1 on server Server1\SQLEXPRESS as WindowsUser LoginType
      Checking if user {DOMAIN\user1} exists on server {[Server1\SQLEXPRESS]}
      User does not exists. Creating user {DOMAIN\user1} on server {[Server1\SQLEXPRESS]}
      Created user {DOMAIN\user1}, type {WindowsUser} on server {[Server1\SQLEXPRESS]}
      .EXAMPLE
      New-SQLLogin -Computername Server1 -SQLInstance 'SQLEXPRESS' -Username DOMAIN\user1  -SQLRole 'sysadmin'
    
      It will add windows user DOMAIN\user1 on server Server1\SQLEXPRESS and add this user sysadmin role.
      Checking if user {DOMAIN\user1} exists on server {[Server1\SQLEXPRESS]}
      User does not exists. Creating user {DOMAIN\user1} on server {[Server1\SQLEXPRESS]}
      Created user {DOMAIN\user1}, type {WindowsUser} on server {[Server1\SQLEXPRESS]}
      Checking if role {sysadmin} on server {[Server1\SQLEXPRESS]} is valid
      Role sysadmin is a valid Role on [Server1\SQLEXPRESS]
      Adding user {DOMAIN\user1} to role {sysadmin} on server {[Server1\SQLEXPRESS]}
      Added user {DOMAIN\user1} to role {sysadmin} on server {[Server1\SQLEXPRESS]}
 
  #>




  [CmdletBinding()]             
  [OutputType([void])]
  
  param(
    [Parameter(Mandatory=$true,HelpMessage='Provide SQL Server name', ValueFromPipelineByPropertyName)]
    [ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })] 
       
    [string]
    $Computername,

    [Parameter(Mandatory=$false,HelpMessage='Provide SQL Server instance name. If none - will use default one.')]             
    [string]
    $SQLInstance,
     
    [Parameter(Mandatory=$true,HelpMessage='Provide user to grant permissions to')]             
    [string]
    $Username,
    
    [Parameter(Mandatory=$false,HelpMessage = 'Provide LoginType')]             
    [ValidateSet('AsymmetricKey', 'Certificate', 'SqlLogin', 'WindowsGroup', 'WindowsUser')]
    [string]
    $LoginType = 'WindowsUser',
     
    [Parameter(Mandatory=$false,HelpMessage = 'Provide optional db role. If none - public role will be user')]             
    [string]
    $SQLRole = 'public'

  )
 
  begin { 
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null 
  } 
    
  process {
  
    if (-not ($SQLInstance)) {
      Write-Verbose -Message "Enumerating SQL Instances on given server {$Computername}"
      $sqlservertemp = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $Computername
      $sqlInstEnum = $sqlservertemp | Select-Object -Property InstanceName -ExpandProperty InstanceName
      if(-not ($sqlInstEnum)) {
        Write-Verbose "Default instance found on server {$Computername}."
        $server = $Computername
        $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $server
      }
      elseif ($sqlInstEnum.Count -ge 2) {
        Write-Warning -Message "Found more than 1 instance on server {$Computername}. Please specify which one of following should be used:"
        Write-Warning -Message $sqlInstEnum
      }
      else {
        Write-Verbose -Message "Found instance {$sqlInstEnum} on server {$Computername}"
        $server = "$Computername\$sqlInstEnum"
        $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $server
      }
    }
    else {
      #ToCHeck if this is correct
      $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList "$Computername\$SQLInstance"
      
    }
   
    Write-Verbose -Message "Checking if user {$Username} exists on server {$sqlserver}"
    if($sqlserver.Logins.Contains($Username) ) {
      Write-Verbose -Message "User {$Username} exists on server {$sqlserver}"
    }
    else { 
      Write-Verbose -Message  "User does not exists. Creating user {$Username} on server {$sqlserver}"
      if ($LoginType -eq 'WindowsUser' -or $LoginType -eq 'WindowsGroup') {
        $sqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login $sqlserver, $Username
        $SqlUser.LoginType = $LoginType
        $SqlUser.Create()
        Write-Verbose -Message "Created user {$Username}, type {$LoginType} on server {$sqlserver}"
      }
    }
    
 
    
    if($SQLRole -notcontains 'public') {
      Write-Verbose -Message "Checking if role {$SQLRole} on server {$sqlserver} is valid"
      $sqlServerRole = $sqlserver.Roles[$SQLRole]
      if(-not ($sqlServerRole) ) {
        Write-Verbose -Message "Role $SQLRole is not a valid Role on $sqlserver"
        break
      }
      Write-Verbose -Message "Role $SQLRole is a valid Role on $sqlserver"
      if ($sqlServerRole.EnumServerRoleMembers() -contains $Username) {
        Write-Verbose "{$Username} exists in role {$SQLRole} on server {$sqlserver}"
      }
      else {
        Write-Verbose -Message "Adding user {$Username} to role {$sqlRole} on server {$sqlserver}"
        $sqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login $sqlserver, $Username
        $sqlServerRole.AddMember("$($sqlUser.Name)")
        Write-Verbose -Message "Added user {$Username} to role {$sqlRole} on server {$sqlserver}"
      }
    }

  }

}