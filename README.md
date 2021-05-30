# PSSourceQuery

[![github-actions](https://github.com/theohbrothers/PSSourceQuery/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/PSSourceQuery/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/PSSourceQuery?style=flat-square)](https://github.com/theohbrothers/PSSourceQuery/releases/)
[![powershell-gallery-release](https://img.shields.io/powershellgallery/v/PSSourceQuery?logo=powershell&logoColor=white&label=PSGallery&labelColor=&style=flat-square)](https://www.powershellgallery.com/packages/PSSourceQuery/)


Powershell implementation of [SourceQuery](https://developer.valvesoftware.com/wiki/Server_queries) and [Rcon](https://developer.valvesoftware.com/wiki/Source_RCON_Protocol) for [Source](https://developer.valvesoftware.com/wiki/Source) and [Goldsource](https://developer.valvesoftware.com/wiki/Goldsource) games.

## Install

Open [`powershell`](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-5.1) or [`pwsh`](https://github.com/powershell/powershell#-powershell) and type:

```powershell
Install-Module -Name PSSourceQuery -Repository PSGallery -Scope CurrentUser -Verbose
```

If prompted to trust the repository, hit `Y` and `enter`.

## Usage

`-Address` may be a DNS or IP address.

`-Verbose` turns on verbose output for debugging.

### Query

```powershell
Import-Module PSSourceQuery

# Source Engine
# A2S_INFO query. Returns a hashtable of server metadata
SourceQuery -Address $address -Port $port -Engine 'Source' -Type 'info'
# A2S_PLAYER query. Returns a hashtable of players
SourceQuery -Address $address -Port $port -Engine 'Source' -Type 'players'
# A2S_RULES query, Returns a hashtable of server cvars
SourceQuery -Address $address -Port $port -Engine 'Source' -Type 'rules'
# A2A_PING query. Returns a hashtable of whether the ping was successful
SourceQuery -Address $address -Port $port -Engine 'Source' -Type 'ping'

# GoldSource Engine
# A2S_INFO query - Returns a hashtable of server metadata
SourceQuery -Address $address -Port $port -Engine 'GoldSource' -Type 'info'
# A2S_PLAYER query. Returns a hashtable of players
SourceQuery -Address $address -Port $port -Engine 'GoldSource' -Type 'players'
# A2S_RULES query, Returns a hashtable of server cvars
SourceQuery -Address $address -Port $port -Engine 'GoldSource' -Type 'rules'
# A2A_PING query. Returns a hashtable of whether the ping was successful
SourceQuery -Address $address -Port $port -Engine 'GoldSource' -Type 'ping'
```

### Rcon

```powershell
Import-Module PSSourceQuery

# Source Engine
SourceRcon -Address $address -Port $port -Password $rcon_password -Command 'status'

# GoldSource Engine
GoldsourceRcon -Address $address -Port $port -Password $rcon_password -Command 'status'
```

## FAQ

Q: Prerequisites?

- [`Powershell` v5](https://www.microsoft.com/en-us/download/details.aspx?id=50395) and later or [`Powershell Core`](https://github.com/powershell/powershell) (aka `pwsh`)

Q: Verified games?

Engine           |       Games
:---------------:|:---------------:
`Source` (`srcds`) | `left4dead2`, `csgo`, `hl2mp`
`Goldsource` (`hlds`) | `cstrike`, `czero`, `valve`. Should work for all `hlds` games.

The functions will probably work on a lot more games than those in the list.

## Notes

The functions are *stateless* - that is, `SourceQuery`, `SourceRcon`, and `GoldsourceRcon` are pure functions, storing no authentication or challenge states. This is to be expected for Source Queries, but not for Rcon. A possible future area of improvement would be to make `SourceRcon` and `GoldsourceRcon` construct and return a stateful Rcon object, that would improve client performance especially when multiple rcon commands need to be executed in sequence.
