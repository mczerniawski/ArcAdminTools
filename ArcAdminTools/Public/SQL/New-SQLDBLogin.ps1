Function New-SQLDBLogin {
  <#
      .SYNOPSIS
      This will add user to SQL db role on given database.

      .DESCRIPTION
      If given SQL and DB are valid it will:
      1. Check if user exists on SQL server. If so it will:
      2. Check if dabatase contains user. If not - will add.
      3. Check if database role contains user - if not it will add.
        
      .PARAMETER ComputerName
      SQL server name.

      .PARAMETER SQLInstance
      SQL Instance name.

      .PARAMETER Username
      User to add to SQL Server database.
      .PARAMETER Database
      SQL Server Database to alter. 
      
      .PARAMETER DBRole
      DB Role to add user to on given database.
      
      .EXAMPLE
      New-SQLDBLogin -SQLServer Server1 -Database DB1 -User domain\user1 -dbRole db_owner
      It will add windows user domain\user1 to db role db_owner on database DB1 on server Server1

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
    $Identity,
    
    [Parameter(Mandatory=$true,HelpMessage='Provide SQL DB name to alter roles')]             
    [string]
    $Database,
    
    [Parameter(Mandatory=$true,HelpMessage='Provide role name to alter with new user')]             
    [string]
    $DBRole
  
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
        Write-Warning -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] SQLInstance :$sqlInstEnum"
        break
      }
      else {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Found instance {$sqlInstEnum} on server {$Computername}"
        $server = "$Computername\$sqlInstEnum"
        $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList $server
      }
    }
    else {
      $sqlserver = new-object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList "$Computername\$SQLInstance"
    }
   
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Checking if user {$Identity} exists on server {$sqlserver}"
    if(-not ($sqlserver.Logins.Contains($Identity) )) {
      Write-Error -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] User {$Identity} is not a valid login on server {$sqlserver}. Create it first!"
      break
    }
    elseif (-not ($sqlserver.Databases[$Database])) {
      Write-Error -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Database {$Database} is not a valid database on server {$sqlserver}"
      break
    }
    elseif (-not ($sqlserver.Databases[$Database].Roles[$DBRole]))  {
      Write-Error -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Role {$DBRole} is not a valid role on database {$Database} on server {$sqlserver}"
      break
    }
    elseif ($sqlserver.Databases[$dataBase].Roles[$DBRole].EnumMembers() -contains $Identity) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Database {$DataBase} role {$DBRole} on server {$sqlserver} already contains user {$Identity}"
      break
    }
    elseif($sqlserver.Databases[$dataBase].EnumLoginMappings() | Where-Object {$_.LoginName -contains $Identity}) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Database {$dataBase} on server {$sqlserver} already contains user {$Identity}"
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Adding user {$Identity} to dbrole {$DBRole} on database {$Database} on server {$sqlserver}"
      ($sqlserver.Databases[$Database].Roles[$DBRole]).AddMember($Identity)
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Added user {$Identity} to dbrole {$DBRole} on database {$Database} on server {$sqlserver}"
      break
    }
    else {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Database {$dataBase} on server {$sqlserver} does not contains user {$Identity}"
      $dbUser = New-Object -TypeName ('Microsoft.SqlServer.Management.Smo.User') -ArgumentList ($sqlserver.Databases[$dataBase], $Identity)
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Creating user {$Identity} on database {$dataBase} on server {$sqlserver}"
      $dbUser.Login = $Identity
      $dbUser.Create()
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Adding user {$Identity} to dbrole {$DBRole} on database {$Database} on server {$sqlserver}"
      ($sqlserver.Databases[$Database].Roles[$DBRole]).AddMember($Identity)
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Added user {$Identity} to dbrole {$DBRole} on database {$Database} on server {$sqlserver}"
    }
 
  }
}