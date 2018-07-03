function SourceRcon {
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

    if ($g_debug -band 8) { Write-Host "Sending SourceRcon to $Address`:$Port" }

    $enc = [system.Text.Encoding]::UTF8

    # Rcon props
    $SERVERDATA_AUTH = 3
    $SERVERDATA_EXECCOMMAND = 2
    $SERVERDATA_AUTH_RESPONSE = 2
    $SERVERDATA_RESPONSE_VALUE = 0
    $auth = 0
    $packetID_Auth = 1
    $packetID = 10

    # Set up TCP Socket
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Client.SendTimeout = 500
    $tcpClient.Client.ReceiveTimeout = 500

    # Connect the TCP Socket (Sync) - Not using this because there's no socket timeout!
    <#
    $remoteEP  = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($Address), $Port)
    $tcpClient.Connect($remoteEP)
    if (!$tcpClient.Connected) {
        Write-Host "Could not connect to remote host: $Address`:$Port"
    }
    #>

    # Connect the TCP Socket (Async yet sync) - Now there's a socket timeout
    $result = $tcpClient.BeginConnect([System.Net.IPAddress]::Parse($Address), $Port, $null, $null)
    $success = $result.AsyncWaitHandle.WaitOne([System.TimeSpan]::FromSeconds(2))
    if (!$success) {
        throw "Could not connect to remote host: $Address`:$Port"
    }
    if (! $tcpclient.Connected) {
        throw "Could not connect to remote host: $Address`:$Port"
    }

    # Set up Network stream
    [System.Net.Sockets.NetworkStream]$stream = $tcpClient.GetStream()
    $stream.ReadTimeout = 500
    $stream.WriteTimeout = 500

    function IntToBytes ([int]$integer) {
        [byte[]]$bytes = [BitConverter]::GetBytes($integer)
        if (![BitConverter]::IsLittleEndian) {
            [array]::Reverse($bytes)
        }
        $bytes
    }
    function BytesToInt32 ($bytes) {
        [BitConverter]::ToInt32($bytes, 0)
    }
    function BuildPacket ($ID, $TYPE, $BODY) {
        $pack = (IntToBytes $ID) + (IntToBytes $TYPE) + $enc.GetBytes($BODY) + 0 + 0
        $pack = (IntToBytes $pack.Length) + $pack
        $pack
    }
    function SendPacket ([byte[]]$pack) {
        if ($g_debug -band 8) { Write-host "[SendPacket] pack: $pack, length:$($pack.Length)" -ForegroundColor Yellow }
        $stream.Write($pack, 0, $pack.Length)
    }
    function ReceivePacket ($packetSize) {
        [byte[]]$pack = New-Object byte[] $packetSize
        $memStream = New-Object System.IO.MemoryStream
        $bytes = 0
        do {
            try {
                $bytes = $stream.Read($pack, 0, $pack.Length)
                $memStream.Write($pack, 0, $bytes)
                if ($g_debug -band 8) { Write-host "bytes: $bytes, pack: $pack, length: $($pack.Length)" -ForegroundColor Yellow }
                if ($pack) {
                    break
                }
            }catch {
                throw "Did not receive any response."
            }
        }while($bytes -gt 0)
        $memStream.Dispose()
        $pack
    }
    function ParsePacket ([byte[]]$pack) {
        @{  'Size' = BytesToInt32 $pack[0..3]
            'Id' = BytesToInt32 $pack[4..7]
            'Type' = BytesToInt32 $pack[8..11]
            'Body' = $enc.GetString($pack[12..($pack.Length - 1)])
            'Bytes' = $pack
        }
    }
    function Auth {
        $pack = BuildPacket $packetID_Auth $SERVERDATA_AUTH $Password
        SendPacket $pack
        $emptyPack = ReceivePacket (4+10)
        $authPack = ReceivePacket (4+10)
        $ID = BytesToInt32 $authPack[4..7]
        $ID
    }
    # Send and receive (Sync)
    function SendReceive ($Command) {
        $packetID++
        $pack = BuildPacket $packetID $SERVERDATA_EXECCOMMAND $Command
        SendPacket $pack
        $rPack = ReceivePacket 4096
        if (!$rPack.Length) {
            return
        }
        $mainPacket = ParsePacket $rPack
        if ($g_debug -band 8) { Write-Host "[first]`nreceived body: $($mainPacket['Body']) `nsize: $($mainPacket['Size']) `nend: $( BytesToInt32 $mainPacket['Bytes'][12..15] )" }
        $body += ($mainPacket['Body']).Trim()


        # Always send one dummy empty response packet to determine if there's multipack
        if (!$multipack) {
            $pack = BuildPacket $packetID $SERVERDATA_RESPONSE_VALUE ''
            SendPacket $pack
            $rPack = ReceivePacket(4+10);
            $pollPacket = ParsePacket $rPack
            if ($g_debug -band 8) { Write-Host "[dummy]`nreceived body: $($pollPacket['Body']) `nsize: $($pollPacket['Size'])" }
            if ($mainPacket.Size -gt 10) {
                # The last two bytes are actually the start of the multipack
                $multipack = 1
                $body +=  $enc.GetString($pollPacket["Bytes"][12..13])
            }
        }

        # Only for multipack cases
        while ($multipack) {
            try {
                $rPack = ReceivePacket 4096
                if ((BytesToInt32 $rPack[12..15]) -eq 256) {
                    Write-Host "No more multipack!"
                    break
                }
                $body_continued = $enc.GetString($rPack)
                $body += $body_continued.Trim()
                Write-Host "Continued:`n $body_continued"
            }catch {
                Write-Host "No more packets."
                break
            }
        }
        $body
    }
    # Rcon
    try {
        $success = Auth
        if ($success -eq -1) {
            throw "Bad rcon password."
        }else {
            $auth = 1
            # Send and receive (Sync)
            $body = SendReceive $Command
        }
        $tcpClient.Dispose()
        $body
    }catch {
        throw $_
    }
}