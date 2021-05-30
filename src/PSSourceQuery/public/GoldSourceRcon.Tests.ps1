$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "GoldSourceRcon" -Tag 'Unit' {

    Context 'Runs' {

        $gameservers = [ordered]@{
            # GoldSource
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

        It 'Handles errors (error stream)' {
            $password = 'foo'
            $command = 'status'
            $ErrorActionPreference = 'Continue'
            Mock Write-Verbose {
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
            Mock Write-Verbose {
                throw 'some exception'
            }

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                { GoldSourceRcon @params -Password $password -Command $command } | Should -Throw 'some exception'
            }
        }

        It 'Fails when rcon password is wrong' {
            $password = 'foo'
            $command = 'status'
            $ErrorActionPreference = 'Stop'
            Mock Write-Verbose {}

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                { GoldSourceRcon @params -Password $password -Command $command } | Should -Throw 'Bad rcon_password'
            }

        }

    }

}
