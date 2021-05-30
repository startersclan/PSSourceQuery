# Gold Source rcon documentation from: https://forums.alliedmods.net/showpost.php?p=1718732&postcount=3
function GoldSourceRcon {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Address
    ,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int]$Port
    ,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    ,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command
    )

    try {
        # Determine the IP
        $Address = Resolve-DNS -Address $Address

        Write-Verbose "Sending GoldSourceRcon to $Address`:$Port"

        $enc = [system.Text.Encoding]::UTF8

        # Set up UDP Socket
        $remoteEP  = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($Address), $Port)
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Client.SendTimeout = 500
        $udpClient.Client.ReceiveTimeout = 500
        $udpClient.Connect($remoteEP)

        function BuildPacket ([string]$Command) {
            $pack = @(255,255,255,255) + $enc.GetBytes($Command) + 0
            $pack
        }
        function SendPacket ([byte[]]$pack) {
            Debug-Packet $MyInvocation.MyCommand.Name $pack
            $udpClient.Send($pack, $pack.Length) > $null
        }
        function ReceivePacket {
            $pack = $udpClient.Receive([ref]$remoteEP)
            Debug-Packet $MyInvocation.MyCommand.Name $pack
            $pack
        }
        function GetResponse ([byte[]]$pack) {
            $response = $enc.GetString( $pack[5..($pack.Length - 1)] )
            $response
        }
        function Init {
            # 1 - Client sends: \xFF\xFF\xFF\xFFchallenge rcon\n\0
            $pack = BuildPacket "challenge rcon`n"
            # 2 - Server replies with challenge id
            $response = SendReceive $pack
            if ($response -match '(\d+)') {
                $challengeID = $matches[1]
                Write-Verbose "Got challengeID: $challengeID"
                $challengeID
            }
        }
        function SendReceive ([byte[]]$pack) {
            SendPacket $pack
            $rPack = ReceivePacket
            $response = GetResponse $rPack
            $response
        }

        function Debug-Packet ($label, $pack) {
            if ($pack) {
                Write-Verbose "[$label]"
                #Write-Verbose "pack: $pack"
                Write-Verbose "pack: $( $pack | % { $_.ToString('X2').PadLeft(2) } )"
                Write-Verbose "pack: "
                Write-Verbose "$( $pack | % { if ($_ -eq 0x00) { "\".PadLeft(2) } else { [System.Text.Encoding]::Utf8.GetString($_).Trim().PadLeft(2) } } )"
                Write-Verbose "length: $($pack.Length)"
                Write-Verbose ""
            }
        }

        # Rcon
        $challengeID = Init
        if (!$challengeID) {
            throw "No challengeID."
        }else {
            # 3 - Client sends: \xFF\xFF\xFF\xFFrcon CHALLENGEID RCONPASSWORD COMMAND
            $pack = BuildPacket "rcon $challengeID $Password $Command"
            # 4 - Server replies with plain text
            $response = SendReceive $pack
            $udpClient.Dispose()
            if ($response -match 'Bad rcon_password') {
                throw $response
            }
            $response
        }
    }catch {
        if ($ErrorActionPreference -eq 'Stop') {
            throw
        }else {
            Write-Error -ErrorRecord $_
        }
    }
}
