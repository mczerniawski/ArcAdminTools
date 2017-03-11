function ConvertTo-HashtableFromJSON {
  <#
    .SYNOPSIS
    Retrievies json file from disk and converts to hashtable.

    .DESCRIPTION
    Reads file given as Path parameter and using ConvertTo-HashtableFromPsCustomObject converts it to a hashtable.

    .PARAMETER Path
    Path to a json file.

    .EXAMPLE
    ConvertTo-HashtableFromJSON -Path c:\AdminTools\somefile.json
    Will read somefile.json and convert it to custom hashtable.

    .INPUTS
    Path to a json file (string).

    .OUTPUTS
    Custom Hashtable.
  #>



    [CmdletBinding()]
    [OutputType([Hashtable])]
    param ( 
         [Parameter(  
             Position = 0,HelpMessage='Path to json file', 
             Mandatory = $true,   
             ValueFromPipeline = $true,  
             ValueFromPipelineByPropertyName = $true)]
         [ValidateScript({Test-Path $_ -PathType 'Leaf' })]
         
         [string]
         $Path 
     ) 

process{
    $content = Get-Content -LiteralPath $path -ReadCount 0 -Raw | Out-String
    $pscustomObject = ConvertFrom-Json -InputObject $content
    $hashtable = ConvertTo-HashtableFromPsCustomObject -psCustomObject $pscustomObject
    
    return $hashtable;
}
}


