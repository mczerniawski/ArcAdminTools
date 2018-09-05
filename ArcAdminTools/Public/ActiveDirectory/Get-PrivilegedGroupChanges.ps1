Function Get-PrivilegedGroupChanges {
    <#
      .SYNOPSIS
      Will check for changes in Privileged Groups using Replication Metadata
  
      .DESCRIPTION
      Will return all members of Groups with 'AdminCount=1' that changed within last $Hours. Can target other domains - require ComputerName and Credential parameter then.
  
      .PARAMETER ComputerName
        Domain Controller of another domain. Provide FQDN name
    
        .PARAMETER Credential
        Optional Credential parameter to foreign domain if current user has no read rights in target domain
  
      .PARAMETER Hour
      How many hours back should search for changes
  
      .EXAMPLE
      Get-PrivilegedGroupChanges -ComputerName PDC1.contoso.com -Credential (Get-Credential) -Hour 24
      Will return all members of Privileged Groups that changed within last 24 from provided DomainController $ComputerName using given Credentials
    #>
  
       
         
    [CmdletBinding()]   
    Param(            
        [Parameter(Mandatory = $false, HelpMessage = 'Domain Controler, provide FQDN',
            ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ComputerName,
    
        [Parameter(Mandatory = $false, HelpMessage = 'Provide Credentials to access domain',
            ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Credential()][System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
            
        [Parameter(Mandatory = $false, HelpMessage = 'How many hours to include in search',
            ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int32]
        $Hour          
    )
    process { 
        $connectionProps = @{}
        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            $connectionProps.Server = $ComputerName
            Write-Verbose -Message "Will try to connect to DC {$ComputerName} to query for Privileged Groups"
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $connectionProps.Credential = $Credential
            Write-Verbose -Message "Will try to connect to DC {$ComputerName} using Credential {$($connectionProps.Credential.UserName)}"
        }
        if ($PSBoundParameters.ContainsKey('Hour')) {
            $SearchHours = $Hour
        }
        else {
            $SearchHours = 24
        }
        Write-Verbose -Message "Will search for changes within {$SearchHours} hours"
                 
        $privilegedGroups = Get-ADGroup @connectionProps -Filter 'AdminCount -eq 1'
        if ($privilegedGroups) {
            if ($connectionProps.Server) {
                $DomainController = $connectionProps.Server
            }
            else {
                $DomainController = Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName
            }
            $PrivilegedMembers = foreach ($group in $privilegedGroups) {
                Write-Verbose -Message "Processing group {$($group.Name)}"
                Get-ADReplicationAttributeMetadata -Server $DomainController -Object $Group.DistinguishedName -ShowAllLinkedValues |            
                    Where-Object {$_.IsLinkValue} |             
                    Select-Object -Property @{name = 'GroupDN'; expression = {$Group.DistinguishedName}}, 
                @{name = 'GroupName'; expression = {$Group.Name}}, *   
            }
            $MembersChanged = $PrivilegedMembers | Where-Object {$_.LastOriginatingChangeTime -gt (Get-Date).AddHours(-1 * $SearchHours)}  
            if ($MembersChanged) {
                Write-Verbose -Message "Found changes in protected groups in last {$SearchHours} hours"
                $MembersChanged
            } 
            else {
                Write-Verbose -Message "No changes to protected groups in last {$Hour} hours"
            }
        }
    }
} 