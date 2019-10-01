# Source Rcon: https://developer.valvesoftware.com/wiki/Source_RCON_Protocol
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

    try {
        Write-Verbose "Sending SourceRcon to $Address`:$Port"

        $enc = [system.Text.Encoding]::UTF8

        # Rcon props
        $SERVERDATA_AUTH = 3
        $SERVERDATA_EXECCOMMAND = 2
        $SERVERDATA_AUTH_RESPONSE = 2
        $SERVERDATA_RESPONSE_VALUE = 0
        $auth = 0
        $packetID_Auth = 1
        $packetID = 10
        $packetID_MultipackDummy = $SERVERDATA_RESPONSE_VALUE

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
        function BuildPacket ([int]$ID, [int]$TYPE, [string]$BODY) {
            $pack = (IntToBytes $ID) + (IntToBytes $TYPE) + $enc.GetBytes($BODY) + 0 + 0
            $pack = (IntToBytes $pack.Length) + $pack
            $pack
        }
        function SendPacket ([byte[]]$pack) {
            Debug-Packet $MyInvocation.MyCommand.Name $pack
            $stream.Write($pack, 0, $pack.Length)
        }
        function ReceivePacket ([int]$packetSize) {
            [byte[]]$pack = New-Object byte[] $packetSize
            $memStream = New-Object System.IO.MemoryStream
            $bytes = 0
            do {
                try {
                    $bytes = $stream.Read($pack, 0, $pack.Length)
                    $memStream.Write($pack, 0, $bytes)
                    Debug-Packet $MyInvocation.MyCommand.Name $pack
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
            $IdBytes = $pack[0..3]
            $typeBytes = $pack[4..7]
            $bodyBytes = $pack[8..($pack.Length -1 -1 -1)] # Ignore Null Character at 1) at Packet Empty String Terminator 2) end of Packet Body
            @{
                Id = BytesToInt32 $IdBytes
                Type = BytesToInt32 $typeBytes
                Body = $enc.GetString($bodyBytes)
                IdBytes = $IdBytes
                TypeBytes = $typeBytes
                BodyBytes = $bodyBytes
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
        # Send and receive (Synchronous)
        function SendReceive ([string]$Command) {
            $pack = BuildPacket $packetID $SERVERDATA_EXECCOMMAND $Command
            SendPacket $pack

            $answer = ''
            while ($true) {
                try {
                    # Read the Size of packet
                    $rPack = ReceivePacket 4
                    if (!$rPack.Length) { return }
                    $size = BytesToInt32 $rPack
                    $rPack = ReceivePacket $size

                    # Now read the packet
                    $response = ParsePacket $rPack
                    if ($response['ID'] -eq $packetID_MultipackDummy) {
                        # At the end of a multiple-packet response, the dummy empty packet is finally mirrored, followed by another RESPONSE_VALUE packet containing 0x0000 0001 0000 0000 in the packet body field.
                        # See: https://developer.valvesoftware.com/wiki/Source_RCON_Protocol#Multiple-packet_Responses
                        $rPack = ReceivePacket 4
                        $size = BytesToInt32 $rPack
                        $rPack = ReceivePacket $size
                        $response = ParsePacket $rPack
                        if ( $response['Body'] -eq $enc.GetString([byte[]]@(0x00, 0x01, 0x00, 0x00)) ) {
                            Write-Verbose "End of multiple-packet response."
                            break
                        }
                    }
                    $answer += $response['Body'].Trim()

                    if (!$dummyPacketSent) {
                        # Always send one dummy empty packet right after the sending a first packet to determine whether we will get a multiple-packet response
                        # See: https://developer.valvesoftware.com/wiki/Source_RCON_Protocol#Multiple-packet_Responses
                        Write-Verbose "Sending dummy empty packet."
                        $pack = BuildPacket $packetID_MultipackDummy $SERVERDATA_RESPONSE_VALUE ''
                        SendPacket $pack
                        $dummyPacketSent = $true
                    }
                }catch {
                    # No more packets to read from socket
                    break
                }
            }
            $answer
        }

        function Debug-Packet ([string]$label, [byte[]]$pack) {
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
        $success = Auth
        if ($success -eq -1) {
            throw "Bad rcon password."
        }else {
            $auth = 1
            # Send and receive (Sync)
            $answer = SendReceive $Command
            $packetID++
        }
        $tcpClient.Dispose()
        $answer
    }catch {
        if ($ErrorActionPreference -eq 'Stop') {
            throw
        }else {
            Write-Error -ErrorRecord $_
        }
    }
}

Export-ModuleMember -Function SourceRcon
