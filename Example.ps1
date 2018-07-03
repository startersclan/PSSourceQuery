cd $PSScriptRoot

. ./SourceQuery.ps1
. ./GoldSourceRcon.ps1
. ./SourceRcon.ps1

# Examples
SourceQuery '127.0.0.1' '27015' 'info'
SourceQuery '127.0.0.1' '27015' 'players'
SourceQuery '127.0.0.1' '27015' 'rules'
SourceQuery '127.0.0.1' '27015' 'ping'

#SourceRcon '127.0.0.1' '27015' 'rcon_password' 'status'
GoldSourceRcon '127.0.0.1' '27015' 'rcon_password' 'status'

