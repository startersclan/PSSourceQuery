$MODULE_BASE_DIR = Split-Path $MyInvocation.MyCommand.Path -Parent

Get-ChildItem "$MODULE_BASE_DIR/private/*.ps1" -exclude *.Tests.ps1 | % {
    . $_.FullName
}

Get-ChildItem "$MODULE_BASE_DIR/public/*.ps1" -exclude *.Tests.ps1 | % {
    . $_.FullName
}

# Get-ChildItem "$MODULE_BASE_DIR/helper/*.ps1" -exclude *.Tests.ps1 | % {
#     . $_.FullName
# }
