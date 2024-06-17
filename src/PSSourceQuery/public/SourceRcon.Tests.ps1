$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "SourceRcon" -Tag 'Unit' {

    BeforeEach {
        $gameservers = [ordered]@{
            # Source
            # left4dead2 = @{
            #     Address = 'l4d.startersclan.com'
            #     Port = 27015
            # }
            csgo = @{
                Address = 'cs.startersclan.com'
                Port = 27115
            }
            hl2mp = @{
                Address = 'hl.startersclan.com'
                Port = 27215
            }
        }

        . "$here/../private/Resolve-DNS.ps1"
    }

    Context 'Error handling' {

        It 'Handles errors (error stream)' {
            $password = 'foo'
            $command = 'status'
            $ErrorActionPreference = 'Continue'
            function Resolve-DNS {
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
            function Resolve-DNS {
                throw 'some exception'
            }

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                { SourceRcon @params -Password $password -Command $command } | Should -Throw 'some exception'
            }
        }

    }

    Context 'Behavior' {

        It 'Fails when rcon password is wrong' {
            $password = "$( Get-Random -Minimum 1 -Maximum 1000000 )"
            $command = 'status'
            $ErrorActionPreference = 'Stop'
            Mock Write-Verbose {}

            foreach ($game in $gameservers.Keys) {
                $params = $gameservers[$game]
                {
                    SourceRcon @params -Password $password -Command $command
                } | Should -Throw 'Bad rcon password.'
            }

        }

    }

}
