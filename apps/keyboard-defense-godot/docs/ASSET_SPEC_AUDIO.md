# Audio Asset Specifications

## Design Philosophy
- **Responsive Feedback**: Every action has audio confirmation
- **Layered Soundscape**: Music, ambience, SFX coexist without mudding
- **Typing Rhythm**: Audio supports typing flow state
- **Accessibility**: Visual alternatives for all critical audio

---

## AUDIO STANDARDS

### File Formats
```
Music:      OGG Vorbis (looping)
SFX:        WAV (short), OGG (long)
Voice:      OGG Vorbis
Ambience:   OGG Vorbis (seamless loop)
```

### Quality Standards
```
Sample Rate:   44.1 kHz
Bit Depth:     16-bit (SFX), 24-bit (Music)
Channels:      Stereo (Music/Ambience), Mono (SFX)
Normalization: -3dB peak, -14 LUFS average
```

### File Size Budgets
```
Short SFX:     < 50 KB
Medium SFX:    < 150 KB
Long SFX:      < 500 KB
Music Track:   < 5 MB
Ambience Loop: < 2 MB
```

---

## AUDIO CATEGORIES

### Volume Hierarchy
```
Master:     100% (user adjustable)
├── Music:      70% default
├── SFX:        100% default
│   ├── Combat:     100%
│   ├── UI:         80%
│   └── Typing:     90%
├── Voice:      100% default
└── Ambience:   50% default
```

---

## MUSIC TRACKS

### Main Menu (music_menu)
```
Duration:   2-3 minutes (loop)
Mood:       Heroic, inviting, medieval fantasy
Tempo:      Medium (100-120 BPM)
Key:        Major (uplifting)
Instruments: Orchestral strings, brass fanfare, harp
```

**Structure**:
- Intro: 8 bars (can skip)
- Main theme: 16 bars
- Bridge: 8 bars
- Main theme variation: 16 bars
- Loop point: Seamless

---

### Gameplay - Peaceful (music_game_calm)
```
Duration:   3-4 minutes (loop)
Mood:       Focused, light tension, preparation
Tempo:      Medium-slow (80-100 BPM)
Use:        Between waves, low threat
Instruments: Soft strings, woodwinds, light percussion
```

---

### Gameplay - Battle (music_game_battle)
```
Duration:   2-3 minutes (loop)
Mood:       Urgent, exciting, heroic
Tempo:      Fast (120-140 BPM)
Use:        Active combat, waves in progress
Instruments: Full orchestra, driving percussion, brass
```

**Dynamic Layers**:
- Base: Percussion, bass
- Layer 1: Strings (add at wave start)
- Layer 2: Brass (add at 50% enemies)
- Layer 3: Full orchestra (boss/intense moments)

---

### Gameplay - Intense (music_game_intense)
```
Duration:   2 minutes (loop)
Mood:       Critical danger, desperate
Tempo:      Very fast (140-160 BPM)
Use:        Castle low HP, overwhelming enemies
Instruments: Aggressive percussion, dissonant strings
```

---

### Boss Battle (music_boss)
```
Duration:   3-4 minutes (loop)
Mood:       Epic, threatening, climactic
Tempo:      Variable (dramatic shifts)
Use:        Boss encounters
Instruments: Full orchestra, choir hits, unique motif per boss
```

**Boss Themes**:
- The Tyrant: Heavy brass, war drums
- The Witch Queen: Eerie choir, dark strings
- The Dragon King: Full orchestra, fire motifs

---

### Victory (music_victory)
```
Duration:   30-45 seconds (one-shot)
Mood:       Triumphant, celebratory
Tempo:      Medium-fast (110-130 BPM)
Use:        Wave complete, level complete
Instruments: Fanfare brass, celebratory percussion
```

---

### Defeat (music_defeat)
```
Duration:   15-20 seconds (one-shot)
Mood:       Somber, reflective (not punishing)
Tempo:      Slow (60-80 BPM)
Use:        Game over
Instruments: Soft strings, minor key resolution
```

---

### Tutorial (music_tutorial)
```
Duration:   2-3 minutes (loop)
Mood:       Encouraging, light, instructional
Tempo:      Medium (90-100 BPM)
Use:        Tutorial sequences
Instruments: Friendly woodwinds, plucky strings
```

---

### Kingdom Map (music_map)
```
Duration:   2-3 minutes (loop)
Mood:       Adventurous, exploratory
Tempo:      Medium (100-110 BPM)
Use:        Level select, kingdom overview
Instruments: Adventure strings, travel percussion
```

---

## SOUND EFFECTS

### Typing Sounds

#### Key Press (sfx_key_press)
```
Duration:   50-100ms
Variations: 5 (prevent repetition)
Character:  Mechanical keyboard click
Pitch:      Consistent, satisfying
Volume:     Moderate (not fatiguing over time)
```

#### Key Correct (sfx_key_correct)
```
Duration:   100ms
Character:  Soft chime, positive
Pitch:      High, pleasant
Trigger:    Each correct keystroke
```

#### Key Wrong (sfx_key_wrong)
```
Duration:   150ms
Character:  Soft buzz, not harsh
Pitch:      Low, distinct from correct
Trigger:    Typo entered
```

#### Word Complete (sfx_word_complete)
```
Duration:   300ms
Character:  Satisfying ding, sparkle
Pitch:      Rising, celebratory
Trigger:    Word fully typed
```

#### Perfect Word (sfx_word_perfect)
```
Duration:   400ms
Character:  Enhanced ding, magical chime
Pitch:      Higher, more elaborate
Trigger:    100% accuracy word
```

#### Word Failed (sfx_word_failed)
```
Duration:   300ms
Character:  Deflating sound
Pitch:      Falling, minor
Trigger:    Word times out or enemy reaches castle
```

---

### Combo Sounds

#### Combo Up (sfx_combo_up)
```
Duration:   200ms
Character:  Rising pitch chime
Pitch:      Increases with combo level
Variations: x2, x3, x5, x10 (escalating intensity)
```

#### Combo Milestone (sfx_combo_milestone)
```
Duration:   500ms
Character:  Fanfare burst
Trigger:    x5, x10, x15, x20
Pitch:      Higher for higher combos
```

#### Combo Drop (sfx_combo_drop)
```
Duration:   300ms
Character:  Glass break, deflation
Pitch:      Falling
Trigger:    Combo timer expires
```

---

### Combat Sounds

#### Tower Attacks

##### Arrow Fire (sfx_tower_arrow_fire)
```
Duration:   150ms
Character:  Bow twang, arrow whoosh
Variations: 3
```

##### Cannon Fire (sfx_tower_cannon_fire)
```
Duration:   400ms
Character:  Boom, rumble
Bass:       Heavy low end
Variations: 2
```

##### Fire Tower (sfx_tower_fire_fire)
```
Duration:   300ms
Character:  Woosh, crackle
Layered:    Fire burst + sizzle
```

##### Ice Tower (sfx_tower_ice_fire)
```
Duration:   300ms
Character:  Crystalline chime, frost
Layered:    Ice formation + wind
```

##### Lightning Tower (sfx_tower_lightning_fire)
```
Duration:   250ms
Character:  Electric zap, crackle
Layered:    Charge + discharge
```

##### Poison Tower (sfx_tower_poison_fire)
```
Duration:   300ms
Character:  Splurt, bubble
Layered:    Launch + sizzle
```

##### Support Tower (sfx_tower_support_pulse)
```
Duration:   400ms
Character:  Magical chime, warm
Layered:    Pulse + sparkle
```

---

#### Projectile Impacts

##### Arrow Impact (sfx_impact_arrow)
```
Duration:   100ms
Character:  Thunk, stick
```

##### Explosion Impact (sfx_impact_explosion)
```
Duration:   500ms
Character:  Boom, debris
Bass:       Heavy
```

##### Fire Impact (sfx_impact_fire)
```
Duration:   300ms
Character:  Burst, sizzle
```

##### Ice Impact (sfx_impact_ice)
```
Duration:   300ms
Character:  Shatter, freeze
Crystalline: High frequencies
```

##### Lightning Impact (sfx_impact_lightning)
```
Duration:   200ms
Character:  Crack, thunder
```

##### Poison Impact (sfx_impact_poison)
```
Duration:   300ms
Character:  Splat, bubble hiss
```

---

#### Enemy Sounds

##### Enemy Spawn (sfx_enemy_spawn)
```
Duration:   300ms
Character:  Dark woosh, portal
Variations: 3
```

##### Enemy Hit (sfx_enemy_hit)
```
Duration:   150ms
Character:  Impact thud
Variations: 5
```

##### Enemy Death (sfx_enemy_death)
```
Duration:   400ms
Character:  Defeat sound, dispersal
Variations: 4
```

##### Elite Enemy Spawn (sfx_elite_spawn)
```
Duration:   500ms
Character:  Enhanced spawn, warning tone
```

##### Elite Enemy Death (sfx_elite_death)
```
Duration:   600ms
Character:  Dramatic defeat, loot sparkle
```

##### Boss Spawn (sfx_boss_spawn)
```
Duration:   2000ms
Character:  Epic entrance, ground shake
```

##### Boss Death (sfx_boss_death)
```
Duration:   3000ms
Character:  Dramatic defeat, victory swell
```

---

### Castle Sounds

#### Castle Hit (sfx_castle_hit)
```
Duration:   400ms
Character:  Stone impact, damage
Layered:    Impact + crumble
```

#### Castle Critical (sfx_castle_critical)
```
Duration:   600ms
Character:  Major damage, alarm element
Layered:    Heavy impact + warning
```

#### Castle Repair (sfx_castle_repair)
```
Duration:   400ms
Character:  Stone reform, magical
Layered:    Repair + sparkle
```

---

### UI Sounds

#### Button Click (sfx_ui_click)
```
Duration:   50ms
Character:  Soft click
```

#### Button Hover (sfx_ui_hover)
```
Duration:   30ms
Character:  Subtle tick
```

#### Menu Open (sfx_ui_menu_open)
```
Duration:   200ms
Character:  Whoosh, unfold
```

#### Menu Close (sfx_ui_menu_close)
```
Duration:   150ms
Character:  Whoosh, fold
```

#### Toggle On (sfx_ui_toggle_on)
```
Duration:   100ms
Character:  Click, positive
```

#### Toggle Off (sfx_ui_toggle_off)
```
Duration:   100ms
Character:  Click, neutral
```

#### Error/Invalid (sfx_ui_error)
```
Duration:   200ms
Character:  Soft buzz, denied
```

#### Confirm/Success (sfx_ui_success)
```
Duration:   200ms
Character:  Positive chime
```

#### Notification (sfx_ui_notification)
```
Duration:   300ms
Character:  Alert chime
```

---

### Reward Sounds

#### Gold Pickup (sfx_gold_pickup)
```
Duration:   200ms
Character:  Coin clink
Variations: 3
```

#### Gold Burst (sfx_gold_burst)
```
Duration:   500ms
Character:  Multiple coins, shower
```

#### XP Gain (sfx_xp_gain)
```
Duration:   200ms
Character:  Soft chime, accumulate
```

#### Level Up (sfx_level_up)
```
Duration:   1000ms
Character:  Fanfare, celebration
```

#### Achievement Unlock (sfx_achievement)
```
Duration:   800ms
Character:  Grand chime, special
```

---

### Tower Building

#### Tower Place (sfx_tower_place)
```
Duration:   400ms
Character:  Construction, settle
```

#### Tower Upgrade (sfx_tower_upgrade)
```
Duration:   600ms
Character:  Enhancement, power up
Layered:    Build + magical
```

#### Tower Sell (sfx_tower_sell)
```
Duration:   300ms
Character:  Coins, deconstruct
```

---

## VOICE LINES

### Mentor - Lyra

#### Greetings
```
"Welcome back, student!"
"Ready to practice?"
"Let's improve those typing skills!"
```

#### Encouragement
```
"Excellent typing!"
"You're getting faster!"
"Keep up the great work!"
"Perfect accuracy!"
```

#### Hints
```
"Remember to use your home row."
"Watch your finger placement."
"Take your time, accuracy matters."
```

#### Tutorial
```
"Type the words to defeat enemies."
"Build towers to defend your castle."
"Higher combos mean more points!"
```

---

### Mentor - Kael

#### Battle Start
```
"The enemy approaches!"
"Prepare the defenses!"
"Hold the line!"
```

#### Combat
```
"Well struck!"
"They're breaking through!"
"Reinforce that position!"
```

#### Victory
```
"Victory is ours!"
"The kingdom is safe!"
"Well fought!"
```

---

### Enemy Taunts

#### Generic
```
"Your castle will fall!"
"You cannot stop us!"
"Prepare to be defeated!"
```

#### Boss - Tyrant
```
"I will crush your defenses!"
"Bow before your conqueror!"
"This kingdom is mine!"
```

#### Boss - Witch Queen
```
"Your spells are weak!"
"Darkness consumes all!"
"Join my eternal army!"
```

#### Boss - Dragon King
```
"Burn in my flames!"
"I am the end of all!"
"Tremble before the dragon!"
```

---

## AMBIENCE

### Forest Ambience (amb_forest)
```
Duration:   60 seconds (seamless loop)
Elements:   Birds, wind, rustling leaves
Mood:       Peaceful, natural
Use:        Forest biome, calm moments
```

### Castle Ambience (amb_castle)
```
Duration:   45 seconds (seamless loop)
Elements:   Distant activity, flags flapping, stone echo
Mood:       Medieval, fortified
Use:        Castle interior, menus
```

### Battle Ambience (amb_battle)
```
Duration:   30 seconds (seamless loop)
Elements:   Distant combat, war drums, tension
Mood:       Urgent, dangerous
Use:        Layered during combat
```

### Night Ambience (amb_night)
```
Duration:   60 seconds (seamless loop)
Elements:   Crickets, owl, wind
Mood:       Quiet, mysterious
Use:        Night levels
```

### Storm Ambience (amb_storm)
```
Duration:   45 seconds (seamless loop)
Elements:   Rain, thunder, wind
Mood:       Dramatic, intense
Use:        Storm weather, boss fights
```

---

## AUDIO DUCKING

### Priority System
```
Priority 1: Voice lines (duck all else by 50%)
Priority 2: Critical SFX (castle damage, boss spawn)
Priority 3: Music
Priority 4: Combat SFX
Priority 5: Ambience
Priority 6: UI SFX
```

### Ducking Rules
```
On Voice:     Music -6dB, SFX -3dB
On Critical:  Music -3dB
On Pause:     Music -6dB, fade to menu music
```

---

## RATE LIMITING

### Prevent Audio Spam
```
Same SFX:           Min 50ms between plays
Similar SFX:        Min 30ms between plays
Maximum Concurrent: 16 sounds
Maximum Same Type:  4 instances
```

### Typing Audio
```
Key Press:    No limit (core feedback)
Key Correct:  Max 10/second
Key Wrong:    Max 5/second
Word Complete: Max 3/second
```

---

## ACCESSIBILITY

### Audio Alternatives
Every critical audio cue must have visual alternative:
- Enemy spawn: Visual warning indicator
- Castle damage: Screen flash, HP bar
- Combo sounds: Visual combo display
- Achievement: Toast notification

### Audio Description
- Option for voice descriptions of visual events
- Sound effects described in subtitles
- Music mood indicated textually

### Mono Audio Option
- Full mix available in mono
- Important directional cues have visual backup

---

## IMPLEMENTATION NOTES

### Audio Bus Structure
```
Master
├── Music
│   ├── Menu Music
│   ├── Gameplay Music
│   └── Boss Music
├── SFX
│   ├── Combat
│   │   ├── Towers
│   │   ├── Enemies
│   │   └── Impacts
│   ├── Typing
│   ├── UI
│   └── Rewards
├── Voice
│   ├── Mentors
│   └── Enemies
└── Ambience
    ├── Environment
    └── Weather
```

### Crossfade Settings
```
Music transitions:    2000ms crossfade
Ambience transitions: 3000ms crossfade
Combat intensity:     500ms layer blend
```

### Randomization
- Pitch variation: ±5% on SFX
- Volume variation: ±10% on repeated sounds
- Random selection from variation pools

---

## ASSET NAMING

```
audio/
├── music/
│   ├── music_menu.ogg
│   ├── music_game_calm.ogg
│   ├── music_game_battle.ogg
│   └── music_boss_tyrant.ogg
├── sfx/
│   ├── combat/
│   │   ├── sfx_tower_arrow_fire_01.wav
│   │   └── sfx_impact_explosion.wav
│   ├── typing/
│   │   ├── sfx_key_press_01.wav
│   │   └── sfx_word_complete.wav
│   ├── ui/
│   │   └── sfx_ui_click.wav
│   └── rewards/
│       └── sfx_gold_pickup_01.wav
├── voice/
│   ├── lyra/
│   │   └── voice_lyra_greeting_01.ogg
│   └── enemies/
│       └── voice_boss_tyrant_taunt_01.ogg
└── ambience/
    ├── amb_forest.ogg
    └── amb_battle.ogg
```

