function Set-DHCPScope {
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
      Value='test1.com'
      }

      Set-DHCPScope -ComputerName server1 -ScopeName TestScope1 -ScopeID 10.70.1.0 -StartRange 10.70.1.1 -EndRange 10.70.1.250 -SubnetMask 255.255.255.0 -ScopeOptions $ScopeOptions
      Will create DHCP Scope on Computer server1 with given parameters. Will set ScopeOptions as well.
      .EXAMPLE
      $ScopeOptions = @{
      Option = '15'
      Value='test1.com'
      }

      $Exclusions = @{
      StartRange = '10.70.1.1'
      EndRange = '10.70.1.10'
      }

      Set-DHCPScope -ComputerName server1 -ScopeName TestScope1 -ScopeID 10.70.1.0 -StartRange 10.70.1.1 -EndRange 10.70.1.250 -SubnetMask 255.255.255.0 -ScopeOptions $ScopeOptions -Exclusions $Exclusions
      Will create DHCP Scope on Computer server1 with given parameters. Will set ScopeOptions and ScopeExclusions.

      .EXAMPLE
      $ScopeOptions = @{
      Option = '15'
      Value='test1.com'
      }

      $Exclusions = @{
      StartRange = '10.70.1.1'
      EndRange = '10.70.1.10'
      }

      Set-DHCPScope -ComputerName server1 -ScopeName TestScope1 -ScopeID 10.70.1.0 -StartRange 10.70.1.1 -EndRange 10.70.1.250 -SubnetMask 255.255.255.0 -ScopeOptions $ScopeOptions -Exclusions $Exclusions -SuperScopeName 'test1'
      Will create DHCP Scope on Computer server1 with given parameters. Will set ScopeOptions and ScopeExclusions. Will also add to SuperScope test1
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

  begin {
    Write-Verbose -Message "Starting $($MyInvocation.MyCommand) " 
    Write-Verbose -Message 'Execution Metadata:'
    Write-Verbose -Message "User = $($env:userdomain)\$($env:USERNAME)" 
    Write-Verbose -Message "Computername = $env:COMPUTERNAME" 
    Write-Verbose -Message "Host = $($host.Name)"
    Write-Verbose -Message "PSVersion = $($PSVersionTable.PSVersion)"
    Write-Verbose -Message "Runtime = $(Get-Date)" 
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) BEGIN   ] Starting: $($MyInvocation.Mycommand)"
  }
  
  process{
   
    if(-not (Get-DhcpServerv4Scope -ComputerName $ComputerName -ScopeId $ScopeId -ErrorAction SilentlyContinue)) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Scope {$ScopeId} on {$ComputerName} does not exist. Creating..."
      Add-DhcpServerv4Scope -ComputerName $ComputerName -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Created DHCP scope on {$ComputerName} with ScopeName {$ScopeName}, StartRange {$StartRange}, EndRange {$EndRange} and SubnetMask {$SubnetMask}"
    }
    else {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Scope {$ScopeId} on {$ComputerName} already exists. Processing..."
    }
    foreach ($ScopeOption in $ScopeOptions){
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Setting ScopeOptions on Scope {$ScopeId} on {$ComputerName}."
      Set-DhcpServerv4OptionValue -ComputerName $ComputerName -OptionId $ScopeOption.Option -value $ScopeOption.Value -ScopeId $ScopeId
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Set Option {$($ScopeOption.Option)} with Value {$($ScopeOption.Value)} on server {$Computername} and ScopeID {$ScopeId} "  
    }
    if ($Exclusions) {
      foreach ($Exclusion in $Exclusions) {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Setting Exclusions on Scope {$ScopeId} on {$ComputerName}."
        if(!(Get-DhcpServerv4ExclusionRange -ComputerName $ComputerName -ScopeId $ScopeId)) {
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Creating Exclusion range {$($Exclusion.StartRange) - $($Exclusion.EndRange)} on Scope {$ScopeId} on {$ComputerName}."
          Add-DhcpServerv4ExclusionRange -ComputerName $ComputerName -ScopeId $ScopeId -StartRange $Exclusion.StartRange -EndRange $Exclusion.EndRange
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Created Exclusion range {$($Exclusion.StartRange) - $($Exclusion.EndRange)} on Scope {$ScopeId} on {$ComputerName}."
        }
        else {
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Exclusion {$($Exclusion.StartRange) - $($Exclusion.EndRange)} already exists on server {$Computername} with scope id {$ScopeId}."
        }
      }
    }
    
    if($SuperScopeName) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] SuperScope {$SuperScopeName} provided. Adding..."
      Add-DhcpServerv4Superscope -SuperscopeName $SuperScopeName -ComputerName $ComputerName -ScopeId $ScopeId
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Scope id {$ScopeId} added to SuperScope {$SuperScopeName} on server {$ComputerName}."
    }
  }
  
  end{
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Verbose -Message "Ending $($MyInvocation.MyCommand)" 
  }
}