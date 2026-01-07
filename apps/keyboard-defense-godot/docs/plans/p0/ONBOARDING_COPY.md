# Onboarding Copy (P0-ONB-001)

This file contains exact tutorial panel copy. Keep step IDs and order aligned to `docs/plans/p0/ONBOARDING_PLAN.md`.

## Step 1: Welcome + focus
Title: Welcome to Keyboard Defense
Copy:
- This game is typing-first. Keep your hands on the keyboard.
- The command bar stays focused so you can act instantly.
- We will use short commands to learn the day and night loop.
Try this: help
Success: The log shows the help output.

## Step 2: Day actions primer
Title: Daytime actions
Copy:
- Daytime is for gathering, building, and exploring.
- Actions cost AP, so pick a small plan each day.
- Watch the log to confirm each command result.
Try this: gather wood 5, build farm, explore
Success: Resources change and a tile is discovered.

## Step 3: End day
Title: End the day
Copy:
- Ending the day starts the night wave.
- Production happens immediately when you end the day.
- A defend prompt will appear at night.
Try this: end
Success: Phase changes to night and a prompt appears.

## Step 4: Night typing
Title: Defend by typing
Copy:
- Each enemy has a word. Type the word to attack that enemy.
- Prefixes are safe; Enter only submits on a full match.
- Commands like status still work at night.
Try this: Type an enemy word from the wave list, then press Enter.
Success: The targeted enemy loses HP and the wave list updates.

## Step 5: Survive to dawn
Title: Reach dawn
Copy:
- Keep typing enemy words until the wave is cleared.
- If you need a pause, use wait to advance without a penalty.
- Dawn returns you to the day phase.
Try this: Defeat enemies until Dawn (or use wait if needed).
Success: Dawn is announced and the typing report appears.

## Step 6: Wrap-up
Title: Panels and replay
Copy:
- Lessons and settings are available any time.
- The tutorial can be replayed if you want a refresher.
- You can switch goals and lessons as you improve.
Try this: lessons, settings, tutorial
Success: Panels open and the tutorial controls are shown.

## String extraction considerations
- Keep each line short and self-contained for localization.
- Avoid punctuation that changes meaning in translation (prefer simple sentences).
- Keep commands in backticks when presenting them in UI.
- Do not embed dynamic values inside full sentences; use short labels.
