$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "GoldSourceRcon" -Tag 'Unit' {

    BeforeEach {
        $gameservers = [ordered]@{
            # Goldsource
            cstrike = @{
                Address = 'cs.startersclan.com'
                Port = 27815
            }
            czero = @{
                Address = 'cs.startersclan.com'
                Port = 27615
            }
            valve = @{
                Address = 'hl.startersclan.com'
                Port = 27915
            }
        }
    }

    Context 'Error handling' {

        It 'Handles errors (error stream)' {
            $password = 'foo'
            $command = 'status'
            $ErrorActionPreference = 'Continue'
            . "$here\..\private\Resolve-DNS.ps1"
            Mock Resolve-DNS {
                throw 'some error'
            }

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                $err = GoldSourceRcon @params -Password $password -Command $command 2>&1
                $err | ? { $_ -is [System.Management.Automation.ErrorRecord] } | % { $_.Exception.Message } | Should -Match 'some error'
            }
        }

        It 'Handles errors (exception)' {
            $password = 'foo'
            $command = 'status'
            $ErrorActionPreference = 'Stop'
            . "$here\..\private\Resolve-DNS.ps1"
            Mock Resolve-DNS {
                throw 'some exception'
            }

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                { GoldSourceRcon @params -Password $password -Command $command } | Should -Throw 'some exception'
            }
        }
    }

    Context 'Behavior' {

        It 'Fails when rcon password is wrong' {
            $password = "$( Get-Random -Minimum 1 -Maximum 1000000 )"
            $command = 'status'
            $ErrorActionPreference = 'Stop'
            . "$here\..\private\Resolve-DNS.ps1"
            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                {
                    GoldSourceRcon @params -Password $password -Command $command
                } | Should -Throw 'Bad rcon_password'
            }
        }

    }

}
