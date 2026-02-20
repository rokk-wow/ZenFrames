# Text Tag Reference

Tags are enclosed in square brackets and combined with literal text.

## Syntax

| Example | Output |
|---|---|
| `[name]` | Full unit name |
| `[perhp]%` | 85% |
| `[curhp:short] / [maxhp:short]` | 245K / 300K |
| `[raidcolor][name:medium]\|r` | Class-colored name |

**Optional prefix/suffix** (shown only if the tag returns a value):

| Example | Output |
|---|---|
| `[==$>name<$==]` | ==Thrall== |
| `[perhp<$%]` | 85% |

---

## Name Tags

| Tag | Description |
|---|---|
| `[name]` | Full name |
| `[name:short]` | Short name |
| `[name:medium]` | Medium name |
| `[name:long]` | Long name |
| `[name:abbrev]` | Abbreviated name |
| `[name:trunc(12)]` | Truncated to 12 characters |

## Health Tags

| Tag | Description |
|---|---|
| `[curhp]` | Current HP (raw number) |
| `[maxhp]` | Max HP (raw number) |
| `[perhp]` | Health percent (e.g. 85) |
| `[missinghp]` | Missing HP |
| `[curhp:short]` | Current HP abbreviated (245K) |
| `[maxhp:short]` | Max HP abbreviated (300K) |
| `[hp:percent]` | Health percent with % (85%) |
| `[hp:cur-percent]` | 245K - 85% |
| `[hp:cur-max]` | 245K / 300K |
| `[hp:deficit]` | Missing HP as -245K |

## Power Tags

| Tag | Description |
|---|---|
| `[curpp]` | Current power (raw) |
| `[maxpp]` | Max power (raw) |
| `[perpp]` | Power percent |
| `[curpp:short]` | Current power abbreviated |
| `[maxpp:short]` | Max power abbreviated |
| `[pp:percent]` | Power percent with % |
| `[pp:cur-percent]` | Current - percent% |
| `[pp:cur-max]` | Current / Max |

## Info Tags

| Tag | Description |
|---|---|
| `[level]` | Unit level |
| `[smartlevel]` | Level with elite/boss indicator |
| `[class]` | Class name |
| `[smartclass]` | Class (players) or creature type (NPCs) |
| `[spec]` | Spec abbreviation (e.g. ARMS, RESTO) |
| `[race]` | Race name |
| `[creature]` | Creature family or type |
| `[faction]` | Faction name |
| `[group]` | Raid group number |

## Status Tags

| Tag | Description |
|---|---|
| `[dead]` | Dead or Ghost |
| `[offline]` | Offline if disconnected |
| `[status]` | Dead / Ghost / Offline / zzz |
| `[resting]` | zzz if resting |
| `[pvp]` | PvP if flagged |
| `[leader]` | L if group leader |
| `[sex]` | Male / Female |

## Color Tags

| Tag | Description |
|---|---|
| `[raidcolor]` | Class color hex (use before name, `\|r` after) |
| `[powercolor]` | Power type color hex |
| `[threatcolor]` | Threat level color hex |

## Classification Tags

| Tag | Description |
|---|---|
| `[classification]` | Rare / Rare Elite / Elite / Boss |
| `[shortclassification]` | R / R+ / + / B / - |
| `[threat]` | Aggro / ++ / -- |
