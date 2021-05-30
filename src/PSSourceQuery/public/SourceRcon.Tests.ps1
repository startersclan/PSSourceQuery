$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "SourceRcon" -Tag 'Unit' {

    Context 'Runs' {

        $gameservers = [ordered]@{
            # Source
            left4dead2 = @{
                Address = 'cs.startersclan.com'
                Port = 27015
            }
            csgo = @{
                Address = 'cs.startersclan.com'
                Port = 27115
            }
            hl2mp = @{
                Address = 'hl.startersclan.com'
                Port = 27215
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
                $err = SourceRcon @params -Password $password -Command $command 2>&1
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
                { SourceRcon @params -Password $password -Command $command } | Should -Throw 'some exception'
            }
        }

        It 'Fails when rcon password is wrong' {
            $password = 'foo'
            $command = 'status'
            $ErrorActionPreference = 'Stop'
            Mock Write-Verbose {}

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                { SourceRcon @params -Password $password -Command $command } | Should -Throw 'Bad rcon password.'
            }

        }

    }

}
