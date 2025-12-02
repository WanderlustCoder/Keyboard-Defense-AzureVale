# Difficulty Tuning with the Playtest Bot

Automated tuning loop for item **87** (Season 3 backlog). Use the playtest bot to gather runs, then generate recommendations that nudge dynamic difficulty, word weights, and spawn cadence. Target audience remains ages 8-16 on Edge/Chrome, single-player, free.

## Workflow
1. Ensure the dev server is running (`npm run start -- --no-build`).
2. Capture a few bot runs against the current build:
   - `npm run playtest:bot -- --duration 30000 --delay 30 --artifact artifacts/summaries/playtest-bot-01.json`
   - Vary delays/word sets to simulate different learners (e.g., `--delay 55` for younger players).
3. Generate tuning recommendations:
   - `npm run analytics:difficulty-tuning`
   - Outputs JSON: `artifacts/summaries/difficulty-tuning.json`
   - Outputs Markdown: `artifacts/summaries/difficulty-tuning.md`
4. Apply the suggestions manually:
   - `difficultyBiasDelta`: adjust the baseline dynamic difficulty bias (e.g., seed `state.typing.dynamicDifficultyBias`).
   - `wordWeightShifts`: redistribute `config.difficultyBands[*].wordWeights` by the indicated deltas, then renormalize to 1.0.
   - `spawnSpeedMultiplier`: multiply spawn cadence or enemy speed for the opening bands as a gentle pacing change.

## Recommendation Logic
- Targets 95% accuracy and ~45 WPM as a comfort zone for ages 8-16.
- High accuracy/WPM pushes bias up and shifts weight from easy to medium/hard.
- Low accuracy/WPM pulls bias down and shifts weight toward easy.
- Spawn multiplier mirrors the bias but stays within ±12% to avoid harsh swings.

## Tips
- Keep at least 3 bot runs per build before acting on the recommendations.
- Re-run after curriculum or wordlist changes; store artifacts under `artifacts/summaries/` for traceability.
- If the Markdown table shows frequent errors, fix stability first before tuning.
