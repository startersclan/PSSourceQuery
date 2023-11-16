$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "SourceQuery" -Tag 'Unit' {

    Context 'Behavior' {

        $gameservers = [ordered]@{
            # Source
            cs2 = @{
                Address = 'cs.startersclan.com'
                Port = 27125
                Engine = 'Source'
            }
            csgo = @{
                Address = 'cs.startersclan.com'
                Port = 27115
                Engine = 'Source'
            }
            left4dead2 = @{
                Address = 'l4d.startersclan.com'
                Port = 27015
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
                "Testing $game" | Write-Host
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result['Protocol'] | Should -BeOfType [int]
                $result['Name'] | Should -BeOfType [string]
                $result['Map'] | Should -BeOfType [string]
                $result['Folder'] | Should -BeOfType [string]
                $result['Game'] | Should -BeOfType [string]
                $result['ID'] | Should -BeOfType [int]
                $result['Players'] | Should -BeOfType [int]
                $result['Max_players'] | Should -BeOfType [int]
                $result['Bots'] | Should -BeOfType [int]
                $result['Server_type'] | Should -BeOfType [int]
                $result['Environment'] | Should -BeOfType [string]
                $result['Visibility'] | Should -BeOfType [string]
                $result['VAC'] | Should -BeOfType [string]
                $result['Version'] | Should -BeOfType [string]
                $result['Port'] | Should -BeOfType [int]
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'Gets players' {
            $type = 'players'
            $ErrorActionPreference = 'Stop'
            . "$here\..\private\Resolve-DNS.ps1"

            foreach ($game in $gameservers.Keys) {
                "Testing $game" | Write-Host
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result.Players_count | Should -BeOfType [int]
                ,$result.Players | Should -BeOfType [System.Collections.ArrayList]
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        It 'Gets rules' {
            $type = 'rules'
            $ErrorActionPreference = 'Stop'
            . "$here\..\private\Resolve-DNS.ps1"

            foreach ($game in $gameservers.Keys) {
                "Testing $game" | Write-Host
                $params = $gameservers[$game]
                $result = SourceQuery @params -Type $type
                $result.Rules_count | Should -BeOfType [int]
                ,$result.Rules | Should -BeOfType [System.Collections.ArrayList]
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        # Deprecated
        # It 'Gets ping' {
        #     $type = 'ping'

        #     foreach ($game in $gameservers.Keys) {
        #         "Testing $game" | Write-Host
        #         $params = $gameservers[$game]
        #         Write-Host "game: $game"
        #         $result = SourceQuery @params -Type $type
        #         $result | Should -Not -Be $null
        #     }
        # }

    }

}
