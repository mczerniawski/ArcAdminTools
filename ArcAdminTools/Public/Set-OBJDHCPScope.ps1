function Set-OBJDHCPScope {
  <#
      .SYNOPSIS
      Create DHCP scope on given server

      .DESCRIPTION
      If given scope doesn't exists it's created. Then Scope values are set. Then Exclusions are created. 

      .PARAMETER ComputerName
      Server with DHCP Role

      .PARAMETER ScopeName
      Scope Name to create or modify

      .PARAMETER ScopeId
      ScopeID to create or modify

      .PARAMETER StartRange
      Start of IP address space to lease

      .PARAMETER EndRange
      End of IP address space to lease

      .PARAMETER SubnetMask
      IP Subnet mask of address space configured on this server

      .PARAMETER Exclusions
      Optional parameter of exclusions to set on DHCP lease

      .PARAMETER ScopeOptions
      Scope options like router or DNS servers

      .PARAMETER SuperScopeName
      Optional parameter. If provided super scope will be created or appended with this scope. 

      .EXAMPLE
      $ScopeOptions = @{
         Option = '15'
        Value='test1.co.uk'
      }

      Set-OBJDHCPScope -ComputerName $server1 -ScopeName TestScope1 -ScopeID 10.70.1.0 -StartRange 10.70.1.1 -EndRange 10.70.1.250 -SubnetMask 255.255.255.0 -ScopeOptions $ScopeOptions

      .EXAMPLE
      $ScopeOptions = @{
         Option = '15'
        Value='test1.co.uk'
      }

      $Exclusions = @{
        StartRange = '10.70.1.1'
        EndRange = '10.70.1.10'
      }

      Set-OBJDHCPScope -ComputerName $server1 -ScopeName TestScope1 -ScopeID 10.70.1.0 -StartRange 10.70.1.1 -EndRange 10.70.1.250 -SubnetMask 255.255.255.0 -ScopeOptions $ScopeOptions -Exclusions $Exclusions

        .EXAMPLE
      $ScopeOptions = @{
         Option = '15'
        Value='test1.co.uk'
      }

      $Exclusions = @{
        StartRange = '10.70.1.1'
        EndRange = '10.70.1.10'
      }

      Set-OBJDHCPScope -ComputerName $server1 -ScopeName TestScope1 -ScopeID 10.70.1.0 -StartRange 10.70.1.1 -EndRange 10.70.1.250 -SubnetMask 255.255.255.0 -ScopeOptions $ScopeOptions -Exclusions $Exclusions -SuperScopeName 'test1'
  #>
  [CmdletBinding()]
  [OutputType([void])]
  param(

    [Parameter(Mandatory = $true,HelpMessage='Server with DHCP role')]
    [string]
    $ComputerName,
    
    [Parameter(Mandatory = $true,HelpMessage='Name for DHCP scope')]
    [string]
    $ScopeName,
    
    [Parameter(Mandatory = $true,HelpMessage='Scope ID')]
    [string]
    $ScopeId,
    
    [Parameter(Mandatory = $true,HelpMessage='Start range of IP pool')]
    [string]
    $StartRange,
    
    [Parameter(Mandatory = $true,HelpMessage='End range of IP pool')]
    [string]
    $EndRange,
    
    [Parameter(Mandatory = $true,HelpMessage='Subnet mask for IP scope')]
    [string]
    $SubnetMask,

    [Parameter(Mandatory = $false,HelpMessage='List of IP exclusions')]
    [PSCustomObject]
    $Exclusions,
    
    [Parameter(Mandatory = $true,HelpMessage='Hashtable of option/value for scope')]
    [PSCustomObject]
    $ScopeOptions,
    
    [Parameter(Mandatory = $false,HelpMessage='SuperScope name')]
    [string]
    $SuperScopeName
    
  )

  begin {}
  
  process{
    #scopeID do wyciagniecia przed nawias
    if(!(Get-DhcpServerv4Scope -ComputerName $ComputerName -ScopeId $ScopeId -ErrorAction SilentlyContinue)) {
        Add-DhcpServerv4Scope -ComputerName $ComputerName -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask 
        Write-Log -Info "Created DHCP scope on {$ComputerName} with ScopeName {$ScopeName}, StartRange {$StartRange}, EndRange {$EndRange} and SubnetMask {$SubnetMask}" -Emphasize
    }
    else {
        Write-Log -Info "Already exists DHCP scope on {$ComputerName} with ScopeName {$ScopeName}, StartRange {$StartRange}, EndRange {$EndRange} and SubnetMask {$SubnetMask}" -Emphasize
    }
    foreach ($ScopeOption in $ScopeOptions){
        Set-DhcpServerv4OptionValue -ComputerName $ComputerName -OptionId $ScopeOption.Option -value $ScopeOption.Value -ScopeId $ScopeId
        Write-Log -Info "On server {$Computername} and ScopeID {$ScopeId} set Option {$($ScopeOption.Option)} with Value {$($ScopeOption.Value)}" -Emphasize
    }
    if ($Exclusions) {
        foreach ($Exclusion in $Exclusions) {
            if(!(Get-DhcpServerv4ExclusionRange -ComputerName $ComputerName -ScopeId $ScopeId)) {
                Add-DhcpServerv4ExclusionRange -ComputerName $ComputerName -ScopeId $ScopeId -StartRange $Exclusion.StartRange -EndRange $Exclusion.EndRange
                Write-Log -Info -Emphasize "Created exclusion range on server {$Computername} with scope id {$ScopeId}, start range {$($Exclusion.StartRange)} and end range {$($Exclusion.EndRange)}"
            }
            else {
                Write-Log -Info -Emphasize "Exclusion already exists on server {$Computername} with scope id {$ScopeId}, start range {$($Exclusion.StartRange)} and end range {$($Exclusion.EndRange)}"
            }
        }
    }
    
    if($SuperScopeName) {
      Add-DhcpServerv4Superscope -SuperscopeName $SuperScopeName -ComputerName $ComputerName -ScopeId $ScopeId
      Write-Log -Info -Emphasize "On server {$ComputerName} added scope id {$ScopeId} to SuperScope {$SuperScopeName}"
    }
  }
  
  end{}



}