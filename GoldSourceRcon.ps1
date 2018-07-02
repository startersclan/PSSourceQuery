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

    if ($g_debug -band 8) { Write-Host "Sending GoldSourceRcon to $Address`:$Port" }
    if (!$Address) { throw "Invalid address" }

    $enc = [system.Text.Encoding]::UTF8

    # Set up UDP Socket
    $remoteEP  = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($Address), $Port)
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $udpClient.Client.SendTimeout = 500
    $udpClient.Client.ReceiveTimeout = 500
    $udpClient.Connect($remoteEP)


    function BuildPacket ($Command) {
        $pack = @(255,255,255,255) + $enc.GetBytes($Command) + 0
        $pack
    }
    function SendPacket ($pack) {
        if ($g_debug -band 8) { Write-host "[SendPacket] pack: $pack, length:$($pack.Length)" -ForegroundColor Yellow }
        $udpClient.Send($pack, $pack.Length) > $null
    }
    function ReceivePacket {
        $pack = $udpClient.Receive([ref]$remoteEP)
        if ($g_debug -band 8) { Write-host "[ReceivePack] pack: $pack, length:$($pack.Length)" -ForegroundColor Yellow }
        $pack
    }
    function GetResponse ($pack) {
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
            if ($g_debug -band 8) { Write-Host "Got challengeID: $challengeID" }
            $challengeID
        }
    }
    function SendReceive ($pack) {
        SendPacket $pack
        $rPack = ReceivePacket
        $response = GetResponse $rPack
        $response
    }
    # Rcon
    try {
        $challengeID = Init
        if (!$challengeID) {
            throw "Bad rcon password."
        }else {
            # 3 - Client sends: \xFF\xFF\xFF\xFFrcon CHALLENGEID RCONPASSWORD COMMAND
            $pack = BuildPacket "rcon $challengeID $Password $Command"
            # 4 - Server replies with plain text
            $response = SendReceive $pack
            $udpClient.Dispose()
            $response
        }
    }catch {
        throw $_
    }
}