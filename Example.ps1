cd $PSScriptRoot

. ./SourceQuery.ps1
. ./GoldSourceRcon.ps1
. ./SourceRcon.ps1

# GoldSource query
SourceQuery '127.0.0.1' '27015' 'goldsource' 'info'
SourceQuery '127.0.0.1' '27015' 'goldsource' 'players'
SourceQuery '127.0.0.1' '27015' 'goldsource' 'rules'
SourceQuery '127.0.0.1' '27015' 'goldsource' 'ping'

# GoldSource Rcon
GoldSourceRcon '127.0.0.1' '27015' 'rcon_password' 'status'

# Source query
SourceQuery '127.0.0.1' '27015' 'source' 'info'
SourceQuery '127.0.0.1' '27015' 'source' 'players'
SourceQuery '127.0.0.1' '27015' 'source' 'rules'
SourceQuery '127.0.0.1' '27015' 'source' 'ping'

# Source Rcon
SourceRcon '127.0.0.1' '27015' 'rcon_password' 'status'


