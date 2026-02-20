# SAdCore Style Guide

This document outlines the coding standards and requirements for the SAdCore framework.

## Tools and Linting

**LUA Helper by Tencent** is used to apply linting to LUA files. Ensure your code passes linting checks before committing.

## Scope

These constraints apply **ONLY** to `addon.*` functions (functions on the addon table). Local (private) functions are NOT subject to these requirements as they cannot be hooked by external addons.

## Critical Coding Constraints

### 1. Hook Requirement

Every `addon.*` function MUST include:
- `callHook(self, "BeforeFunctionName", ...)` as the first line
- `callHook(self, "AfterFunctionName", returnValue)` before EVERY return statement

### 2. Return Value Requirement

Every `addon.*` function MUST explicitly return a value:
- Success functions typically return `true` or the actual result
- Failed/error conditions MUST return `false` or the actual result (NEVER `nil`)
- NO function should end without an explicit return statement
- NEVER return `nil` - use `false` for failures, `true` for success, or actual data

### 3. Short-Circuit Returns

When returning early (error conditions, validation failures):
- MUST call the After hook with the return value
- MUST explicitly return that value (`false` for errors, never `nil`)

Example:
```lua
if not data then
    callHook(self, "AfterFunctionName", false)
    return false
end
```

### 4. Standard Function Pattern

```lua
function addon:FunctionName(params)
    callHook(self, "BeforeFunctionName", params)
    
    -- Early return example
    if errorCondition then
        callHook(self, "AfterFunctionName", false)
        return false
    end
    
    -- Function logic here
    
    local returnValue = true
    callHook(self, "AfterFunctionName", returnValue)
    return returnValue
end
```

## Example: Correct Initialize Section

```lua
do -- Initialize

    function addon:_Initialize(savedVarsGlobal, savedVarsPerChar)
        callHook(self, "BeforeInitialize", savedVarsGlobal, savedVarsPerChar)
        
        -- Initialization logic here
        
        local returnValue = true
        callHook(self, "AfterInitialize", returnValue)
        return returnValue
    end
end
```

## Localization Requirements

### All User-Facing Messages Must Use Localization

All `Info` and `Error` messages MUST use localization strings via `self:L()`:

**✅ Correct:**
```lua
self:Error(self:L("frameNotFound") .. ": " .. frameName)
self:Info(self:L("importSuccess"))
```

**❌ Incorrect:**
```lua
self:Error("Frame not found: " .. frameName)
self:Info("Import successful")
```

This ensures the framework can be localized for different languages.

### Tagline Translation Guidelines

The framework tagline "Simple Addons—Bare minimum addons for bare minimum brains." must follow specific translation rules:

**Critical Rules:**

1. **"Simple Addons" MUST remain in English** - This is the source of the "SAd" acronym and MUST NOT be translated
2. **Self-deprecating humor** - The tagline is intentionally self-deprecating and humorous in tone
3. **"brains" = intellectual capacity** - When translating "brains", use words that refer to intellectual capacity or mental ability, NOT the physical brain organ

**Translation Pattern:**
```
Simple Addons—[Minimal/bare minimum] [addons/extensions] for [minimal/bare minimum] [minds/intellects].
```

**Examples:**
- Spanish: "Simple Addons—Addons mínimos para mentes mínimas."
- Russian: "Simple Addons—Минимальные аддоны для минимального ума."
- French: "Simple Addons—Addons minimaux pour esprits minimaux."
- German: "Simple Addons—Minimale Addons für minimale Köpfe."

**Note:** "Simple Addons" staying in English preserves brand identity across all languages while the humor translates naturally.

## Code Comments

### Minimal Comments Philosophy

Code should be self-documenting. Comments should be rare and strategic.

### Allowed Comments

**Only the following types of comments are permitted:**

1. **Section Header Comments** - Large sections with `do` scopes:
   ```lua
   do -- Initialize
       -- functions here
   end
   
   do -- Settings Panels
       -- functions here
   end
   ```

2. **File Header Comments** - Copyright, license, and framework description at the top of files

### Prohibited Comments

**Do NOT use comments for:**
- Explaining what code does (write clearer code instead)
- TODO notes (use issue tracking)
- Inline explanations (refactor for clarity)
- Parameter documentation (use clear parameter names)

### Examples

**❌ Bad (over-commented):**
```lua
-- Set the width to 500
local width = 500

-- Loop through all items
for i = 1, #items do
    -- Get the current item
    local item = items[i]
    -- Process the item
    processItem(item)
end
```

**✅ Good (self-documenting):**
```lua
local defaultDialogWidth = 500

for _, item in ipairs(items) do
    processItem(item)
end
```

## Code Clarity

### Write Self-Explanatory Code

Scoped code should be written clearly enough that its purpose is understandable without comments.

**Strategies for self-documenting code:**
- Use descriptive variable names
- Use descriptive function names
- Keep functions small and focused
- Use meaningful constants instead of magic numbers
- Structure code logically

### Affirmative Logic Requirement

**All logic must be written in the affirmative case.** Avoid negative variable names and double negatives in conditionals.

**✅ Correct (affirmative):**
```lua
local visible = frame:IsVisible()
if visible then
    showFrame()
end

local enabled = GetSettingValue("feature")
if enabled then
    activateFeature()
end

local success = ProcessData(data)
if success then
    self:Info(self:L("operationSuccess"))
end
```

**❌ Incorrect (negative):**
```lua
local hidden = not frame:IsVisible()
if not hidden then
    showFrame()
end

local disabled = not GetSettingValue("feature")
if not disabled then
    activateFeature()
end

local failed = not ProcessData(data)
if not failed then
    self:Info(self:L("operationSuccess"))
end
```

**Rationale:** Double negatives (`if not hidden`, `if not disabled`) are harder to read and reason about. Affirmative logic makes code intention immediately clear and reduces cognitive load when reading conditions.

**Note:** This is a general rule. There are always exceptions. If the code becomes complex or harder to read because of trying to follow this rule, then it might be a valid exception. Use your judgment to prioritize overall code clarity.

### Developer Documentation Location

**Do NOT put developer documentation in code comments.**

Documentation for developers implementing or using SAdCore should go in:
- **README.md** - User guide, getting started, examples
- **API documentation** - Function signatures and usage
- **This style guide** - Coding standards and patterns

The main code should be clean and focused on implementation.

### Comment Policy

**Comments should be minimal and limited to simple section headers.**

**Permitted comments:**
- File header (at the very top of the file only): license, copyright, or brief file description
- Simple section headers for large code blocks: `-- Section Name` (e.g., `-- Russian`, `-- Utility Functions`)
- Block scope headers: `do -- Section Name` (as part of a `do` block declaration)

**PROHIBITED comments:**
- Explanatory comments describing what code does
- Usage examples in the code itself
- Multi-line documentation blocks within code
- Inline comments explaining behavior or logic
- Comments before or within functions explaining implementation
- Verbose or detailed comments within data structures

**Guidelines for section headers:**
- Keep them SHORT (1-3 words maximum)
- Use only for major sections that span many lines
- Do NOT use for small blocks of code
- Do NOT explain what the section does, just label it

**Examples:**

✅ **Good (permitted):**
```lua
-- French
SAdCore.prototype.locale.frFR = { ... }

do -- Zone Management
    function addon:RegisterZone() ... end
end
```

❌ **Bad (prohibited):**
```lua
-- This merges user-provided locale with default locale
for localeKey, prototypeLocale in pairs(...) do

-- Get the current value from saved variables
local value = self.savedVars[key]
```

**Rationale:** Developers will not be reading the framework code directly. Most comments are unnecessary noise that belongs in README.md or other documentation files. Code should be self-explanatory through clear naming and structure. Simple section headers are acceptable ONLY to organize very large sections of code (like localization tables or major functional blocks).

## Rationale

These constraints enable external addons to hook into ANY `addon.*` function's execution for monitoring, modification, or extension purposes. Failure to follow these patterns breaks the extensibility contract of the framework.

The minimal comments philosophy keeps the codebase clean, maintainable, and forces developers to write clear, understandable code rather than relying on comments as a crutch.
