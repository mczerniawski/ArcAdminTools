function Set-DHCPReservation {
  <#
      .SYNOPSIS
      Creates DHCP reservation for given parameters.

      .DESCRIPTION
      Checks if IP or MAC is already assigned. If not - creates a dhcp reservation.

      .PARAMETER ComputerName
      Server with DHCP role to create reservation on.

      .PARAMETER ScopeId
      Scope Id where to create DHCP reservation.

      .PARAMETER ReservationList
      List of hashtables with reservations parameters

      .EXAMPLE
      $ReservationList =@{
      ScopeID='10.70.1.0'
      IPAddress='10.70.1.21'
      ClientID='00-0f-ff-b0-01'
      Name='Test2'
      Description='Test2'
      }
      Set-DHCPReservation -ComputerName Server1 -ScopeId 10.70.1.0 -ReservationList $ReservationList
    
      Hashtable ReservationList is used to create reservation on Server1 on scope TestScope1

  #>



  [CmdletBinding()]
  [OutputType([void])]
  param(
    [Parameter(Mandatory,HelpMessage='Server with DHCP role')]
    [string]
    $ComputerName,
    
    [Parameter(Mandatory,HelpMessage='Scope ID')]
    [string]
    $ScopeId,
    
    [Parameter(Mandatory,HelpMessage='Hashtable with Reservarions list')]
    [PSCustomObject]
    $ReservationList
    
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
    if (Get-DhcpServerv4Scope -ComputerName $ComputerName -ScopeId $ScopeId) {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] ScopeID {$ScopeId} exists on server {$ComputerName}. Processing..."
      foreach ($ReservationItem in $ReservationList) {
        Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Processing reservation for IP {$($ReservationItem.IPAddress)} on scope {$ScopeId}, server {$ComputerName}"    
        $reservationIP = (Get-DhcpServerv4Reservation -ComputerName $computername -ScopeId $Scopeid ) | Where-Object {$_.IPAddress -eq $ReservationItem.IPAddress}
        if($reservationIP){
          if(($reservationIP.IPAddress -eq $ReservationItem.IPAddress) -AND ($reservationIP.ClientID -eq $ReservationItem.ClientID)) {
            Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Reservation with IP {$($ReservationItem.IPAddress)} and Mac {$($ReservationItem.ClientID)} already exists"
            continue
          }
          elseif(($reservationIP.IPAddress -eq $ReservationItem.IPAddress) -AND ($reservationIP.ClientID -ne $ReservationItem.ClientID)) {
            Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Reservation with IP {$($ReservationItem.IPAddress)} for differnet mac {$($ReservationItem.ClientID)} exists"
            continue
          }
                
        }
        $reservationMAC = (Get-DhcpServerv4Reservation -ComputerName $computername -ScopeId $Scopeid ) | Where-Object {$_.ClientID -eq $ReservationItem.ClientID}
        if($reservationMAC){
          if(($reservationMAC.IPAddress -eq $ReservationItem.IPAddress) -AND ($reservationMAC.ClientID -eq $ReservationItem.ClientID)) {
            Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Reservation with IP {$($ReservationItem.IPAddress)} and Mac {$($ReservationItem.ClientID)} already exists"
            continue
          }
          elseif(($reservationMAC.IPAddress -ne $ReservationItem.IPAddress) -AND ($reservationMAC.ClientID -eq $ReservationItem.ClientID)) {
            Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Reservation with MAC {$($ReservationItem.ClientID)} for different IP {$($ReservationItem.IPAddress)} exist"
            continue
          }
                
        }
        if((-not $reservationIP) -AND (-not $reservationMAC) ) {
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Creating reservation on server {$ComputerName} at scope {$ScopeId}: IPAddress = {$($ReservationItem.IPAddress)}, MAC = {$($ReservationItem.ClientID)} and name {$($ReservationItem.Name)}"
          Add-DhcpServerv4Reservation -ComputerName $ComputerName -ScopeId $ScopeID -IPAddress $ReservationItem.IPAddress -ClientId $ReservationItem.ClientID -Name $ReservationItem.Name -Description $ReservationItem.Description
          Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Created reservation on server {$ComputerName} at scope {$ScopeId}: IPAddress = {$($ReservationItem.IPAddress)}, MAC = {$($ReservationItem.ClientID)} and name {$($ReservationItem.Name)}"
                
        }
      }
    }
    else {
      Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) PROCESS ] Given ScopeID {$ScopeId} does not exist on server {$ComputerName}"
    }
  }
  
  end{
    Write-Verbose -Message "[$((get-date).TimeOfDay.ToString()) END     ] Ending: $($MyInvocation.Mycommand)"
    Write-Verbose -Message "Ending $($MyInvocation.MyCommand)" 
  }
}