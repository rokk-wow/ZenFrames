# Dev Notes (Core Basics)

This file is intentionally short so AI can load it quickly each session.

## Project Context
- WoW Beta addon development (12.0.x era behavior).
- Use `LibSAdCore` patterns first before inventing custom framework behavior.
- For deep details, check source docs when needed (for example `Libs/LibSAdCore/README.md`).

## Critical API Reality (Beta)
- See `.github/copilot-instructions.md` for the full secret value rules (auto-loaded by Copilot).
- TL;DR: secret values throw Lua exceptions on ANY operation — no compares, no storage, no concatenation. Use spell ID lookups, Blizzard's built-in aura filter APIs, or existing project patterns.

## Critical Information about fixing Bugs and Defects
- If you are requested to fix a bug or defect first analyze the problem
- If you are less than 95% confident in the resolution, you must gather more information
  - Ad print statements and ask the user to run the tests and give results
  - This gives you understanding of the actual problem and the ability to fix it
  - The more complicated the resolution, the more code changes, the more it means it's probably wrong. This should lower your confidence.
  - Never make code changes for bug fixes when you have low confidence in the resolution

## Critical information about functions, variables and scope
- We should always default to addon scoped functions and variables.
  - Using local functions and variables requires specific ordering and loading of files that is unnecessary
  - Addon scoped functions and variables do not give us much overhead and they allow us to freely access necessary items across files.
- Only use local functions and variables in very specific situations when the circumstances call for it.

## FStack Triage (When User Shares Screenshots)
- Find the mouse cursor first (the exact UI element in question).
- Check the `SOURCE` line to identify which Blizzard/AddOn frame created it.
- Confirm the exact frame container before editing (do not assume viewers/frames are interchangeable).

## SAdCore Coding Rules (Keep These)
- For every `addon.*` function:
  - First line: `callHook(self, "BeforeFunctionName", ...)`
  - Before every return: `callHook(self, "AfterFunctionName", returnValue)`
- Always return explicit values (`true`/`false`/actual value). Never return `nil`.
- Local/private functions are not bound by the `addon.*` hook rule.

## Localization + Messaging
- All user-facing info/error text must use localization via `self:L()`.
- Keep release/user messaging concise and readable.

## Edit Mode
- All edit mode code belongs in the `EditMode/` folder.
- No edit mode logic should live in other modules, settings, or ZenFrames.lua.
- There may be rare exceptions we can discuss on a case by case basis.
  - If we must make changes to code outside of the `EditMode/` folder, then we must do so in a specific way
    - We must allow inversion of control into the function. For example:
      - Good: We need to change display text hard coded into a method. We add a parameter into that method and allow the calling code to pass in the text. Now the original calling code can pass in the hard coded text and the Edit Mode code can pass in the text it needs to see. Now there is no code specific to edit mode but we've allowed edit mode to inject dependencies into the method.
      - Bad: We go into the method and add an if statement that says `if "editMode" then text = "editmodetext" else text = "hardcoded text" end. This is bad because we've added static code that is only relevant to Edit Mode.

## Code Style Essentials
- Favor self-documenting code and descriptive names.
- Keep comments minimal (only major section headers or required file headers).
- Prefer affirmative logic when practical.

## Preparing for a Release
To prepare for a release:
- Bump addon version in the `.toc` file:
  - Increase patch version for bug fixes
  - Increase minor version for normal changes that dont break backwards compatibility
  - Increase major version for major/breaking changes.
  - Check Announcement.lua and see if we need to update it with new patch notes
    - Title might need to be updated, the localization string might contain the previous version - title = "announcementTitle",
    - Patch notes should be brief and very high level. Players can find detailed patch notes on release site.
    - check ZenFrames.lua to see if version in show announcement needs to be updated - self:ShowAnnouncement("v2.0.0")
  - Check for unused localization strings and remove them
  - Verifiy all new localization strings are in place and have translations for the existing languages already translated for other strings




readycheck
