function Resolve-DNS {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Address
    )

    try {
        # Determine the IP
        try {
            $ipAddress = $null
            [System.Net.IPAddress]::TryParse($Address, [ref]$ipAddress) > $null
            # IP
            $Address = $ipAddress.IPAddressToString
        }catch {
            # DNS
            try {
                "Resolving DNS: $Address" | Write-Verbose
                $ipAddresses = [System.Net.Dns]::GetHostAddresses($Address)
                $address = $ipAddresses[0].IPAddressToString
                # $ipAddress = [System.Net.Dns]::GetHostEntry($Address)
                # $ipAddress = [System.Net.Dns]::Resolve($Address)
                # $address = $ipAddress.AddressList[0].IPAddressToString
            }catch {
                throw "Failed to resolve DNS: $Address"
            }
        }
    }catch {
        if ($ErrorActionPreference -eq 'Stop') {
            throw
        }else {
            Write-Error -ErrorRecord $_
        }
    }
    $Address
}
