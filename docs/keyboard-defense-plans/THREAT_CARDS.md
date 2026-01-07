# Battle interventions spec (typing prompts)

Battle interventions are short, targeted typing prompts that change the flow of
combat. They are conceptually similar to threat cards but tuned for the current
battle drill model.

## Lifecycle
- Trigger -> present prompt -> resolve -> apply effect -> log result.

## Intervention types (prototype)
1. Breach Repair
   - Prompt: short (10-20 chars)
   - Effect: reduce threat and restore castle stability.
2. Volley
   - Prompt: medium (20-35 chars)
   - Effect: spawn a power shot, large threat relief.
3. Rally
   - Prompt: sentence (35-60 chars)
   - Effect: temporary buff to typing power.
4. Ward
   - Prompt: incantation with punctuation (later lessons)
   - Effect: temporary threat slow.
5. Reposition (rare)
   - Prompt: precise command
   - Effect: adjust battle pacing or swap drill focus.

## Scaling knobs
- Prompt length increases by campaign tier.
- Time pressure rises slowly; always allow accessibility overrides.
- Confusability rises with player mastery (more similar words).

## Fail policy
- Missing a prompt removes the positive effect.
- Avoid direct penalties on typo to protect learning motivation.
