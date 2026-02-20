# SAd - Simple Addons

SAdCore is a lightweight, embeddable framework for rapidly building simple addons with consistent options and controls. Define your checkboxes, dropdowns, sliders, and buttons, and the settings UI is automatically generated with values persisted to SavedVariables. Built-in features include settings import/export, profile management, and optional zone detection for addons that need zone-based behavior.

**Note:** SAdCore is a library, not a standalone addon. It's embedded within other addons (similar to Ace3, LibStub, etc.).

## The SAd Creed
SAddons are:
- **Easy.** If a configuration setting is more complicated than a single control, it's probably wrong
- **Simple.** If a user doesn't understand your configuration without additional instructions, it's probably wrong
- **Intuitive.** If a user can't remember where they saw a particular configuration setting, it's probably wrong
- **Relevant.** If a configuration setting doesn't directly relate to the name of the addon, it's probably wrong
- **Respectful.** If a users game setting is changed just by installing the addon, it's probably wrong
- **Affirmative.** Logic should always enable, not disable (a checkbox should "Show Map", not "Hide Map")
- **Robust.** All code exists inside scoped functions. No global code exists
- **On Time.** All code should run based on events, not timers
- **Exceptional.** All rules have exceptions, especially when writting addons for WoW 😂

## Installation

### Embedding SAdCore in Your Addon

1. **Clone or download this repository** into your addon's `Libs/LibSAdCore` folder:
   ```bash
   cd MyAddon/Libs
   git clone https://github.com/rokk-wow/LibSAdCore.git LibSAdCore
   ```

   Your addon structure should look like:
   ```
   MyAddon/
   ├── Libs/
   │   └── LibSAdCore/
   │       ├── LibSAdCore.lua
   │       ├── LibSAdCore.toc
   │       ├── Addon_Example.lua
   │       ├── README.md
   │       ├── STYLEGUIDE.md
   │       └── LICENSE
   ├── MyAddon.lua
   └── MyAddon.toc
   ```

2. **Update your `.toc` file** to load SAdCore:
   
   ```toc
   ## Interface: 120000
   ## Title: MyAddon
   ## Author: Your Name
   ## Version: 1.0
   ## SavedVariables: MyAddon_Settings_Global
   ## SavedVariablesPerCharacter: MyAddon_Settings_Char
   ## AddonCompartmentFunc: MyAddon_Compartment_Func
   ## IconTexture: Interface\Icons\boss_odunrunes_green

   Libs\LibSAdCore\LibSAdCore.lua

   MyAddon.lua
   ```

3. **Initialize the addon** in `MyAddon.lua`:
   ```lua
   local addonName = ...
   local SAdCore = LibStub("SAdCore-1")
   local addon = SAdCore:GetAddon(addonName)
   
   addon.sadCore.savedVarsGlobalName = "MyAddon_Settings_Global"
   addon.sadCore.savedVarsPerCharName = "MyAddon_Settings_Char"
   addon.sadCore.compartmentFuncName = "MyAddon_Compartment_Func"
   
   function addon:Initialize()
       self.author = "Your Name"
       
       -- Example - Add Settings to Main Settings Panel
       self:AddSettingsPanel("main", {
           controls = {
               {
                   type = "header",
                   name = "exampleHeader"
               },
               {
                   type = "checkbox",
                   name = "exampleCheckbox",
                   default = true,
                   onValueChange = self.exampleCheckbox
               }
           }
       })
       
       -- Example - Add a New Child Settings Panel
       self:AddSettingsPanel("examplePanel", {
           title = "examplePanelTitle",
           controls = {
               {
                   type = "header",
                   name = "examplePanelHeader"
               },
               {
                   type = "checkbox",
                   name = "examplePanelCheckbox",
                   default = true,
                   onValueChange = self.examplePanelCheckbox
               }
           }
       })
   end
   
   function addon:exampleCheckbox(isChecked)
       self:Debug(addonName .. ": " .. tostring(isChecked))
   end
   
   function addon:examplePanelCheckbox(isChecked)
       self:Info("Checkbox changed to: " .. tostring(isChecked))
   end
   
   -- Localization
   -- The locale table is automatically initialized by SAdCore
   addon.locale.enEN = {
       -- Main settings localization strings
       exampleTitle = "My Addon Settings",
       exampleHeader = "Example Settings",
       exampleCheckbox = "Example Checkbox on Main Settings",
       exampleCheckboxTooltip = "Tooltip for example checkbox control",
       
       -- Custom panel localization strings
       examplePanelTitle = "Example Panel Settings",
       examplePanelHeader = "Example Panel Header",
       examplePanelCheckbox = "Example Checkbox on Custom Panel",
       examplePanelCheckboxTooltip = "Tooltip for checkbox on the custom panel"
   }
   ```

## Example Controls

This example shows all available control types using the same naming convention and structure as `Addon_Example.lua`:

```lua
function addon:Initialize()
    self.author = "Your Name"
    
    -- Main Settings Panel
    self:AddSettingsPanel("main", {
        controls = {
            {
                type = "header",
                name = "mainHeader"
            },
            {
                type = "checkbox",
                name = "mainCheckbox",
                default = true,
                onValueChange = self.mainCheckbox
            }
        }
    })
    
    -- Child Settings Panel (shows all available control types)
    self:AddSettingsPanel("advancedPanel", {
        title = "advancedTitle",
        controls = {
            {
                type = "header",
                name = "advancedHeader"
            },
            {
                type = "checkbox",
                name = "advancedCheckbox",
                default = false,
                onValueChange = self.advancedCheckbox
            },
            {
                type = "dropdown",
                name = "advancedDropdown",
                default = "option2",
                options = {
                    {value = "option1", label = "dropdownOption1"},
                    {value = "option2", label = "dropdownOption2"},
                    {value = "option3", label = "dropdownOption3"}
                },
                onValueChange = self.advancedDropdown
            },
            {
                type = "slider",
                name = "advancedSlider",
                default = 50,
                min = 0,
                max = 100,
                step = 5,
                onValueChange = self.advancedSlider
            },
            {
                type = "colorPicker",
                name = "advancedColor",
                default = "#FFFFFF",
                onValueChange = self.advancedColor
            },
            {
                type = "inputBox",
                name = "advancedInput",
                default = "Enter text",
                buttonText = "advancedInputButton",
                onClick = self.advancedInputButton
            },
            {
                type = "button",
                name = "advancedButton",
                onClick = self.advancedButton
            },
            {
                type = "divider"
            },
            {
                type = "description",
                name = "advancedDescription"
            }
        }
    })
end

-- Callback Functions
function addon:mainCheckbox(isChecked)
    self:Debug("Main checkbox: " .. tostring(isChecked))
end

function addon:advancedCheckbox(isChecked)
    self:Info("Advanced checkbox: " .. tostring(isChecked))
end

function addon:advancedDropdown(selectedValue)
    self:Info("Dropdown selected: " .. selectedValue)
end

function addon:advancedSlider(value)
    self:Info("Slider value: " .. value)
end

function addon:advancedColor(hexColor)
    self:Info("Color changed: " .. hexColor)
end

function addon:advancedInputButton(inputText, editBox)
    self:Info("Input value: " .. inputText)
    editBox:SetText("")
end

function addon:advancedButton()
    self:Info("Button clicked!")
end

-- Localization
-- The locale table is automatically initialized by SAdCore
addon.locale.enEN = {
    -- Main panel
    mainHeader = "Main Settings",
    mainCheckbox = "Enable Main Feature",
    mainCheckboxTooltip = "Enable or disable the main feature",
    
    -- Advanced panel
    advancedTitle = "Advanced Settings",
    advancedHeader = "Advanced Options",
    advancedCheckbox = "Enable Advanced Mode",
    advancedCheckboxTooltip = "Enable advanced features",
    advancedDropdown = "Select Option",
    advancedDropdownTooltip = "Choose from available options",
    dropdownOption1 = "Option One",
    dropdownOption2 = "Option Two",
    dropdownOption3 = "Option Three",
    advancedSlider = "Adjust Value",
    advancedSliderTooltip = "Set the value between 0 and 100",
    advancedColor = "Choose Color",
    advancedColorTooltip = "Select a color with optional transparency",
    advancedInput = "Enter Text",
    advancedInputTooltip = "Type your text here",
    advancedInputButton = "Apply",
    advancedButton = "Click Me",
    advancedButtonTooltip = "Perform an action",
    advancedDescription = "This is a description that provides additional information to the user."
}
```

### Persistent vs Session-Only Controls

By default, all control values are automatically persisted to saved variables. If the user has selected the Global profile, values are saved to the global saved variables. If the user has selected the Character profile, values are saved to the character saved variables.

To create a control that only exists for the current game session (and is reset when the user logs out), set `sessionOnly = true`:

```lua
{
    type = "checkbox",
    name = "temporaryCheckbox",
    default = false,
    sessionOnly = true,  -- This value will NOT be persisted
    onValueChange = self.temporaryCheckbox
}
```

### Automatic Tooltips

To add a tooltip, define a localization key with the control's name + `"Tooltip"` (e.g., `"exampleCheckboxTooltip"` for `name = "exampleCheckbox"`).

### Dropdown Icons

Dropdown options support optional icons to provide visual previews. Icons can be atlas textures or file paths.

**Basic dropdown (no icons):**
```lua
{
    type = "dropdown",
    name = "myDropdown",
    default = "option1",
    options = {
        {value = "option1", label = "dropdownOption1"},
        {value = "option2", label = "dropdownOption2"}
    }
}
```

**Dropdown with icons:**
```lua
{
    type = "dropdown",
    name = "roleDropdown",
    default = "healer",
    options = {
        {value = "tank", label = "tankRole", icon = "roleicon-tiny-tank"},
        {value = "healer", label = "healerRole", icon = "roleicon-tiny-healer"},
        {value = "dps", label = "dpsRole", icon = "roleicon-tiny-dps"}
    }
}
```

Icons are displayed next to each option in the dropdown menu, making it easier for players to identify selections visually. If an icon is not provided for an option, it will display as text-only.

## Accessing Saved Settings

Control values are automatically persisted and can be accessed through `self.savedVars` organized by panel key. Access control values using `self.savedVars.panelKey.controlName`. Note that controls marked with `sessionOnly = true` will not be available in `self.savedVars` as they are not persisted.

**Example:**
```lua
function addon:PrintDebuggingStatus()
    if self.savedVars.main.enableDebugging then
        self:Info("Debugging is currently ENABLED")
    else
        self:Info("Debugging is currently DISABLED")
    end
end
```

### Safe Value Retrieval with `addon:GetValue()`

Use `addon:GetValue(panel, settingName)` to retrieve saved variables with validation. This protects against corrupted SavedVariables files by validating values against control definitions and returning the saved value, default value, or `nil`.

**Example:**
```lua
-- Direct access (no validation)
local enabled = self.savedVars.main.enableFeature
local scale = self.savedVars.main.uiScale
local icon = self.savedVars.main.selectIcon

-- Validated access (safe)
local enabled = self:GetValue("main", "enableFeature")  -- guaranteed boolean or nil
local scale = self:GetValue("main", "uiScale") or 1.0   -- guaranteed valid number or default
local icon = self:GetValue("main", "selectIcon")        -- guaranteed valid option or nil
```

### Setting Values with `addon:SetValue()`

Use `addon:SetValue(panel, settingName, value)` to programmatically update saved variables. This ensures the panel structure is initialized and returns `true` on success.

**Example:**
```lua
-- Set values programmatically
self:SetValue("main", "enableFeature", true)
self:SetValue("main", "uiScale", 1.5)
self:SetValue("options", "selectedMode", "advanced")
```

## Storing Custom Data

Need to save data without creating UI controls? Use the reserved `self.savedVars.data` namespace. This table is automatically initialized and included in saved variables, export/import, and profile switching.

**Example:**
```lua
-- Store arbitrary data
self.savedVars.data.lastLoginTime = time()
self.savedVars.data.playerStats = {
    kills = 0,
    deaths = 0,
    honor = 0
}

-- Retrieve data later
function addon:OnZoneChange(zone)
    local stats = self.savedVars.data.playerStats or {}
    stats.zonesVisited = stats.zonesVisited or {}
    stats.zonesVisited[zone] = true
end
```

**Note:** The `data` namespace is reserved for your use. Don't create panel keys named "data" to avoid conflicts.

## Adding New Lua Files

To add a new Lua file to the addon: add it to your `.toc` file, then include these three lines at the top:

```lua
local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)
```

## Localization

All user-facing text uses localization keys. This allows you to easily translate into other languages.
When you use `name = "exampleHeader"` in your control config, SAdCore automatically displays "My Settings". If a key is missing, it displays as `[keyName]` to alert you during development.

**Adding localized text:**

```lua
addon.locale.enEN = {
    keyName = "Your Text Here",
    exampleHeader = "My Settings",
    exampleCheckbox = "Enable Feature"
}
```

## Release Notes

Automatically display patch notes to users the first time they load after an update. Users can manually view release notes via the "Show Release Notes" button in settings.

Release notes are displayed once per version using `addon:Info()`. Users won't see them again unless they reset their SavedVariables. Manually display anytime with `addon:ShowReleaseNotes()`

**Example:**

```lua
-- Set version and release notes
addon.sadCore.releaseNotes = {
    version = "1.2.0",
    notes = {
        "releaseNote_feature1",
        "releaseNote_feature2",
        "releaseNote_bugfix1"
    }
}

-- Add localization strings
addon.locale.enEN = {
    releaseNote_feature1 = "Added new feature: Advanced role selection",
    releaseNote_feature2 = "Improved settings panel organization",
    releaseNote_bugfix1 = "Fixed: Settings not saving on logout"
}
```

## Slash Commands

Register custom slash commands using `self:RegisterSlashCommand(command, callback)`. Each command becomes its own slash command that accepts parameters.

**Example:**
```lua
function addon:Initialize()
    self.author = "Your Name"
    
    self:RegisterSlashCommand("hello", self.HelloCommand)
end

function addon:HelloCommand(message, name)
    self:Info("Hello, " .. (name or "World") .. "!")
end
```

**Usage:**
- `/hello` - Displays "Hello, World!"
- `/hello john` - Displays "Hello, john!"

## Event Registration

Register WoW events with `self:RegisterEvent(eventName, callback)`:

```lua
function addon:Initialize()
    self.author = "Your Name"
    
    -- Configure your settings panels here
    -- ...
    
    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD", self.OnPlayerEnteringWorld)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", self.OnEnterCombat)
    self:RegisterEvent("UNIT_HEALTH", self.OnUnitHealth)
end

function addon:OnPlayerEnteringWorld(event)
    self:Info("Player entered world")
end

function addon:OnEnterCombat(event)
    self:Info("Entering combat")
end

function addon:OnUnitHealth(event, unitID)
    if unitID == "player" then
        local health = UnitHealth("player")
        self:Debug("Health: " .. health)
    end
end
```

## Frame Event Registration

Register frame events (EventRegistry callbacks) with `self:RegisterFrameEvent(eventName, callback)`. Frame events use WoW's `EventRegistry` system and are commonly used for UI-related events like Edit Mode changes, layout updates, and other frame-specific callbacks. You can identify frame events from `/etrace` because they usually have the frame name separated from the event name with a `.` dot.

```lua
function addon:Initialize()
    self.author = "Your Name"
    
    -- Register frame events
    self:RegisterFrameEvent("EditMode.Enter", self.OnEditModeEnter)
    self:RegisterFrameEvent("EditMode.Exit", self.OnEditModeExit)
end

function addon:OnEditModeEnter()
    self:Info("Edit mode entered")
end

function addon:OnEditModeExit()
    self:Info("Edit mode exited")
end
```

## Combat-Safe Functions

Some WoW API calls cannot be made during combat (e.g., modifying secure frames, changing UI positions). SAdCore provides `CombatSafe()` to automatically queue actions during combat and execute them when combat ends.

### Example

```lua
function addon:UpdateFramePosition()
    self:CombatSafe(function()
        MyFrame:SetPoint("CENTER", 0, 100)
        MyFrame:Show()
    end)
end
```

If called during combat, the function is queued. When combat ends, it executes automatically. If called outside combat, it executes immediately.

## Secret-Safe Functions

Some WoW API calls return "secret values" in PvP contexts that cannot be used with UI operations. SAdCore provides `SecureCall()` to automatically replace secret values with `nil`.

### Example

```lua
function addon:UpdateArenaHealth()
    local health = self:SecureCall(UnitHealth, "arena1")
    if health then
        self:Info("Health: " .. health)
    end
end
```

Secret values are replaced with `nil`, safe values pass through unchanged. Supports up to 20 return values.

## Retry Functions

Some operations may fail temporarily and need to be retried (e.g., waiting for frames to load, API calls that return incomplete data). SAdCore provides `Retry()` to automatically retry a function until it succeeds or reaches the maximum retry limit. Retry will run the function after a short delay until the function either returns `true`, or the maximum retry count is reached.

### Syntax

```lua
self:Retry(func, initialWait)
```

**Parameters:**
- `func` (function) - The function to retry. Should return `true` when successful.
- `initialWait` (number, optional) - Seconds to wait before the first attempt. If omitted or `0`, executes immediately.

### Examples

```lua
-- Immediate execution (no initial wait)
function addon:WaitForFrame()
    self:Retry(function()
        if MyFrame and MyFrame:IsShown() then
            -- Frame is ready, do something
            MyFrame:SetAlpha(1.0)
            return true  -- Success! Stop retrying
        end
        -- Frame not ready yet, will retry
    end)
end

-- Wait 0.5 seconds before first attempt
function addon:DelayedCheck()
    self:Retry(function()
        if SomeGlobalVariable then
            -- Variable is available, proceed
            return true
        end
        -- Not ready, will retry
    end, 0.5)
end
```

## Zone Management

SAdCore provides automatic zone detection and callbacks. This feature is designed for addons that want to take advantage of zone-based behavior (like chat filters or UI visibility in different zones).

```lua
function addon:OnZoneChange(currentZone)
    -- Apply zone-specific logic here
end
```

### Supported Zones
- `"arena"` - Arena instances
- `"battleground"` - Battleground instances
- `"dungeon"` - Dungeon instances (5-player)
- `"raid"` - Raid instances
- `"world"` - Open world (default)


## Common API Functions

These are the most commonly used functions available on the `self` object within the addon methods:

### Logging
- **`self:Debug(text)`** - Only displays when "Enable Debugging" is enabled in settings
- **`self:Info(text)`** - Always displays (informational messages)
- **`self:Error(text)`** - Always displays (error messages)
- **`self:Dump(value, name)`** - Dumps a variable using DevTools_Dump for inspection (optional name parameter)

### Localization
- **`self:L(key)`** - Returns the localized string for the given key based on client language

### Events & Commands
- **`self:RegisterEvent(eventName, callback)`** - Register a WoW event with a callback function
- **`self:RegisterFrameEvent(eventName, callback)`** - Register a frame event (EventRegistry callback) with a callback function
- **`self:RegisterSlashCommand(command, callback)`** - Register a custom slash command (e.g., command="hello" creates /hello)

### Zone Detection
- **`self:GetCurrentZone()`** - Returns current zone: "arena", "battleground", "dungeon", "raid", or "world"
- **`addon:OnZoneChange(currentZone)`** - Override this hook to respond to zone changes (currentZone parameter passed automatically)

### Settings
- **`self:OpenSettings()`** - Opens the addon settings panel

### Combat & Safety Functions
- **`self:CombatSafe(func)`** - Queues a function to execute after combat ends (or immediately if not in combat)
- **`self:SecureCall(func, ...)`** - Calls a function and replaces any secret values in return values with `nil`
- **`self:Retry(func, initialWait)`** - Retries a function until it returns `true` or maximum attempts is reached. `initialWait` (optional) specifies seconds to wait before the first attempt.

### Color Utilities
- **`self:hexToRGB(hex)`** - Converts hex color string to RGB values (returns r, g, b, a)
- **`self:rgbToHex(r, g, b, a)`** - Converts RGB values to hex color string (returns hex string)

**Example:**
```lua
-- Convert hex to RGB
local r, g, b, a = self:hexToRGB("#FF5733FF")
-- Returns: 1.0, 0.341, 0.2, 1.0

-- Convert RGB to hex
local hexColor = self:rgbToHex(1.0, 0.341, 0.2, 1.0)
-- Returns: "#FF5733FF"
```

### Utilities
- **`self:ShowDialog(dialogOptions)`** - Display a custom dialog with optional controls
  - `dialogOptions` - A table containing:
    - `title` - The dialog title (localization key)
    - `controls` - Array of control configurations (optional)
    - `width` - Custom dialog width in pixels (optional, defaults to 500)
    - `height` - Custom dialog height in pixels (optional, auto-calculated based on content)
    - `onClose` - Callback function when dialog is closed (optional)

**Example:**
```lua
-- Simple dialog with just a title and close button
self:ShowDialog({
    title = "myDialogTitle"
})

-- Dialog with controls
self:ShowDialog({
    title = "myDialogTitle",
    controls = {
        {
            type = "inputBox",
            name = "userInput",
            default = "Enter text here",
            highlightText = true
        }
    },
    onClose = function()
        self:Info("Dialog closed")
    end
})
```


## Hooks

Every framework function has Before/After hooks for extending functionality.

**Before hooks** receive and must return parameters (can modify them):
```lua
function addon:BeforeL(key)
    return key:upper()  -- Modify parameter
end
```

**After hooks** receive return values (observation only):
```lua
function addon:AfterAddCheckbox(checkbox, newYOffset)
    checkbox:SetAlpha(0.9)  -- Customize the checkbox
end
```

All available hooks follow the pattern: `Before[FunctionName]` and `After[FunctionName]`. See `LibSAdCore.lua` for the complete list.
