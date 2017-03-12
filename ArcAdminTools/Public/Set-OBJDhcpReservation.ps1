function Set-OBJDhcpReservation {
  <#
    .SYNOPSIS
    Creates DHCP reservation for given parameters.

    .DESCRIPTION
    Checks if IP or MAC isn't already assigned and if not, creates dhcp reservation.

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
    Set-OBJDhcpReservation -ComputerName Server1 -ScopeId 10.70.1.0 -ReservationList $ReservationList
    
    Hashtable ReservationList is used to create reservation on Server1 on scope TestScope1

  #>



  [CmdletBinding()]
  [OutputType([void])]
  param(
    [Parameter(Mandatory,HelpMessage='Add help message for user')]
    [string]
    $ComputerName,
    
    [Parameter(Mandatory,HelpMessage='Add help message for user')]
    [string]
    $ScopeId,
    
    [Parameter(Mandatory,HelpMessage='Add help message for user')]
    [PSCustomObject]
    $ReservationList
    
  )

  begin {}
  
  process{
    if (Get-DhcpServerv4Scope -ComputerName $ComputerName -ScopeId $ScopeId) {
        foreach ($ReservationItem in $ReservationList) {
         
            $reservationIP = (Get-DhcpServerv4Reservation -ComputerName $computername -ScopeId $Scopeid ) | Where-Object {$_.IPAddress -eq $ReservationItem.IPAddress}
            if($reservationIP){
                if(($reservationIP.IPAddress -eq $ReservationItem.IPAddress) -AND ($reservationIP.ClientID -eq $ReservationItem.ClientID)) {
                    Write-Log -Info -Emphasize "Reservation with IP {$($ReservationItem.IPAddress)} and Mac {$($ReservationItem.ClientID)} already exists"
                    continue
                }
                elseif(($reservationIP.IPAddress -eq $ReservationItem.IPAddress) -AND ($reservationIP.ClientID -ne $ReservationItem.ClientID)) {
                    Write-Log -Info -Emphasize "Reservation with IP {$($ReservationItem.IPAddress)} for differnet mac {$($ReservationItem.ClientID)} exists"
                    continue
                }
                
            }
            $reservationMAC = (Get-DhcpServerv4Reservation -ComputerName $computername -ScopeId $Scopeid ) | Where-Object {$_.ClientID -eq $ReservationItem.ClientID}
            if($reservationMAC){
                if(($reservationMAC.IPAddress -eq $ReservationItem.IPAddress) -AND ($reservationMAC.ClientID -eq $ReservationItem.ClientID)) {
                    Write-Log -Info -Emphasize "Reservation with IP {$($ReservationItem.IPAddress)} and Mac {$($ReservationItem.ClientID)} already exists"
                    continue
                }
                elseif(($reservationMAC.IPAddress -ne $ReservationItem.IPAddress) -AND ($reservationMAC.ClientID -eq $ReservationItem.ClientID)) {
                    Write-Log -Info -Emphasize "Reservation with MAC {$($ReservationItem.ClientID)} for different IP {$($ReservationItem.IPAddress)} exist"
                    continue
                }
                
            }
            if((-not $reservationIP) -AND (-not $reservationMAC) ) {
                Add-DhcpServerv4Reservation -ComputerName $ComputerName -ScopeId $ScopeID -IPAddress $ReservationItem.IPAddress -ClientId $ReservationItem.ClientID -Name $ReservationItem.Name -Description $ReservationItem.Description
                Write-Log -Info -Emphasize "Created reservation on server {$Computername} at scope {$ScopeId}: IPAddress = {$($ReservationItem.IPAddress)}, MAC = {$($ReservationItem.ClientID)} and name {$($ReservationItem.Name)}"
                
            }
        }
    }
    else {
        Write-Log -Info -Emphasize "Given Scope {$ScopeName} does not exist on server {$Computername}"
    }
    
  }
  
  end{}



}