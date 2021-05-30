$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Resolve-DNS" -Tag 'Unit' {

    Context 'Behavior' {

        It 'Handles errors (error stream)' {
            $address = 'zzz'
            $ErrorActionPreference = 'Continue'

            $err = Resolve-DNS -Address $address 2>&1
            $err | ? { $_ -is [System.Management.Automation.ErrorRecord] } | % { $_.Exception.Message } | Should -Match 'Failed to resolve DNS'
        }

        It 'Handles errors (exception)' {
            $address = 'zzz'

            { Resolve-DNS -Address $address | Should -Throw 'Failed to resolve DNS' }
        }

        It 'Validates and returns an IP if an IP was passed' {
            $address = '127.0.0.1'
            $ErrorActionPreference = 'Stop'

            $result = Resolve-DNS -Address $address
            $result | Should -BeOfType [string]
            $result | Should -Be $address

        }

        It 'Resolves DNS to IP' {
            $address = 'example.com'
            $ErrorActionPreference = 'Stop'

            $result = Resolve-DNS -Address $address
            $result | Should -BeOfType [string]
            $result | Should -Not -Be $null

        }

    }

}
