# PSSourceQuery

Powershell implementation of [SourceQuery](https://developer.valvesoftware.com/wiki/Server_queries) and [Rcon](https://developer.valvesoftware.com/wiki/Source_RCON_Protocol) for [Source](https://developer.valvesoftware.com/wiki/Source) and [Goldsource](https://developer.valvesoftware.com/wiki/Goldsource) games.

## Prerequisites

- [`Powershell` V5](https://www.microsoft.com/en-us/download/details.aspx?id=50395) or later or [`Powershell Core`](https://github.com/powershell/powershell) (aka `pwsh`)

## Verified games

Engine           |       Games
:---------------:|:---------------:
`Source` (`srcds`) | `left4dead2`, `csgo`, `hl2mp`
`Goldsource` (`hlds`) | `cstrike`, `czero`, `valve`. Should work for all `hlds` games.

The libraries will probably work on a lot more games than those in the list.

## Notes

The libraries are *stateless* - that is, `SourceQuery`, `SourceRcon`, and `GoldsourceRcon` are pure functions, storing no authentication or challenge states. This is to be expected for Source Queries, but not for Rcon. A possible future area of improvement would be to make `SourceRcon` and `GoldsourceRcon` construct and return a stateful Rcon object, that would improve client performance especially when multiple rcon commands need to be executed in sequence.

## Usage

### SourceQuery

```powershell
# Source Engine
Import-Module SourceQuery
# A2S_INFO query. Returns a hashtable of server metadata
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'info'
# A2S_PLAYER query. Returns a hashtable of players
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'players'   #
# A2S_RULES query, Returns a hashtable of server cvars
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'rules'
# A2A_PING query. Returns a hashtable of whether the ping was successful
SourceQuery -Address $ip -Port $port -Engine 'Source' -Type 'ping'

# GoldSource Engine
Import-Module SourceQuery
# A2S_INFO query - Returns a hashtable of server metadata
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'info'
# A2S_PLAYER query. Returns a hashtable of players
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'players'
# A2S_RULES query, Returns a hashtable of server cvars
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'rules'
# A2A_PING query. Returns a hashtable of whether the ping was successful
SourceQuery -Address $ip -Port $port -Engine 'GoldSource' -Type 'ping'
```

### Rcon

```powershell
# Source Engine
Import-Module SourceRcon
SourceRcon -Address $ip -Port $port -Password $rcon_password -Command 'status'

# GoldSource Engine
Import-Module GoldsourceRcon
GoldsourceRcon -Address $ip -Port $port -Password $rcon_password -Command 'status'
```

### Debugging

Use the `-Verbose` switch to turn on verbose output.
