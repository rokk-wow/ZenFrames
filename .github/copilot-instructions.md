# Copilot Instructions — ZenFrames (WoW Addon)

These rules are mandatory. Violations produce broken code that fails silently at runtime.

---

## CRITICAL: Secret Values — Hard Constraint

Modern WoW (12.0+) designates certain API return values as **secret/forbidden values**. A secret value **throws an immediate Lua exception** if you perform ANY operation on it:

- ❌ Compare it (`if secretVal == something`)
- ❌ Concatenate it (`"text" .. secretVal`)
- ❌ Store it in a variable for later use (`local x = secretVal`)
- ❌ Pass it to `print()`, `tostring()`, or string formatting
- ❌ Use it as a table key or value
- ❌ Pass it to any function that inspects its contents
- ❌ Use it in conditional logic of any kind

### What values are secret?

- Aura/buff/debuff names and spell names from combat-related APIs
- Spell IDs returned from certain combat/aura query functions
- Aura durations, expiration times, and counts in many contexts
- Targeting details and combat log payload values (source/dest names, GUIDs in combat contexts)
- Generally: any value Blizzard marks as restricted in the 12.0+ protected API surface

### What to do instead

- **Use spellId-based filtering** — compare known spell IDs you define yourself, never extract and compare names
- **Use Blizzard's built-in aura filter system** (`AuraUtil.ForEachAura` with filter strings, `UnitAura` index-based iteration with Blizzard's own filter callbacks)
- **Use framework-provided helpers** — `LibSAdCore` and `oUF` elements already handle secret values correctly
- **Check existing code patterns** in this project before writing new aura/combat logic — follow established conventions
- **If you are unsure whether a value is secret**: treat it as secret. Do not guess. Ask the user or search for how existing code handles the same data.

### What are the exceptions?

- Secret values may only be used when the code is **explicitly intended to run outside of combat** (e.g., configuration UI, out-of-combat inspection, auction house addon, in-game bank functionality). This is rare. **Always ask the user to confirm** that the use case is non-combat before writing any code that reads, stores, or manipulates a secret value.

### Why this matters

Secret value errors are **insidious** — they only trigger when the specific code path executes (e.g., a specific buff appears, a specific combat event fires). They pass casual testing and break in production. This is the #1 source of hard-to-find bugs in this project.

---

## Project Architecture

- This is a WoW addon built on the **oUF** unit frame framework with **LibSAdCore** as a shared utility library.
- Always check `LibSAdCore` patterns first before inventing custom solutions. See `Libs/LibSAdCore/README.md`.
- All edit mode code belongs in `EditMode/`. No edit mode logic in other modules (see dev-notes for rare exception rules).
- Configuration lives in `Config/` with per-content-type files (Arena, Raid, Party, etc.).

## SAdCore Hook Convention (Mandatory)

For every `addon.*` function:
- First line: `callHook(self, "BeforeFunctionName", ...)`  
- Before every return: `callHook(self, "AfterFunctionName", returnValue)`
- Always return explicit values (`true`/`false`/actual value). Never return `nil`.
- Local/private functions are exempt from this hook rule.

## Code Style

- Self-documenting code with descriptive names
- Minimal comments (major section headers or required file headers only)
- Prefer affirmative logic
- All user-facing text must use localization via `self:L()`

## Bug Fixing Protocol

- Analyze the problem before changing code
- If confidence < 95%, add print statements and ask the user to test — do not guess
- The more complex the proposed fix, the more likely it's wrong
- Never make speculative multi-file changes for bug fixes

## FStack Triage

When the user shares UI screenshots:
- Find the mouse cursor to identify the element
- Check the `SOURCE` line for the owning frame/addon
- Confirm the exact frame container before editing
