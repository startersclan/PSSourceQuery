$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "SourceQuery" -Tag 'Unit' {

    Context 'Runs' {

        $gameservers = [ordered]@{
            # Source
            left4dead2 = @{
                Address = 'l4d.startersclan.com'
                Port = 27015
                Engine = 'Source'
            }
            csgo = @{
                Address = 'cs.startersclan.com'
                Port = 27115
                Engine = 'Source'
            }
            hl2mp = @{
                Address = 'hl.startersclan.com'
                Port = 27215
                Engine = 'Source'
            }
            # GoldSource
            cstrike = @{
                Address = 'cs.startersclan.com'
                Port = 27815
                Engine = 'GoldSource'
            }
            czero = @{
                Address = 'cs.startersclan.com'
                Port = 27615
                Engine = 'GoldSource'
            }
            valve = @{
                Address = 'hl.startersclan.com'
                Port = 27915
                Engine = 'GoldSource'
            }
        }

        It 'Gets info' {
            $type = 'info'
            $ErrorActionPreference = 'Stop'

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

        }

        It 'Gets players' {
            $type = 'players'
            $ErrorActionPreference = 'Stop'

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

        }

        It 'Gets rules' {
            $type = 'rules'
            $ErrorActionPreference = 'Stop'

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

        }

        # Deprecated
        # It 'Gets ping' {
        #     $type = 'ping'

        #     foreach ($game in $gameservers.Keys) {
        #         $params = $gameservers[$game]
        #         Write-Host "game: $game"
        #         $result = SourceQuery @params -Type $type
        #         $result | Should -Not -Be $null
        #     }
        # }

    }

}
