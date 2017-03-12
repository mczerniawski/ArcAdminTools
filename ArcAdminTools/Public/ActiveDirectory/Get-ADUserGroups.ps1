function Get-ADUserGroups {
  <#
      .Synopsis
      Retrieves all groups user belongs to from specified OU.
      .DESCRIPTION
      Retrieves all groups user belongs to from specified OU. If no OU is specified then domain root is set as default.
 
      .PARAMETER Identity
      Can take username or multiple usernames as a parameter.

      .PARAMETER SearchOU
      Expects DN of an OU. If not provided will deafult to root domain DN. 
      
      .EXAMPLE
      Get-ADUserGroups -Identity 'someuser' 
      Will query for all groups 'someuser' belongs to in current Domain

      .EXAMPLE
      Get-ADUserGroups -Identity 'someuser' -SearchOU 'OU=Security Groups,OU=SOME_OU,DC=corp,DC=org'
      Will query for all groups from Security Groups in SOME_OU 'someuser' belongs to in current Domain.
    
  #>

  [CmdletBinding()]             
  [OutputType([PSObject])]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] 
    [string[]]
    $Identity,
         
    [Parameter(Mandatory=$false)] 
    [string]
    $SearchOU= (Get-ADDomain).DistinguishedName

  )
  begin{
    Write-Verbose "Starting $($MyInvocation.MyCommand) " 
    Write-Verbose "Execution Metadata:"
    Write-Verbose "User = $($env:userdomain)\$($env:USERNAME)" 
    Write-Verbose "Computername = $env:COMPUTERNAME" 
    Write-Verbose "Host = $($host.Name)"
    Write-Verbose "PSVersion = $($PSVersionTable.PSVersion)"
    Write-Verbose "Runtime = $(Get-Date)" 

    Write-Verbose "[$((get-date).TimeOfDay.ToString()) BEGIN   ] Starting: $($MyInvocation.Mycommand)"
 
  }

  process{

    try
    {
      foreach ($user in $Identity){
        Write-Verbose "[$((get-date).TimeOfDay.ToString()) PROCESS ] Processing user {$user}"
        $userTest = Get-ADUser -Identity $user -Properties Memberof -ErrorAction SilentlyContinue
        if($userTest) {
          Write-Verbose "[$((get-date).TimeOfDay.ToString()) PROCESS ] User found in AD. Processing user {$user}" 
          foreach ($groupTest in ( ($userTest.MemberOf)| Select-String $SearchOU )) {
            if (-not $groupTest) {
              Write-Verbose "[$((get-date).TimeOfDay.ToString()) PROCESS ] No group found for user {$user} in given SearchBase {$SearchOU}" 
            }
            elseif ($groupTest) {                    
              $userGroup = [psCustomObject]@{
                Identity = $userTest.samAccountName
                Group = (Get-ADGroup "$groupTest").SamAccountName
              }
              $userGroup
            } 
          }
        }
      }
    }
    catch 
    {
      Write-Error -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] $_ "
    }


  }

  end{
    Write-Verbose "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Verbose "Ending $($MyInvocation.MyCommand) " 
  } 
   
   
       

  

}