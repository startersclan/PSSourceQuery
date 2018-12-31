# SourceQuery-Powershell

[SourceQuery](https://developer.valvesoftware.com/wiki/Server_queries) and [Rcon](https://developer.valvesoftware.com/wiki/Source_RCON_Protocol) interface for [Source](https://developer.valvesoftware.com/wiki/Source) and [Goldsource](https://developer.valvesoftware.com/wiki/Goldsource) games.


## SourceQuery Examples

### Source Engine

```powershell
Import-Module SourceQuery

# A2S_INFO query
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'info'      # Returns a hashtable of server metadata

# A2S_PLAYER query
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'players'   # Returns a hashtable of players

# A2S_RULES query
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'rules'     # Returns a hashtable of server cvars

# A2A_PING query
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'ping'      # Returns a hashtable of whether the ping was successful
```

### Goldsource Engine

```powershell
Import-Module SourceQuery

# A2S_INFO query
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'info'      # Returns a hashtable of server metadata

# A2S_PLAYER query
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'players'  # Returns a hashtable of players

# A2S_RULES query
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'rules'    # Returns a hashtable of server cvars

# A2A_PING query
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'ping'     # Returns a hashtable of whether the ping was successful
```

## Rcon Examples

### Source Engine

```powershell
Import-Module SourceRcon
SourceRcon -Address $ip -Port $port -Password $rcon_password -Command 'status'
```

### Goldsource Engine

```powershell
Import-Module GoldsourceRcon
GoldsourceRcon -Address $ip -Port $port -Password $rcon_password -Command 'status'
```

## Minumum Requirements

- `Powershell` V5 or later or `Powershell Core` (aka `pwsh`)

## Debugging

Use the `-Verbose` switch to turn on verbose output.