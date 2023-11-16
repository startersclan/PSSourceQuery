# - Initial setup: Fill in the GUID value. Generate one by running the command 'New-GUID'. Then fill in all relevant details.
# - Ensure all relevant details are updated prior to publishing each version of the module.
# - To simulate generation of the manifest based on this definition, run the included development entrypoint script Invoke-PSModulePublisher.ps1.
# - To publish the module, tag the associated commit and push the tag.
@{
    RootModule = 'PSSourceQuery.psm1'
    # ModuleVersion = ''                            # Value will be set for each publication based on the tag ref. Defaults to '0.0.0' in development environments and regular CI builds
    GUID = '4d4854bd-0f11-4342-8b69-83e9eaaf4067'
    Author = 'Starters Clan'
    CompanyName = 'Starters Clan'
    Copyright = '(c) 2018 Starters Clan'
    Description = 'Powershell implementation of Query and Rcon for Source and Goldsource games.'
    PowerShellVersion = '5.0'
    # PowerShellHostName = ''
    # PowerShellHostVersion = ''
    # DotNetFrameworkVersion = ''
    # CLRVersion = ''
    # ProcessorArchitecture = ''
    # RequiredModules = @()
    # RequiredAssemblies = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()
    FunctionsToExport = @(
        Get-ChildItem $PSScriptRoot/../../src/PSSourceQuery/public -Exclude *.Tests.ps1 | % { $_.BaseName }
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    # DscResourcesToExport = @()
    # ModuleList = @()
    # FileList = @()
    PrivateData = @{
        # PSData = @{           # Properties within PSData will be correctly added to the manifest via Update-ModuleManifest without the PSData key. Leave the key commented out.
            Tags = @(
                'goldsource-dedicated-server'
                'goldsource'
                'hlds'
                'library'
                'powershell'
                'pwsh'
                'query'
                'rcon'
                'source-dedicated-server'
                'source'
                'sourcequery'
                'srcds'
                'steam'
                'steam-games'
                'steam'
                'valve'
            )
            LicenseUri = 'https://raw.githubusercontent.com/startersclan/PSSourceQuery/master/LICENSE'
            ProjectUri = 'https://github.com/startersclan/PSSourceQuery'
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            # ExternalModuleDependencies = @()
        # }
        # HelpInfoURI = ''
        # DefaultCommandPrefix = ''
    }
}
