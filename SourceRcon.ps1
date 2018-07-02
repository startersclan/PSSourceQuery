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
        [ValidateSet('info', 'players', 'rules', 'ping')]
        [string]$Type
    )

    # Constants (Request Body)
    $A2S_INFO = 0x54
    $A2S_PLAYER = 0x55
    $A2S_RULES = 0x56
    $A2A_PING = 0x69
    $A2S_SERVERQUERY_GETCHALLENGE # Deprecated

    if ($g_debug -band 8) { Write-Host "Sending SourceQuery to $Address`:$Port" }
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
        if ($g_debug -band 8) { $pack | % { " " + $_.ToString("X") | Write-Host -NoNewline }  }
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

    function GetQueryData ([byte[]]$rPack) {
        if ($requestBody -eq $A2S_INFO) {

            $pack = BuildPacket
            SendPacket $pack
            $rPack = ReceivePacket
            if (!$rPack.Length) { return }

            $buffer = [SourceQueryBuffer]::New($rPack)
            $Junk = $buffer.GetLong()
            $Header = $buffer.GetByte()

            if ($Header -eq 0x6D) {
                # Obsolute Goldsource
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
            return $Info
        }elseif ($requestBody -eq $A2S_PLAYER) {
            # Send a challenge request
            $pack = @(255,255,255,255) + $requestBody + @( 0x00, 0x00, 0x00, 0x00)
            SendPacket $pack
            $rpack = ReceivePacket
            if (!$rPack.Length) { return }

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
            return $Players
        }elseif ($requestBody -eq $A2S_RULES) {
            # Send a challenge request
            $pack = @(255,255,255,255) + $requestBody + @( 0x00, 0x00, 0x00, 0x00)
            $pack | % { " " + $_.ToString("X") | Write-Host -NoNewline }
            SendPacket $pack
            $rpack = ReceivePacket
            $rpack | % { " " + $_.ToString("X") | Write-Host -NoNewline }
            if (!$rPack.Length) { return }

            # A2S_RULES request
            $pack = @(255,255,255,255) + $requestBody + $rpack[5..8]
            $pack | % { " " + $_.ToString("X") | Write-Host -NoNewline }
            SendPacket $pack
            
            
            
            try {
                $rPack = ''
                $Rules = [ordered]@{
                    Rules_count = 0
                    Rules = [System.Collections.ArrayList]@() 
                }
                $i = 0
                while ($rPack = ReceivePacket) {
                    $i++
                    if (!$remainderBytes) {
                        $buffer = [SourceQueryBuffer]::New($rPack)
                        $Junk = $buffer.GetLong()
                        $Header = $buffer.GetByte()
                        $rules_count = $buffer.GetShort()

                        ## Clean out junk from Older games?
                        $Junk = $buffer.GetShort()
                        $Junk = $buffer.GetLong() 
                        $Header = $buffer.GetByte()
                        $rules_count = $buffer.GetShort()

                        $Rules['Rules_count'] += $rules_count
                    }else {
                        # First 4 is: 0xFE 0xFF 0xFF 0xFF
                        # Next 4 is: 37 0 0 0
                        $buffer = [SourceQueryBuffer]::New($remainderBytes + $rPack[ 8..$($rPack.Length - 1) ])
                    }
                    

                    while ($true) {
                        if ($buffer.HasMore()) {
                            $rule = [ordered]@{
                                Name = $buffer.GetString()
                                Value = $buffer.GetString()
                            }
                            $Rules['Rules'].Add( $rule ) > $null
                            
                        }else {
                            $remainderBytes = $buffer.GetRemaining()
                            break
                        }
                    }
                    if ($remainderBytes -eq $null) {
                        break
                    }
                }
            }catch {
                if ($rPack -eq $null) { throw }
            }
           return $Rules
        }elseif ($requestBody -eq $A2A_PING) {

        }
    }
    function GetResponse ($pack) {
        $response = $enc.GetString( $pack[5..($pack.Length - 1)] )
        $response
    }
    # Rcon
    try {
        $body = GetQueryData $pack
        $udpClient.Dispose()
        $body
    }catch {
        throw $_
    }
}