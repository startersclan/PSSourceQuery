###############
#  Libraries  #
###############

# Source Query documnetation from: https://developer.valvesoftware.com/wiki/Server_Queries#Multi-packet_Response_Format
class SourceQueryBuffer {
    SourceQueryBuffer([byte[]]$buffer) {
        $this.buffer = $buffer

        $bufferTmp = $this.buffer.Clone()
        [array]::Reverse($bufferTmp)
        $this.lastNullCharacterPosition = $this.buffer.length - 1 - $bufferTmp.IndexOf( [byte]0 )
    }

    [byte[]]$buffer
    [int] hidden $position
    [int] hidden $lastNullCharacterPosition

    [int]PeekByte() {
        $data = $this.buffer[ $this.position ]
        return $data
    }
    [int]GetByte() {
        $this.position++
        $data = $this.buffer[ $this.position - 1 ]
        return $data
    }
    [int]GetShort() {
        $this.position += 2
        $data = [BitConverter]::ToInt16($this.buffer, $this.position - 2) #
        return $data
    }
    [int]GetLong() {
        $this.position += 4
        $data = [BitConverter]::ToInt32($this.buffer, $this.position - 4)
        return $data
    }
    [int]GetLongLong() {
        $this.position += 8
        $data = [BitConverter]::ToInt64($this.buffer, $this.position - 8)
        return $data
    }
    [float]GetFloat() {
        #$bytes = $this.buffer[ ($this.position) .. ($this.position + 3) ]
        #[float[]]$floatArr = [float]($bytes.length / 4)
        # for ($i = 0; $i -lt $floatArr.Length; $i++) {
        #     if ([BitConverter]::IsLittleEndian) {
        #         [Array]::Reverse($bytes, $i * 4, 4)
        #     }
        #     $floatArr[$i] = [BitConverter]::ToSingle($bytes, $i * 4)
        # }
        #return $floatArr[0]

        $bytes = $this.buffer[ ($this.position) .. ($this.position + 3) ]
        if ([BitConverter]::IsLittleEndian) {
            #[Array]::Reverse($bytes)
        }
        $float = [BitConverter]::ToSingle($bytes, 0)
        $this.position += 4
        return $float
    }
    [string]GetString() {
        $bufferRemaining = $this.buffer[ $($this.position) .. $( $this.buffer.Length - 1 ) ]
        $nullTerminatorPosition = $bufferRemaining.IndexOf( [byte]0 )
        $str = [System.Text.Encoding]::UTF8.GetString($bufferRemaining[ 0 .. $nullTerminatorPosition ])
        $this.position += $nullTerminatorPosition + 1
        return $str.Trim("`0")
    }
    [bool]HasMore() {
        if ($this.position -lt $this.lastNullCharacterPosition) {
            return $true
        }
        return $false
    }
    # Returns all bytes after the last Null Character Position until end of byte array
    [byte[]]GetRemainingBytes() {
        if ($this.lastNullCharacterPosition -eq -1) {
            return $null
        }else {
            $bytes = $this.buffer[ $($this.lastNullCharacterPosition + 1) .. $($this.buffer.Length - 1) ]
            return $bytes
        }
        return $null
    }
    [string]GetRemainingString() {
        $bytes = $this.GetRemainingBytes()
        if ($bytes -ne $null) {
            return [System.Text.Encoding]::UTF8.GetString( $bytes )
        }
        return ''
    }
}

function SourceQuery {
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
        [ValidateSet('GoldSource', 'Source')]
        [string]$Engine
    ,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('info', 'players', 'rules', 'ping')]
        [string]$Type
    )

    # Constants (Request Body)
    $A2S_INFO = 0x54
    $A2S_PLAYER = 0x55
    $A2S_RULES = 0x56
    $A2A_PING = 0x69
    $A2S_SERVERQUERY_GETCHALLENGE = 0x57 # Deprecated

    Write-Verbose "Sending SourceQuery to $Address`:$Port"
    if (!$Address) { throw "Invalid address" }

    # Set up UDP Socket
    $remoteEP  = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($Address), $Port)
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $udpClient.Client.SendTimeout = 500
    $udpClient.Client.ReceiveTimeout = 500
    $udpClient.Connect($remoteEP)

    $requestBody = ''
    if ($Type -match 'info') {
        $requestBody = $A2S_INFO
    }elseif ($Type -match 'players') {
        $requestBody = $A2S_PLAYER
    }elseif ($Type -match 'rules') {
        $requestBody = $A2S_RULES
    }elseif ($Type -match 'ping') {
        $requestBody = $A2A_PING
    }


    function BuildPacket () {
        $pack = @(255,255,255,255) + $requestBody + [System.Text.Encoding]::UTF8.GetBytes('Source Engine Query') + 0
        $pack
    }
    function SendPacket ($pack) {
        Debug-Packet $MyInvocation.MyCommand.Name $pack
        $udpClient.Send($pack, $pack.Length) > $null
    }
    function ReceivePacket {
        $pack = $udpClient.Receive([ref]$remoteEP)
        Debug-Packet $MyInvocation.MyCommand.Name $pack
        $pack
    }

    function GetQueryData ([byte[]]$rPack) {
        if ($requestBody -eq $A2S_INFO) {

            $pack = BuildPacket
            SendPacket $pack
            $rPack = ReceivePacket
            if (!$rPack.Length) { return }

            $buffer = [SourceQueryBuffer]::New($rPack)
            $Junk = $buffer.GetLong()
            $Header = $buffer.GetByte()

            if ($Header -eq 0x6C) {
                # 'l' - Banned by the server.
                $Info = [ordered]@{
                    Message = $buffer.GetString()
                    Banned = $true
                }
            }else {
                if ($Header -eq 0x6D) {
                    # 'm' - Obsolute Goldsource
                    $Info = [ordered]@{
                        Address = $buffer.GetString()
                        Name = $buffer.GetString()
                        Map = $buffer.GetString()
                        # ....
                    }
                }else {
                    $Info = [ordered]@{
                        Protocol = $buffer.GetByte()
                        Name = $buffer.GetString()
                        Map = $buffer.GetString()
                        Folder = $buffer.GetString()
                        Game = $buffer.GetString()
                        ID = $buffer.GetShort()
                        Players = $buffer.GetByte()
                        Max_players = $buffer.GetByte()
                        Bots = $buffer.GetByte()
                        Server_type = $buffer.GetByte()
                        Environment = & {
                                            switch ( [System.Text.Encoding]::UTF8.GetString($buffer.GetByte()) ) {
                                                'l' { 'linux'; break }
                                                'w' { 'windows'; break }
                                                'm' { 'mac'; break }
                                                default: { '' }
                                            }
                                        }
                        Visibility = if ($buffer.GetByte() -eq 0) { 'public' } else { 'public'}
                        VAC = if ($buffer.GetByte() -eq 0) { 'secured' } else { 'unsecured' }
                    }

                    if ($Info['ID'] -eq 2400) {
                        # AppID 2400 is The Ship
                        $Info['Mode'] = $buffer.GetByte()
                        $Info['Witnesses'] = $buffer.GetByte()
                        $Info['Duration '] = $buffer.GetByte()
                    }

                    $Info['Version'] = $buffer.GetString()

                    $extraDataFlag = $buffer.GetByte()
                    if ($extraDataFlag -band 0x80) {
                        # Server's game port number
                        $Info['Port'] = $buffer.GetShort()
                    }elseif ($extraDataFlag -band 0x80) {
                        # Server's SteamID
                        $Info['SteamID'] = $buffer.GetLongLong()
                    }elseif ($extraDataFlag -band 0x40) {
                        # Source TV port and name
                        $Info['Port'] = $buffer.GetShort()
                        $Info['Name'] = $buffer.GetString()
                    }elseif ($extraDataFlag -band 0x20) {
                        # Tags that describe the game according to the server (for future use.)
                        $Info['Keywords'] = $buffer.GetString()
                    }elseif ($extraDataFlag -band 0x01) {
                        # The server's 64-bit GameID. If this is present, a more accurate AppID is present in the low 24 bits. The earlier AppID could have been truncated as it was forced into 16-bit storage.
                        $Info['GameID'] = $buffer.GetLongLong()
                    }
                }
            }
            return $Info
        }elseif ($requestBody -eq $A2S_PLAYER) {
            # Send a challenge request
            $pack = @(255,255,255,255) + $requestBody + @( 0x00, 0x00, 0x00, 0x00)
            SendPacket $pack
            $rpack = ReceivePacket
            if (!$rPack.Length) { return }

            # Are we banned?
            $buffer = [SourceQueryBuffer]::New($rPack)
            $Header = $buffer.GetByte()
            if ($Header -eq 0x6C) {
                # 'l' - Banned by the server.
                $Players = [ordered]@{
                    Message = $buffer.GetString()
                    Banned = $true
                }
            }else {

                # A2S_PLAYER request
                $pack = @(255,255,255,255) + $requestBody + $rpack[5..8]
                SendPacket $pack
                $rpack = ReceivePacket
                if (!$rPack.Length) { return }

                $buffer = [SourceQueryBuffer]::New($rPack)
                $Junk = $buffer.GetLong()
                $Header = $buffer.GetByte()

                $Players = [ordered]@{
                    Players_count = $buffer.GetByte()
                    Players = [System.Collections.ArrayList]@()
                }
                if ($Players['Players_count'] -gt 0) {
                    1..$Players['Players_count'] | % {
                        $player = [ordered]@{
                            Index = $buffer.GetByte()
                            Name = $buffer.GetString()
                            Score = $buffer.GetLong()
                            Duration = $buffer.GetFloat()
                        }
                        $duration = [int]($player['Duration'])
                        $duration = New-Timespan -Seconds $duration
                        $player['Duration_hh_mm_ss'] = if ($duration.Hours -gt 0) { $duration.ToString('hh\:mm\:ss') } else { $duration.ToString('mm\:ss') }

                        $Players['Players'].Add( $player ) > $null
                    }
                }
            }
            return $Players
        }elseif ($requestBody -eq $A2S_RULES) {
            # Send a challenge request
            $pack = @(255,255,255,255) + $requestBody + @( 0x00, 0x00, 0x00, 0x00)
            SendPacket $pack
            $rpack = ReceivePacket
            if (!$rPack.Length) { return }

            # Are we banned?
            $buffer = [SourceQueryBuffer]::New($rPack)
            $Junk = $buffer.GetLong()
            $Header = $buffer.GetByte()
            if ($Header -eq 0x6C) {
                # 'l' - Banned by the server.
                $Rules = [ordered]@{
                    Message = $buffer.GetString()
                    Banned = $true
                }
            }else {

                # A2S_RULES request
                $pack = @(255,255,255,255) + $requestBody + $rpack[5..8]
                SendPacket $pack

                try {
                    $rPack = ''
                    $Rules = [ordered]@{
                        Rules_count = 0
                        Rules = [System.Collections.ArrayList]@()
                    }

                    $cnt = 0
                    while ($rPack = ReceivePacket) {
                        $buffer = [SourceQueryBuffer]::New($rPack)

                        # Packet Header
                        $packetHeader = $buffer.GetLong() # 4

                        if ($packetHeader -eq -2) {

                            # PacketID
                            $packetIDTmp = $buffer.GetLong() # 4
                            if ($packetID -ne $null -and $packetID -ne $packetIDTmp) {
                                # Invalid multipacket packetID. PacketID does not match the multipacket set's packetID
                                return
                            }
                            $packetID = $packetIDTmp

                            # PacketCount
                            # PacketNumber and PacketSize for newer Source Engines only
                            if ($Engine -match '^Source$') {
                                $packetCount = $buffer.GetByte() # 1
                                $packetNumber = $buffer.GetByte() # 1
                                $packetSize = $buffer.GetShort() # 2
                            }elseif ($Engine -match '^GoldSource$') {
                                if ($cnt -eq 0) {
                                    $packetCount = $buffer.GetByte() # 1
                                }else {
                                    $Junk_0x12 = $buffer.GetByte() # 1
                                }
                            }
                        }

                        # FF FF FF FF, Header, and Rule count in first packet
                        if ($cnt -eq 0) {
                            $Junk = $buffer.GetLong()
                            $Header = $buffer.GetByte()
                            $Rules_count = $buffer.GetShort()

                            $Rules['Rules_count'] += $Rules_count
                        }

                        while ($buffer.HasMore()) {
                            $rule = [ordered]@{
                                Name =  if ($remainderString) {
                                            # Prepend the remainder of the previous tuncated packet to this first entry of current packet
                                            $remainderString + $buffer.GetString()
                                        } else { $buffer.GetString() }
                                Value = $buffer.GetString()
                            }
                            $Rules['Rules'].Add( $rule ) > $null
                            $remainderString = ''
                        }
                        $remainderString = $buffer.GetRemainingString()
                        if ($remainderString -eq '') {
                            break
                        }
                        $cnt++
                    }
                }catch {
                    if ($rPack -eq $null) { throw }
                }
            }
            return $Rules
        }elseif ($requestBody -eq $A2A_PING) {
            # A2A_PING is no longer supported on Counter Strike: Source and Team Fortress 2 servers, and is considered a deprecated feature.
            # See: https://developer.valvesoftware.com/wiki/Server_Queries#A2A_PING

            # A2A_PING request
            $pack = @(255,255,255,255) + $requestBody
            SendPacket $pack
            $rpack = ReceivePacket
            if (!$rPack.Length) { return }

            # Are we banned?
            $buffer = [SourceQueryBuffer]::New($rPack)
            $Junk = $buffer.GetLong()
            $Header = $buffer.GetByte()
            if ($Header -eq 0x6C) {
                # 'l' - Banned by the server.
                $Ping = [ordered]@{
                    Message = $buffer.GetString()
                    Banned = $true
                }
            }

            $ping_response = $buffer.GetByte()
            $Ping = [ordered]@{
                Success = $true
            }
            return $Ping
        }
    }
    function GetResponse ($pack) {
        $response = $enc.GetString( $pack[5..($pack.Length - 1)] )
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
    try {
        $answer = GetQueryData
        $udpClient.Dispose()
        $answer
    }catch {
        if ($ErrorActionPreference -eq 'Stop') {
            throw
        }else {
            Write-Error -ErrorRecord $_
        }
    }
}
