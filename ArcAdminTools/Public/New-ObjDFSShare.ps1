function New-ObjDFSShare {
     <#
        .Synopsis
        Creates new fileshare in DFS namespace. Requires NTFSSecurity module 
         
        .DESCRIPTION
        It does the following steps:
        1. Creates folder and groups in AD, then sets NTFS permissions
        2. Creates share and sets share permissions
        3. Creates DFS share 

        .PARAMETER Name
        Name of the Share

        .PARAMETER Path
        Path of the share root on the fileserver. Where to create new folder. Default set to 'G:\Shares'

        .PARAMETER ComputerName
        Name of the Fileserver. Default set to 'objplfs1.objectivity.co.uk'

        .PARAMETER DFSShareUNC
        Domain DFS space. Default set to '\\objectivity.co.uk'

        .PARAMETER DFSShareNameSpace
        DFS Namespace where to host share. Default set to 'Shares'

        .PARAMETER SecurityGroupsOU
        OU where to create security access groups. Default set to 'OU=Shares_access,OU=Security Groups,DC=objectivity,DC=co,DC=uk'

        .PARAMETER Domain
        Domain where to create shares and groups. Default set to 'objectivity'.

        .EXAMPLE
        New-OBJDFSShare -Name 'TestShare1'

    
 
    #>
    
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('D:\Shares','G:\Shares')]
        [string]
        $Path='G:\Shares',

        [Parameter(Mandatory = $false)]
        [string]
        $ComputerName='objplfs1.objectivity.co.uk',

        [Parameter(Mandatory = $false)]
        [string]
        $DFSShareUNC='\\objectivity.co.uk',
        
        [Parameter(Mandatory = $false)]
        [string]
        $DFSShareNameSpace='Shares',

        [Parameter(Mandatory = $false)]
        [string]
        $SecurityGroupsOU = 'OU=Shares_access,OU=Security Groups,DC=objectivity,DC=co,DC=uk',

        [Parameter(Mandatory = $false)]
        [string]
        $Domain = 'objectivity'

    ) 

   
             
    #Create AD Groups
    $GroupRWParams = [ordered]@{
        Path = $SecurityGroupsOU 
        Name = $Name +'_RW'
        Description = "${Name}_RW Full Access"
        DisplayName = $Name +'_RW'
        SamAccountName = $Name +'_RW'
        GroupScope = 'Universal'
        GroupCategory = 'Security'
    }
    Add-GroupToAD -AdAttributes $GroupRWParams

    $GroupRParams = [ordered]@{
        Path = $SecurityGroupsOU 
        Name = $Name +'_R'
        Description = "${Name}_R ReadOnly Access"
        DisplayName = $Name +'_R'
        SamAccountName = $Name +'_R'
        GroupScope = 'Universal'
        GroupCategory = 'Security'
    }
    Add-GroupToAD -AdAttributes $GroupRParams
    sleep (5)
    $invokeParams = @{
        Path = $Path
        Name = $Name
        GroupR =  '{0}\{1}' -f $Domain, $($GroupRParams.Name)
        GroupRW = '{0}\{1}' -f $Domain, $($GroupRWParams.Name)
        DFSShareUNCFull = (Join-Path -Path $DFSShareUNC -ChildPath $DFSShareNameSpace)
        ComputerName = $ComputerName

    }
    #Write-Verbose "Parameters passed are $($invokeParams)"
    sleep(5)

    $DFSCreated = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        param ( $invokeParams)
        Import-Module NTFSSecurity

        $folder = New-Item -Path (Join-Path -Path $invokeParams.Path -ChildPath $invokeParams.Name) -ItemType Directory 
        sleep(5)      
        New-SmbShare -Name ($($invokeParams.Name) +'$') -Path $folder -Description "$($invokeParams.Name) share in DFS" -ChangeAccess $($invokeParams.GroupRW) -ReadAccess $($invokeParams.GroupR)
        
        Write-Verbose 'Disabling Inheritance' -Verbose
        Disable-NTFSAccessInheritance -Path $folder
        Write-Verbose "Removing 'BUILTIN\Users' user access"  -Verbose
        Get-Item $folder | Get-NTFSAccess -Account 'BUILTIN\Users' | Remove-NTFSAccess

        Write-Verbose "Adding Full Control for $($invokeParams.GroupRW) to $folder"  -Verbose
        Add-NTFSAccess -Path $folder -Account $invokeParams.GroupRW -AccessRights Modify -AccessType Allow
        Write-Verbose "Adding Read for $($invokeParams.GroupR) to $folder"   -Verbose
        Add-NTFSAccess -Path $folder -Account $invokeParams.GroupR -AccessRights Read -AccessType Allow

        $TempDFSPath = Join-Path -Path $invokeParams.DFSShareUNCFull -ChildPath $invokeParams.Name
        Write-Verbose "DFS Full UNC Path is set to $TempDFSPath"   -Verbose
        $Computer = ($($invokeParams.ComputerName).Split('.'))[0]
        $TempTargetPath = '\\'+ (Join-Path -Path $Computer -ChildPath ($invokeParams.Name +'$'))
        Write-Verbose "Target folder Path is set to $TempTargetPath"   -Verbose
        Write-Verbose "Creating New DFS Share $TempDFSPath on $TempTargetPath"   -Verbose
        $DFSCreated = New-DfsnFolder -Path $TempDFSPath -TargetPath $TempTargetPath -Description "$($invokeParams.Name) share in DFS"
        Write-Output $DFSCreated
    } -ArgumentList $invokeParams 

    Write-Output $DFSCreated
}
