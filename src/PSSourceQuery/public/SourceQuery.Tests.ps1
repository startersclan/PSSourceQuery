$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "SourceQuery" -Tag 'Unit' {

    Context 'Behavior' {

        $gameservers = [ordered]@{
            # Source
            # left4dead2 = @{
            #     Address = 'l4d.startersclan.com'
            #     Port = 27016
            #     Engine = 'Source'
            # }
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
            # Goldsource
            cstrike = @{
                Address = 'cs.startersclan.com'
                Port = 27815
                Engine = 'Goldsource'
            }
            czero = @{
                Address = 'cs.startersclan.com'
                Port = 27615
                Engine = 'Goldsource'
            }
            valve = @{
                Address = 'hl.startersclan.com'
                Port = 27915
                Engine = 'Goldsource'
            }
        }

        It 'Gets info' {
            $type = 'info'
            $ErrorActionPreference = 'Stop'
            . "$here\..\private\Resolve-DNS.ps1"

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

        }

        It 'Gets players' {
            $type = 'players'
            $ErrorActionPreference = 'Stop'
            . "$here\..\private\Resolve-DNS.ps1"

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

        }

        It 'Gets rules' {
            $type = 'rules'
            $ErrorActionPreference = 'Stop'
            . "$here\..\private\Resolve-DNS.ps1"

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
