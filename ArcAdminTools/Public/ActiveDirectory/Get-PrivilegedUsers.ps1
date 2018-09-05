function Get-PrivilegedUsers {
    <#
      .SYNOPSIS
      Returns all users belonging to Privileged Groups in Domain
  
      .DESCRIPTION
      Will return all members of Groups with 'AdminCount=1'. Can target other domains - require ComputerName and Credential parameter then. 
  
      .PARAMETER ComputerName
      Domain Controller of another domain. Provide FQDN name
  
      .PARAMETER Credential
      Optional Credential parameter to foreign domain if current user has no read rights in target domain
  
      .EXAMPLE
      Get-PrivilegedUsers 
      Will query current domain for all members of Privileged Groups
  
      .EXAMPLE
      Get-PrivilegedUsers -ComputerName PDC1.contoso.com -Credential (Get-Credential)
      Will query PDC1.contoso.com for all members of Privileged Groups using provided Credentials
    #>
  
  
      
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = 'Domain Controler, provide FQDN',
            ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ComputerName,
  
        [Parameter(Mandatory = $false, HelpMessage = 'Provide Credentials to access domain',
            ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Credential()][System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    process { 
        $connectionProps = @{
            Filter = 'AdminCount -eq 1'
        }
        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            $connectionProps.Server = $ComputerName
            Write-Verbose -Message "Will try to connect to DC {$ComputerName} to query for Privileged Groups"
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $connectionProps.Credential = $Credential
            Write-Verbose -Message "Will try to connect to DC {$ComputerName} using Credential {$($connectionProps.Credential.UserName)}"
        }
        
        $privilegedGroups = Get-ADGroup @connectionProps
        if ($privilegedGroups) {
            if ($connectionProps.Server) {
                $DomainController = $connectionProps.Server
            }
            else {
                $DomainController = Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName
            }
            foreach ($group in $privilegedGroups) {
                Write-Verbose -Message "Processing group {$($group.Name)}"
                Get-ADGroupMember -identity $group | foreach-object { 
                    [pscustomobject]@{
                        groupName        = $group.Name
                        samaccountname   = $PSItem.samaccountname
                        Name             = $PSItem.Name
                        DomainController = $DomainController
                    }
                }
            }
        }
    }
}