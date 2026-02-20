# Custom Config

Custom Config lets you override the entire ZenFrames configuration with a hand-edited Lua table. When a custom config is active, it **completely replaces** all settings — the normal settings panels have no effect.

## How It Works

1. Open **ZenFrames Settings > Custom Config**
2. Click **Get Current Config** to get a copy of your current resolved config
3. Copy the output, paste it into a text editor, and make your changes
4. Paste the modified config back into the Custom Config text box
5. Click **Apply** — this saves the config and reloads the UI

To remove a custom config, click **Remove Custom Config**. This clears the override and reloads using normal settings.

## Important Notes

- The custom config must be a valid Lua table (curly braces, commas, proper quoting).
- Text tags in `format` fields use oUF tag syntax — see [TextTags.md](TextTags.md).
- Colors are hex strings — `"RRGGBB"` or `"RRGGBBAA"` (no `#` prefix).
- Anchoring uses WoW anchor points: `TOP`, `BOTTOM`, `LEFT`, `RIGHT`, `CENTER`, `TOPLEFT`, `TOPRIGHT`, `BOTTOMLEFT`, `BOTTOMRIGHT`.
- `relativeTo` references a frame by its global name string (e.g. `"frmdPlayerFrame"`, `"UIParent"`, `"MainActionBar"`).
- Textures reference registered SharedMedia names (e.g. `"smooth"`, `"minimalist"`).
- Boolean values: `true` / `false` (no quotes).

---

# Config Structure

The config is a single table with these top-level keys:

| Key | Description |
|---|---|
| `global` | Shared settings: font, colors, spec abbreviations |
| `player` | Player unit frame |
| `target` | Target unit frame |
| `targetTarget` | Target-of-target unit frame |
| `focus` | Focus unit frame |
| `focusTarget` | Focus target unit frame |
| `pet` | Pet unit frame |
| `party` | Party group frames |
| `arena` | Arena group frames |
| `auraFilterDebug` | Aura filter debug overlay |

---

# Global

Shared settings referenced by all frames.

| Key | Type | Description |
|---|---|---|
| `font` | string | SharedMedia font name |
| `refreshDelay` | number | Seconds between tag/update refreshes |
| `manaColor` | hex | Mana bar color |
| `rageColor` | hex | Rage bar color |
| `focusColor` | hex | Focus bar color |
| `energyColor` | hex | Energy bar color |
| `runicPowerColor` | hex | Runic power bar color |
| `lunarPowerColor` | hex | Lunar power bar color |
| `comboPointColor` | hex | Combo point color |
| `runesColor` | hex | Runes color |
| `hostileColor` | hex | Hostile unit reaction color |
| `neutralColor` | hex | Neutral unit reaction color |
| `friendlyColor` | hex | Friendly unit reaction color |
| `highlightColor` | hex | Target highlight border color |
| `castbarColor` | hex | Castbar normal cast color |
| `castbarChannelColor` | hex | Castbar channel color |
| `castbarNonInterruptibleColor` | hex | Non-interruptible cast color |
| `castbarEmpowerColor` | hex | Empowered cast color |
| `dispelColors` | table | Per-type dispel highlight colors: `Magic`, `Curse`, `Disease`, `Poison`, `Bleed`, `Enrage`, `default` |
| `roleIcons` | table | Atlas names per role: `TANK`, `HEALER`, `DAMAGER` |
| `specAbbrevById` | table | Spec ID → abbreviation string map (e.g. `[71] = "ARMS"`) |

---

# Unit Frames

Unit frames (`player`, `target`, `targetTarget`, `focus`, `focusTarget`, `pet`) share a common structure.

## Frame Settings

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Show this frame |
| `hideBlizzard` | bool | Hide the default Blizzard frame |
| `frameName` | string | Global frame name (used for anchoring) |
| `anchor` | string | Anchor point on this frame |
| `relativeTo` | string | Frame to anchor to |
| `relativePoint` | string | Anchor point on the target frame |
| `offsetX` | number | Horizontal offset |
| `offsetY` | number | Vertical offset |
| `width` | number | Frame width |
| `height` | number | Frame height |
| `backgroundColor` | hex | Background color (RRGGBBAA) |
| `borderWidth` | number | Border thickness |
| `borderColor` | hex | Border color (RRGGBBAA) |

## Modules

Each unit frame has a `modules` table containing its enabled modules. Not all frames use all modules — smaller frames typically only have `health` and `text`.

---

# Group Frames

Group frames (`party`, `arena`) use a container-based layout to hold multiple unit sub-frames.

## Container Settings

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Show this group |
| `hideBlizzard` | bool | Hide the default Blizzard frames |
| `frameName` | string | Container frame name |
| `anchor` / `relativeTo` / `relativePoint` | string | Container anchoring |
| `offsetX` / `offsetY` | number | Container offset |
| `containerBackgroundColor` | hex | Container background (RRGGBBAA) |
| `containerBorderWidth` | number | Container border thickness |
| `containerBorderColor` | hex | Container border color |
| `maxUnits` | number | Maximum units shown |
| `perRow` | number | Units per row |
| `spacingX` / `spacingY` | number | Spacing between units |
| `growthX` | string | Horizontal growth: `"LEFT"` or `"RIGHT"` |
| `growthY` | string | Vertical growth: `"UP"` or `"DOWN"` |
| `unitWidth` / `unitHeight` | number | Individual unit frame size |
| `unitBackgroundColor` | hex | Unit background (RRGGBBAA) |
| `unitBorderWidth` / `unitBorderColor` | number/hex | Unit border |
| `highlightSelected` | bool | Highlight your current target in the group |

## Modules

Group frames support all the modules that unit frames do, plus additional group-specific modules listed below.

---

# Modules Reference

## health

Health status bar.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable health bar |
| `frameName` | string | Frame name (optional on group frames) |
| `texture` | string | SharedMedia statusbar texture name |
| `height` | number | Bar height (standalone frames) |
| `color` | string | `"class"` for class/reaction coloring, or a hex color |
| `anchor` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

## power

Power (mana/energy/rage/etc.) status bar, colored by power type.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable power bar |
| `texture` | string | StatusBar texture name |
| `height` | number | Bar height |
| `adjustHealthbarHeight` | bool | Shrink health bar to fit power bar |
| `onlyHealer` | bool | Only show for healer-role units |
| `borderWidth` / `borderColor` | number/hex | Border styling |
| `anchor` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

## text

Array of text elements displayed on the frame. Each entry is a separate font string.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Show this text element |
| `format` | string | oUF tag string (see [TextTags.md](TextTags.md)) |
| `size` | number | Font size in points |
| `font` | string | Font override (optional, uses global font if omitted) |
| `color` | hex | Text color |
| `outline` | string | Font outline (default `"OUTLINE"`) |
| `shadow` | bool | Enable drop shadow |
| `justifyH` | string | Horizontal alignment override (`"LEFT"`, `"RIGHT"`, `"CENTER"`) |
| `anchor` / `relativeTo` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

## castbar

Cast bar with optional spell name, cast time, and icon.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable castbar |
| `width` / `height` | number | Bar dimensions |
| `texture` | string | StatusBar texture name |
| `showSpellName` | bool | Show spell name text |
| `textAlignment` | string | Spell name alignment: `"LEFT"`, `"CENTER"`, `"RIGHT"` |
| `textSize` | number | Override font size (optional) |
| `textPadding` | number | Text inset from bar edge |
| `showCastTime` | bool | Show remaining cast time |
| `showIcon` | bool | Show spell icon |
| `iconPosition` | string | `"LEFT"` or `"RIGHT"` |
| `backgroundColor` | hex | Bar background color (RRGGBBAA) |
| `borderWidth` / `borderColor` | number/hex | Border |
| `anchor` / `relativeTo` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

Colors are set globally via `castbarColor`, `castbarChannelColor`, `castbarNonInterruptibleColor`, and `castbarEmpowerColor`.

## absorbs

Absorb shield overlay on the health bar.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable absorb overlay |
| `texture` | string | Overlay texture name |
| `opacity` | number | Overlay opacity (0–1) |
| `maxAbsorbOverflow` | number | Max overflow ratio (1.0 = 100%) |

## auraFilters

Array of aura icon displays. Each entry is an independent filter group.

| Key | Type | Description |
|---|---|---|
| `name` | string | Unique identifier for this filter |
| `enabled` | bool | Enable this filter |
| `baseFilter` | string | `"HELPFUL"` (buffs) or `"HARMFUL"` (debuffs) |
| `subFilters` | array | Additional Blizzard filter tokens to include |
| `excludeSubFilters` | array | Filter tokens to exclude matching auras |
| `disableMouse` | bool | Disable tooltips/interaction |
| `iconSize` | number | Icon size in pixels |
| `maxIcons` | number | Maximum icons shown |
| `perRow` | number | Icons per row |
| `spacingX` / `spacingY` | number | Icon spacing |
| `growthX` | string | `"LEFT"` or `"RIGHT"` |
| `growthY` | string | `"UP"` or `"DOWN"` |
| `showSwipe` | bool | Show cooldown swipe animation |
| `showCooldownNumbers` | bool | Show cooldown number text |
| `tooltipAnchor` | string | Tooltip position (e.g. `"ANCHOR_BOTTOMLEFT"`) |
| `showGlow` | bool | Show proc glow on active auras |
| `glowColor` | hex | Glow color |
| `placeholderIcon` | string | Icon texture when slot is empty |
| `placeholderDesaturate` | bool | Desaturate placeholder icon |
| `placeholderColor` | hex | Placeholder tint (RRGGBBAA) |
| `containerBackgroundColor` | hex | Container background |
| `containerBorderWidth` / `containerBorderColor` | number/hex | Container border |
| `iconBorderWidth` / `iconBorderColor` | number/hex | Per-icon border |
| `relativeToModule` | string or array | Anchor relative to another module's frame |
| `anchor` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

### Valid subFilter / excludeSubFilter Tokens

| Token | Description |
|---|---|
| `CANCELABLE` | Auras the player can cancel |
| `NOT_CANCELABLE` | Auras the player cannot cancel |
| `RAID` | Dispellable debuffs (raid frame relevant) |
| `RAID_IN_COMBAT` | Raid-relevant auras, only during combat |
| `CROWD_CONTROL` | CC effects |
| `BIG_DEFENSIVE` | Major defensive cooldowns |
| `EXTERNAL_DEFENSIVE` | Externally-applied defensives |
| `IMPORTANT` | High-priority auras (also sorts to front) |
| `PLAYER` | Auras cast by the player |

## roleIcon

Group role icon (tank/healer/DPS).

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable role icon |
| `size` | number | Icon size |
| `desaturate` | bool | Desaturate the icon |
| `color` | hex | Vertex color tint |
| `defaultIcon` | string | Atlas to show when no role assigned |
| `defaultAlpha` | number | Opacity for the default icon |
| `anchor` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

Role atlas textures are defined in `global.roleIcons`.

## dispelHighlight

Highlights the unit frame border when the unit has a dispellable debuff.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable dispel highlighting |
| `borderWidth` | number | Highlight border thickness |

Colors are configured globally in `global.dispelColors`.

## trinket

PvP trinket cooldown tracker for arena opponents.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable trinket tracking |
| `iconSize` | number | Trinket icon size |
| `iconBorderWidth` / `iconBorderColor` | number/hex | Icon border |
| `frameBorderWidth` | number | Outer frame border |
| `showSwipe` | bool | Show cooldown swipe |
| `showCooldownNumbers` | bool | Show cooldown text |
| `cooldownDesaturate` | bool | Desaturate icon when on cooldown |
| `cooldownAlpha` | number | Icon opacity when on cooldown |
| `healerReduction` | number | Seconds to subtract from healer trinket CD (default 30) |
| `anchor` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

## arenaTargets

Colored indicator bars showing which enemies/allies are targeting this unit.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable target indicators |
| `mode` | string | `"enemy"` (show enemy targeters) or `"friendly"` (show friendly targeters) |
| `indicatorWidth` / `indicatorHeight` | number | Indicator bar dimensions |
| `spacing` | number | Space between indicators |
| `growDirection` | string | `"DOWN"`, `"UP"`, `"LEFT"`, `"RIGHT"` |
| `maxIndicators` | number | Maximum indicators shown |
| `borderWidth` / `borderColor` | number/hex | Indicator border |
| `containerBackgroundColor` | hex | Container background |
| `anchor` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

## drTracker

Diminishing returns tracker for arena opponents. Captures Blizzard's built-in DR tray.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable DR tracking |
| `iconSize` | number | DR icon size |
| `iconBorderWidth` / `iconBorderColor` | number/hex | Per-icon border |
| `maxIcons` | number | Maximum DR icons |
| `perRow` | number | Icons per row |
| `spacingX` / `spacingY` | number | Icon spacing |
| `growthX` / `growthY` | string | Growth direction |
| `showSwipe` | bool | Show cooldown swipe |
| `showCooldownNumbers` | bool | Show cooldown text |
| `containerBackgroundColor` | hex | Container background |
| `containerBorderWidth` / `containerBorderColor` | number/hex | Container border |
| `relativeToModule` | string or array | Anchor relative to another module's frame |
| `anchor` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

## combatIndicator

Shows an icon when the player is in combat.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable combat indicator |
| `atlasTexture` | string | Atlas texture name |
| `size` | number | Icon size |
| `strata` | string | Frame strata (e.g. `"LOW"`) |
| `anchor` / `relativeTo` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

## restingIndicator

Shows an icon when the player is in a rest area (inn/city). Hidden during combat.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable resting indicator |
| `atlasTexture` | string | Atlas texture name |
| `size` | number | Icon size |
| `strata` | string | Frame strata |
| `anchor` / `relativeTo` / `relativePoint` / `offsetX` / `offsetY` | | Positioning |

---

# auraFilterDebug

Debug overlay for inspecting aura filter behavior.

| Key | Type | Description |
|---|---|---|
| `enabled` | bool | Enable the debug overlay |
| `friendlyUnits` | array | Units to monitor for friendly auras (e.g. `{"player"}`) |
| `hostileUnits` | array | Units to monitor for hostile auras (e.g. `{"target"}`) |

## relativeToModule

Several modules support `relativeToModule` — this anchors the module relative to another module's frame instead of the parent unit frame. When set to an array, it chains: the module anchors to the first module in the list that exists and is visible.

```lua
relativeToModule = "Health"                                    -- anchor to Health module
relativeToModule = {"ArenaDefensives", "ArenaCrowdControl"}    -- chain fallback
```
