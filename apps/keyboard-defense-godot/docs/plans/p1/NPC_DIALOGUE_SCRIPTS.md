# NPC Dialogue Scripts - Complete Collection

**Last updated:** 2026-01-08

This document contains the complete dialogue scripts for all NPCs in Keyboard Defense, including conversation trees, shop dialogue, quest dialogue, and contextual responses.

---

## Table of Contents

1. [Dialogue System Overview](#dialogue-system-overview)
2. [Tutorial NPCs](#tutorial-npcs)
3. [Village NPCs](#village-npcs)
4. [Merchant NPCs](#merchant-npcs)
5. [Quest Giver NPCs](#quest-giver-npcs)
6. [Regional NPCs](#regional-npcs)
7. [Boss Pre-Fight Dialogue](#boss-pre-fight-dialogue)
8. [Ambient & Contextual Dialogue](#ambient-contextual-dialogue)

---

## Dialogue System Overview

### Dialogue Node Structure

```json
{
  "node_id": "string",
  "speaker": "npc_id",
  "portrait": "emotion_state",
  "text": "Dialogue text with {variable} support",
  "typing_effect": true,
  "choices": [
    {
      "text": "Player choice text",
      "next": "node_id",
      "condition": "optional_condition",
      "effects": ["optional_effect_list"]
    }
  ],
  "auto_advance": false,
  "delay_ms": 0
}
```

### Emotion States

- `neutral` - Default expression
- `happy` - Smiling, positive
- `sad` - Downcast, melancholy
- `angry` - Frustrated, upset
- `surprised` - Shocked, amazed
- `worried` - Concerned, anxious
- `thinking` - Contemplative
- `excited` - Enthusiastic
- `proud` - Accomplished
- `mysterious` - Enigmatic

### Variables

- `{player_name}` - Player's chosen name
- `{wpm}` - Current WPM stat
- `{accuracy}` - Current accuracy %
- `{gold}` - Current gold amount
- `{level}` - Player level
- `{region}` - Current region name
- `{time_of_day}` - Morning/Afternoon/Evening/Night
- `{lesson_count}` - Lessons completed
- `{tower_count}` - Towers owned

---

## Tutorial NPCs

### Elder Typhos - Tutorial Master

**Location:** Starting Village, Tutorial Area
**Role:** Primary tutorial guide, introduces game mechanics

#### First Meeting

```json
{
  "dialogue_id": "typhos_intro",
  "nodes": [
    {
      "node_id": "intro_1",
      "speaker": "elder_typhos",
      "portrait": "neutral",
      "text": "Ah, a new defender arrives. Welcome to Keystonia, young one.",
      "choices": [{"text": "Continue", "next": "intro_2"}]
    },
    {
      "node_id": "intro_2",
      "speaker": "elder_typhos",
      "portrait": "worried",
      "text": "I am Elder Typhos. For generations, I have trained those who would stand against the Corruption.",
      "choices": [{"text": "Continue", "next": "intro_3"}]
    },
    {
      "node_id": "intro_3",
      "speaker": "elder_typhos",
      "portrait": "thinking",
      "text": "The ancient letters hold power, but that power must be wielded with precision. Tell me, what brings you to our village?",
      "choices": [
        {"text": "I want to become a defender.", "next": "intro_defender", "effects": ["flag:chose_defender"]},
        {"text": "I'm just passing through.", "next": "intro_traveler", "effects": ["flag:chose_traveler"]},
        {"text": "What is this Corruption?", "next": "intro_corruption"}
      ]
    },
    {
      "node_id": "intro_defender",
      "speaker": "elder_typhos",
      "portrait": "happy",
      "text": "A noble calling! The realm needs brave souls like you. The keyboard is your weapon, and your fingers shall be the instruments of salvation.",
      "choices": [{"text": "Continue", "next": "intro_training"}]
    },
    {
      "node_id": "intro_traveler",
      "speaker": "elder_typhos",
      "portrait": "neutral",
      "text": "Few simply 'pass through' Keystonia these days. The Corruption blocks many paths. Perhaps fate brought you here for a reason.",
      "choices": [{"text": "Continue", "next": "intro_training"}]
    },
    {
      "node_id": "intro_corruption",
      "speaker": "elder_typhos",
      "portrait": "sad",
      "text": "The Corruption... a darkness that twists the very letters of creation. It spawns creatures of malformed words, spreading chaos across the land.",
      "choices": [
        {"text": "How do we fight it?", "next": "intro_training"},
        {"text": "Where did it come from?", "next": "intro_origin"}
      ]
    },
    {
      "node_id": "intro_origin",
      "speaker": "elder_typhos",
      "portrait": "mysterious",
      "text": "Some say it began when the First Typer made an error in the Great Script. Others believe it was always there, waiting. The truth... may be lost to time.",
      "choices": [{"text": "Continue", "next": "intro_training"}]
    },
    {
      "node_id": "intro_training",
      "speaker": "elder_typhos",
      "portrait": "proud",
      "text": "But enough history. Let us begin your training. Place your fingers on the home row - A, S, D, F for your left hand; J, K, L, and semicolon for your right.",
      "choices": [{"text": "I'm ready.", "next": "end", "effects": ["start_tutorial:basic_positioning"]}]
    }
  ]
}
```

#### Tutorial Progress Dialogues

```json
{
  "dialogue_id": "typhos_tutorial_progress",
  "nodes": [
    {
      "node_id": "progress_home_row",
      "speaker": "elder_typhos",
      "portrait": "happy",
      "text": "Excellent! You've mastered the home row. The foundation is set. Now let us reach for new heights - literally.",
      "choices": [{"text": "Continue", "next": "end", "effects": ["start_tutorial:top_row"]}]
    },
    {
      "node_id": "progress_top_row",
      "speaker": "elder_typhos",
      "portrait": "proud",
      "text": "The top row yields to your fingers! Q, W, E, R, T - the letters of inquiry and action. Your range expands.",
      "choices": [{"text": "Continue", "next": "end", "effects": ["start_tutorial:bottom_row"]}]
    },
    {
      "node_id": "progress_all_rows",
      "speaker": "elder_typhos",
      "portrait": "excited",
      "text": "All three rows! You command the full alphabet now. But speed and accuracy must work together. Let us test your mettle.",
      "choices": [{"text": "Continue", "next": "end", "effects": ["start_tutorial:speed_test"]}]
    },
    {
      "node_id": "progress_numbers",
      "speaker": "elder_typhos",
      "portrait": "thinking",
      "text": "Now we venture to the number row. 1 through 0 - the digits that measure and count. They require a stretch, but you are ready.",
      "choices": [{"text": "Continue", "next": "end", "effects": ["start_tutorial:numbers"]}]
    },
    {
      "node_id": "progress_complete",
      "speaker": "elder_typhos",
      "portrait": "proud",
      "text": "You have completed your basic training, {player_name}. Your WPM is {wpm} and your accuracy stands at {accuracy}%. A promising start!",
      "choices": [
        {"text": "Thank you, Elder.", "next": "complete_thanks"},
        {"text": "What's next?", "next": "complete_next"}
      ]
    },
    {
      "node_id": "complete_thanks",
      "speaker": "elder_typhos",
      "portrait": "happy",
      "text": "The thanks are yours to keep - you did the work. Now, the village awaits. Speak with the townsfolk, and prepare for the battles ahead.",
      "choices": [{"text": "Continue", "next": "end", "effects": ["complete_tutorial", "unlock:village"]}]
    },
    {
      "node_id": "complete_next",
      "speaker": "elder_typhos",
      "portrait": "neutral",
      "text": "The Evergrove awaits. Corrupted creatures threaten our borders. But first, visit the village. Equip yourself. Learn from others.",
      "choices": [{"text": "Continue", "next": "end", "effects": ["complete_tutorial", "unlock:village"]}]
    }
  ]
}
```

#### Post-Tutorial Conversations

```json
{
  "dialogue_id": "typhos_postgame",
  "nodes": [
    {
      "node_id": "greeting_morning",
      "speaker": "elder_typhos",
      "portrait": "neutral",
      "text": "The morning light favors practice. Your fingers remember more when rested.",
      "condition": "time_of_day == morning",
      "choices": [
        {"text": "Any advice for today?", "next": "advice"},
        {"text": "Can we train?", "next": "train_offer"},
        {"text": "Farewell.", "next": "end"}
      ]
    },
    {
      "node_id": "greeting_evening",
      "speaker": "elder_typhos",
      "portrait": "thinking",
      "text": "The evening grows long. The Corruption strengthens at night. Be vigilant.",
      "condition": "time_of_day == evening",
      "choices": [
        {"text": "Any advice?", "next": "advice"},
        {"text": "Can we train?", "next": "train_offer"},
        {"text": "Farewell.", "next": "end"}
      ]
    },
    {
      "node_id": "greeting_level_10",
      "speaker": "elder_typhos",
      "portrait": "proud",
      "text": "Level {level}! You've grown beyond my early lessons. Perhaps it's time you sought the Advanced Academy in the capital.",
      "condition": "level >= 10",
      "choices": [
        {"text": "Tell me about the Academy.", "next": "academy_info"},
        {"text": "I still have much to learn here.", "next": "humble_response"},
        {"text": "Farewell.", "next": "end"}
      ]
    },
    {
      "node_id": "advice",
      "speaker": "elder_typhos",
      "portrait": "thinking",
      "text": "Remember: accuracy before speed. A missed keystroke costs more than a slow one. The Corruption exploits our errors.",
      "choices": [{"text": "I'll remember.", "next": "end"}]
    },
    {
      "node_id": "train_offer",
      "speaker": "elder_typhos",
      "portrait": "neutral",
      "text": "Always eager to improve - that's the mark of a true defender. Which aspect would you focus on?",
      "choices": [
        {"text": "Home row fundamentals", "next": "end", "effects": ["open_lesson:home_row"]},
        {"text": "Speed training", "next": "end", "effects": ["open_lesson:speed_1"]},
        {"text": "Accuracy drills", "next": "end", "effects": ["open_lesson:accuracy_1"]},
        {"text": "Never mind.", "next": "end"}
      ]
    },
    {
      "node_id": "academy_info",
      "speaker": "elder_typhos",
      "portrait": "neutral",
      "text": "The Keystonia Academy trains elite defenders. Master Qwerta herself teaches there. You'll need to prove yourself in the Stonepass trials first.",
      "choices": [{"text": "I'll work toward that.", "next": "end"}]
    },
    {
      "node_id": "humble_response",
      "speaker": "elder_typhos",
      "portrait": "happy",
      "text": "Humility serves a defender well. Very well, let us continue to refine your skills.",
      "choices": [{"text": "Continue", "next": "train_offer"}]
    }
  ]
}
```

---

## Village NPCs

### Lyra the Innkeeper

**Location:** Starting Village, The Resting Keys Inn
**Role:** Save point, rumors, rest bonuses

#### Standard Conversations

```json
{
  "dialogue_id": "lyra_standard",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "lyra",
      "portrait": "happy",
      "text": "Welcome to The Resting Keys! Best inn this side of the Evergrove. What can I get you?",
      "choices": [
        {"text": "I'd like to rest.", "next": "rest_offer"},
        {"text": "Any news?", "next": "rumors"},
        {"text": "Just looking around.", "next": "browse"},
        {"text": "Farewell.", "next": "end"}
      ]
    },
    {
      "node_id": "rest_offer",
      "speaker": "lyra",
      "portrait": "neutral",
      "text": "A room for the night costs 10 gold. You'll wake refreshed with a temporary boost to your typing stamina. Interested?",
      "choices": [
        {"text": "Yes, I'll take a room.", "next": "rest_confirm", "condition": "gold >= 10", "effects": ["spend_gold:10", "apply_buff:rested"]},
        {"text": "Too expensive for me.", "next": "rest_decline_poor", "condition": "gold < 10"},
        {"text": "Not right now.", "next": "rest_decline"}
      ]
    },
    {
      "node_id": "rest_confirm",
      "speaker": "lyra",
      "portrait": "happy",
      "text": "Wonderful! Room three, up the stairs. Sleep well, defender. The morning brings new challenges.",
      "choices": [{"text": "Rest", "next": "end", "effects": ["rest_scene"]}]
    },
    {
      "node_id": "rest_decline_poor",
      "speaker": "lyra",
      "portrait": "sad",
      "text": "Times are hard, I understand. Tell you what - clear some corrupted creatures from the Evergrove, and I'll give you a discount.",
      "choices": [
        {"text": "I'll do that.", "next": "end", "effects": ["add_quest:lyra_discount"]},
        {"text": "Thanks anyway.", "next": "end"}
      ]
    },
    {
      "node_id": "rest_decline",
      "speaker": "lyra",
      "portrait": "neutral",
      "text": "The offer stands whenever you need it. A rested mind types faster, remember that!",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "rumors",
      "speaker": "lyra",
      "portrait": "thinking",
      "text": "Rumors? Oh, I hear plenty in this line of work...",
      "choices": [{"text": "Continue", "next": "rumor_random"}]
    },
    {
      "node_id": "rumor_random",
      "speaker": "lyra",
      "portrait": "mysterious",
      "text": "{random_rumor}",
      "choices": [
        {"text": "Interesting. Anything else?", "next": "rumor_random", "condition": "rumor_count < 3"},
        {"text": "Thanks for the information.", "next": "greeting"}
      ]
    },
    {
      "node_id": "browse",
      "speaker": "lyra",
      "portrait": "happy",
      "text": "Make yourself at home! The fireplace is always warm, and the mead is always cold. Well, the other way around for the mead.",
      "choices": [{"text": "Continue", "next": "end"}]
    }
  ],
  "rumor_pool": [
    "A merchant from Stonepass says the dwarven forges have gone quiet. Something's wrong in the deep tunnels.",
    "They say the Grove Guardian has awakened. The old protector stirs against the Corruption.",
    "A scholar was asking about the Mistfen Codex. Dangerous knowledge, if you ask me.",
    "The capital's defenses grow stronger, but the outer villages suffer. We need more defenders.",
    "Some travelers speak of a hidden shrine in the Evergrove. The Letter Spirits may answer prayers there.",
    "The Crimson Quill thieves have been spotted near the eastern road. Watch your coin purse!",
    "A shipment of rare inks went missing. The Scribe's Guild is offering a reward.",
    "They say the Corruption first appeared near the Obsidian Spire. No one goes there anymore."
  ]
}
```

#### Special Event Dialogue

```json
{
  "dialogue_id": "lyra_special",
  "nodes": [
    {
      "node_id": "festival_greeting",
      "speaker": "lyra",
      "portrait": "excited",
      "text": "It's the Festival of First Words! Drinks are half price, and there's a typing tournament in the square!",
      "condition": "event:festival_active",
      "choices": [
        {"text": "Tell me about the tournament.", "next": "festival_tournament"},
        {"text": "I'll take a drink!", "next": "festival_drink"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "festival_tournament",
      "speaker": "lyra",
      "portrait": "happy",
      "text": "Three rounds of speed typing! Winner gets a Gilded Keyboard charm and 500 gold. Entry is free!",
      "choices": [
        {"text": "Sign me up!", "next": "end", "effects": ["start_event:typing_tournament"]},
        {"text": "Maybe later.", "next": "greeting"}
      ]
    },
    {
      "node_id": "after_boss_victory",
      "speaker": "lyra",
      "portrait": "excited",
      "text": "You defeated the {last_boss}! The whole village is talking about it. This round's on the house!",
      "condition": "flag:recent_boss_victory",
      "choices": [{"text": "To victory!", "next": "end", "effects": ["clear_flag:recent_boss_victory", "apply_buff:celebration"]}]
    }
  ]
}
```

### Blacksmith Garrett

**Location:** Starting Village, The Iron Letter Forge
**Role:** Equipment crafting, repairs, upgrades

#### Shop Dialogue

```json
{
  "dialogue_id": "garrett_shop",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "garrett",
      "portrait": "neutral",
      "text": "*clang* *clang* Hmm? Oh, a customer. Welcome to the Iron Letter. What do you need?",
      "choices": [
        {"text": "Show me your wares.", "next": "end", "effects": ["open_shop:garrett"]},
        {"text": "Can you repair my equipment?", "next": "repair_check"},
        {"text": "I have materials to craft with.", "next": "craft_menu"},
        {"text": "Tell me about your work.", "next": "backstory"},
        {"text": "Farewell.", "next": "end"}
      ]
    },
    {
      "node_id": "repair_check",
      "speaker": "garrett",
      "portrait": "thinking",
      "text": "Let me see what you've got... {equipment_status}",
      "choices": [
        {"text": "Repair all ({repair_cost} gold)", "next": "repair_confirm", "condition": "gold >= repair_cost && damaged_items > 0", "effects": ["repair_all"]},
        {"text": "That's too expensive.", "next": "repair_decline", "condition": "gold < repair_cost && damaged_items > 0"},
        {"text": "Everything looks fine.", "next": "repair_none", "condition": "damaged_items == 0"},
        {"text": "Never mind.", "next": "greeting"}
      ]
    },
    {
      "node_id": "repair_confirm",
      "speaker": "garrett",
      "portrait": "happy",
      "text": "*clang* *clang* Done. Good as new. Take care of your gear, and it'll take care of you.",
      "choices": [{"text": "Thanks.", "next": "greeting"}]
    },
    {
      "node_id": "repair_decline",
      "speaker": "garrett",
      "portrait": "neutral",
      "text": "Come back when you have the coin. Damaged equipment fails at the worst moments.",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "repair_none",
      "speaker": "garrett",
      "portrait": "neutral",
      "text": "Your equipment's in good shape. Smart to check, though. Prevention beats repair.",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "craft_menu",
      "speaker": "garrett",
      "portrait": "thinking",
      "text": "Crafting, eh? Show me what materials you've gathered, and I'll tell you what's possible.",
      "choices": [{"text": "Continue", "next": "end", "effects": ["open_crafting:garrett"]}]
    },
    {
      "node_id": "backstory",
      "speaker": "garrett",
      "portrait": "neutral",
      "text": "Been smithing since I could hold a hammer. My father forged the ceremonial blades for the Scribe's Guild. I make defender's gear now.",
      "choices": [
        {"text": "Why defender's gear?", "next": "backstory_why"},
        {"text": "Sounds like skilled work.", "next": "backstory_skill"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "backstory_why",
      "speaker": "garrett",
      "portrait": "sad",
      "text": "Lost my sister to the Corruption. She was a defender. Her gear failed her - shoddy work from a traveling merchant. Never again.",
      "choices": [
        {"text": "I'm sorry for your loss.", "next": "backstory_sympathy"},
        {"text": "Your work honors her memory.", "next": "backstory_honor"}
      ]
    },
    {
      "node_id": "backstory_sympathy",
      "speaker": "garrett",
      "portrait": "neutral",
      "text": "It was years ago. But every piece I forge, I think of her. Make sure no other defender falls because their equipment failed.",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "backstory_honor",
      "speaker": "garrett",
      "portrait": "proud",
      "text": "That... means something. Thank you. Now, what can I forge for you?",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "backstory_skill",
      "speaker": "garrett",
      "portrait": "proud",
      "text": "It's honest work. A well-made gauntlet can mean the difference between life and death. Quality matters.",
      "choices": [{"text": "Continue", "next": "greeting"}]
    }
  ]
}
```

#### Quest-Related Dialogue

```json
{
  "dialogue_id": "garrett_quest",
  "nodes": [
    {
      "node_id": "special_order",
      "speaker": "garrett",
      "portrait": "excited",
      "text": "You're back! I've been working on something special. Bring me Refined Keysteel and a Spell-Forged Core, and I'll craft you the Defender's Gauntlets.",
      "condition": "quest:garrett_gauntlets == active",
      "choices": [
        {"text": "Here are the materials.", "next": "quest_complete", "condition": "has_item:refined_keysteel && has_item:spellforged_core", "effects": ["remove_item:refined_keysteel", "remove_item:spellforged_core"]},
        {"text": "Still gathering them.", "next": "quest_progress"},
        {"text": "Where do I find these?", "next": "quest_hints"}
      ]
    },
    {
      "node_id": "quest_complete",
      "speaker": "garrett",
      "portrait": "happy",
      "text": "Perfect! Give me a moment... *intense hammering* There. The Defender's Gauntlets. May they serve you well.",
      "choices": [{"text": "Thank you, Garrett.", "next": "end", "effects": ["add_item:defenders_gauntlets", "complete_quest:garrett_gauntlets"]}]
    },
    {
      "node_id": "quest_progress",
      "speaker": "garrett",
      "portrait": "neutral",
      "text": "No rush. Quality takes time - both in forging and gathering. I'll be here when you're ready.",
      "choices": [{"text": "Continue", "next": "end"}]
    },
    {
      "node_id": "quest_hints",
      "speaker": "garrett",
      "portrait": "thinking",
      "text": "Refined Keysteel comes from the mines in Stonepass - the dwarves trade it. Spell-Forged Cores... those drop from the arcane constructs in the Mistfen ruins.",
      "choices": [{"text": "Got it.", "next": "end"}]
    }
  ]
}
```

### Merchant Elise

**Location:** Starting Village, Market Square
**Role:** General goods, consumables, traveling merchant

```json
{
  "dialogue_id": "elise_standard",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "elise",
      "portrait": "happy",
      "text": "Hello, hello! Elise's Emporium has everything a defender needs! Potions, scrolls, and curiosities from across Keystonia!",
      "choices": [
        {"text": "Show me what you have.", "next": "end", "effects": ["open_shop:elise"]},
        {"text": "Any rare items today?", "next": "rare_check"},
        {"text": "Where do you get your goods?", "next": "trade_routes"},
        {"text": "Just browsing.", "next": "end"}
      ]
    },
    {
      "node_id": "rare_check",
      "speaker": "elise",
      "portrait": "mysterious",
      "text": "{rare_item_status}",
      "choices": [
        {"text": "I'll take a look.", "next": "end", "effects": ["open_shop:elise_rare"], "condition": "rare_stock > 0"},
        {"text": "Let me know when you get something.", "next": "rare_notify"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "rare_notify",
      "speaker": "elise",
      "portrait": "happy",
      "text": "I'll send word to the inn when my next shipment arrives. A defender like you deserves first pick!",
      "choices": [{"text": "Thanks.", "next": "greeting"}]
    },
    {
      "node_id": "trade_routes",
      "speaker": "elise",
      "portrait": "thinking",
      "text": "Oh, here and there! Dwarven tonics from Stonepass, elven remedies from the deep woods, even some enchanted goods from the Luminara markets.",
      "choices": [
        {"text": "Sounds dangerous.", "next": "trade_danger"},
        {"text": "How do you avoid the Corruption?", "next": "trade_safety"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "trade_danger",
      "speaker": "elise",
      "portrait": "proud",
      "text": "Danger? That's where the best goods are! Besides, I can type faster than any corrupted creature can shamble. *wink*",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "trade_safety",
      "speaker": "elise",
      "portrait": "neutral",
      "text": "I travel with the merchant caravans. Safety in numbers, and we hire defenders for protection. Speaking of which... interested in some escort work?",
      "choices": [
        {"text": "Tell me more.", "next": "caravan_quest"},
        {"text": "Not right now.", "next": "greeting"}
      ]
    },
    {
      "node_id": "caravan_quest",
      "speaker": "elise",
      "portrait": "excited",
      "text": "Next caravan leaves for Stonepass in three days. We need a defender who can handle the Evergrove path. Pay is 200 gold plus whatever loot you find. Interested?",
      "choices": [
        {"text": "I'm in.", "next": "end", "effects": ["add_quest:caravan_escort"]},
        {"text": "I'll think about it.", "next": "greeting"}
      ]
    }
  ]
}
```

---

## Quest Giver NPCs

### Captain Helena - Defender Commander

**Location:** Starting Village, Watchtower
**Role:** Combat quests, defender rankings, battle strategy

```json
{
  "dialogue_id": "helena_standard",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "helena",
      "portrait": "neutral",
      "text": "Defender. The Corruption doesn't rest, and neither should we. What's your report?",
      "choices": [
        {"text": "Any missions available?", "next": "mission_board"},
        {"text": "I want to check my ranking.", "next": "ranking"},
        {"text": "I need combat advice.", "next": "advice"},
        {"text": "Reporting for duty.", "next": "end"}
      ]
    },
    {
      "node_id": "mission_board",
      "speaker": "helena",
      "portrait": "thinking",
      "text": "Let me check the board... {active_missions_count} missions available. Which sector interests you?",
      "choices": [
        {"text": "Evergrove missions", "next": "end", "effects": ["open_quests:evergrove"]},
        {"text": "Stonepass missions", "next": "end", "effects": ["open_quests:stonepass"], "condition": "region_unlocked:stonepass"},
        {"text": "Mistfen missions", "next": "end", "effects": ["open_quests:mistfen"], "condition": "region_unlocked:mistfen"},
        {"text": "Never mind.", "next": "greeting"}
      ]
    },
    {
      "node_id": "ranking",
      "speaker": "helena",
      "portrait": "neutral",
      "text": "Current rank: {player_rank}. Missions completed: {missions_completed}. Creatures vanquished: {enemies_defeated}. {rank_comment}",
      "choices": [
        {"text": "How do I advance?", "next": "rank_advance"},
        {"text": "Good to know.", "next": "greeting"}
      ]
    },
    {
      "node_id": "rank_advance",
      "speaker": "helena",
      "portrait": "thinking",
      "text": "Complete more missions, defeat stronger enemies. Special commendations for boss victories. You need {xp_to_next_rank} more experience for the next rank.",
      "choices": [{"text": "I'll work on it.", "next": "greeting"}]
    },
    {
      "node_id": "advice",
      "speaker": "helena",
      "portrait": "thinking",
      "text": "What aspect of combat are you struggling with?",
      "choices": [
        {"text": "Fast enemies", "next": "advice_speed"},
        {"text": "Large waves", "next": "advice_waves"},
        {"text": "Boss fights", "next": "advice_bosses"},
        {"text": "Tower placement", "next": "advice_towers"}
      ]
    },
    {
      "node_id": "advice_speed",
      "speaker": "helena",
      "portrait": "neutral",
      "text": "Speed is countered with preparation. Place slow towers at chokepoints. Focus on accuracy - one clean hit beats three misses. And practice your common words until they're muscle memory.",
      "choices": [{"text": "Thanks, Captain.", "next": "greeting"}]
    },
    {
      "node_id": "advice_waves",
      "speaker": "helena",
      "portrait": "neutral",
      "text": "Large waves require prioritization. Target threats by proximity to your castle, not by which appeared first. Area towers help, but don't neglect single-target damage.",
      "choices": [{"text": "Understood.", "next": "greeting"}]
    },
    {
      "node_id": "advice_bosses",
      "speaker": "helena",
      "portrait": "proud",
      "text": "Bosses have patterns. Learn them. Watch for phase transitions. Save your abilities for crucial moments. And remember - it's not about speed, it's about surviving until the right opening.",
      "choices": [{"text": "I'll remember that.", "next": "greeting"}]
    },
    {
      "node_id": "advice_towers",
      "speaker": "helena",
      "portrait": "thinking",
      "text": "Placement wins battles before they start. Chokepoints multiply effectiveness. Mix tower types - a pure damage setup fails against armored enemies. And always have a fallback position.",
      "choices": [{"text": "Good advice.", "next": "greeting"}]
    }
  ]
}
```

### Scholar Marcus - Lore Keeper

**Location:** Starting Village, Library Tower
**Role:** Lore collection, research quests, historical knowledge

```json
{
  "dialogue_id": "marcus_standard",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "marcus",
      "portrait": "happy",
      "text": "Ah, a seeker of knowledge! The library is always open to those who thirst for understanding. How may I assist you?",
      "choices": [
        {"text": "I found some lore pages.", "next": "lore_turn_in"},
        {"text": "Tell me about the Corruption.", "next": "corruption_info"},
        {"text": "I want to research something.", "next": "research_menu"},
        {"text": "Just exploring.", "next": "explore_library"}
      ]
    },
    {
      "node_id": "lore_turn_in",
      "speaker": "marcus",
      "portrait": "excited",
      "text": "Lore pages! Let me see... {lore_pages_held} pages! Each one helps us understand more. Here's your reward - {lore_reward} gold and access to the restricted section.",
      "condition": "lore_pages > 0",
      "choices": [{"text": "Continue", "next": "end", "effects": ["turn_in_lore", "grant_xp:lore_bonus"]}]
    },
    {
      "node_id": "corruption_info",
      "speaker": "marcus",
      "portrait": "thinking",
      "text": "The Corruption... a vast topic. What specifically interests you?",
      "choices": [
        {"text": "Its origin.", "next": "corruption_origin"},
        {"text": "How it spreads.", "next": "corruption_spread"},
        {"text": "How to stop it.", "next": "corruption_cure"},
        {"text": "The creatures it creates.", "next": "corruption_creatures"}
      ]
    },
    {
      "node_id": "corruption_origin",
      "speaker": "marcus",
      "portrait": "mysterious",
      "text": "Ancient texts speak of the Typo Primordial - the first error in the Great Script. When the Letter Spirits shaped reality through perfect words, one letter was... wrong. That wrongness grew.",
      "choices": [
        {"text": "Can it be corrected?", "next": "corruption_cure"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "corruption_spread",
      "speaker": "marcus",
      "portrait": "worried",
      "text": "The Corruption feeds on errors - mistyped words, broken promises, forgotten knowledge. Each mistake gives it strength. That's why precision matters so much for defenders.",
      "choices": [
        {"text": "So accuracy fights it?", "next": "corruption_accuracy"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "corruption_accuracy",
      "speaker": "marcus",
      "portrait": "happy",
      "text": "Exactly! Perfect typing doesn't just defeat enemies - it literally pushes back the Corruption. Your accuracy rating affects the Corruption level in each region.",
      "choices": [{"text": "I had no idea.", "next": "greeting"}]
    },
    {
      "node_id": "corruption_cure",
      "speaker": "marcus",
      "portrait": "thinking",
      "text": "The legends speak of the Perfect Word - a phrase of such purity it could unmake the Corruption entirely. Many have sought it. None have succeeded. Yet.",
      "choices": [{"text": "I'll find it.", "next": "greeting"}]
    },
    {
      "node_id": "corruption_creatures",
      "speaker": "marcus",
      "portrait": "neutral",
      "text": "Corrupted creatures were once normal words - transformed by the darkness. Each bears a twisted reflection of its original meaning. Defeating them releases the word back into purity.",
      "choices": [{"text": "That's... almost sad.", "next": "creatures_sympathy"}]
    },
    {
      "node_id": "creatures_sympathy",
      "speaker": "marcus",
      "portrait": "sad",
      "text": "It is. Remember that mercy, defender. These creatures didn't choose their fate. We fight not out of hatred, but to restore what was lost.",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "research_menu",
      "speaker": "marcus",
      "portrait": "thinking",
      "text": "The library contains knowledge on many subjects. What calls to you?",
      "choices": [
        {"text": "Enemy weaknesses", "next": "end", "effects": ["open_codex:enemies"]},
        {"text": "Tower blueprints", "next": "end", "effects": ["open_codex:towers"]},
        {"text": "Regional histories", "next": "end", "effects": ["open_codex:regions"]},
        {"text": "Never mind.", "next": "greeting"}
      ]
    },
    {
      "node_id": "explore_library",
      "speaker": "marcus",
      "portrait": "happy",
      "text": "Please, browse freely! But do be careful with the books in the eastern alcove. Some of them... bite.",
      "choices": [{"text": "I'll be careful.", "next": "end"}]
    }
  ]
}
```

---

## Regional NPCs

### Evergrove - Ranger Sylva

**Location:** Evergrove, Ranger Station
**Role:** Regional guide, hunting quests, survival tips

```json
{
  "dialogue_id": "sylva_standard",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "sylva",
      "portrait": "neutral",
      "text": "*nods* Defender. The grove speaks of your coming. What brings you to our forests?",
      "choices": [
        {"text": "I'm hunting Corrupted.", "next": "hunt_info"},
        {"text": "I need to pass through.", "next": "path_info"},
        {"text": "What is this place?", "next": "grove_info"},
        {"text": "Just passing by.", "next": "end"}
      ]
    },
    {
      "node_id": "hunt_info",
      "speaker": "sylva",
      "portrait": "thinking",
      "text": "The Corruption runs deep here. {corruption_level} corruption currently. The creatures cluster near the old shrine. But beware - the Grove Guardian watches.",
      "choices": [
        {"text": "Tell me about the Guardian.", "next": "guardian_info"},
        {"text": "I can handle it.", "next": "hunt_accept"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "guardian_info",
      "speaker": "sylva",
      "portrait": "worried",
      "text": "The Grove Guardian was once a protector spirit. The Corruption has twisted it. It attacks anything that enters its territory - Corruption and defenders alike.",
      "choices": [
        {"text": "Can it be saved?", "next": "guardian_save"},
        {"text": "I'll defeat it.", "next": "guardian_fight"}
      ]
    },
    {
      "node_id": "guardian_save",
      "speaker": "sylva",
      "portrait": "sad",
      "text": "Perhaps... the scholars say a perfectly typed purification phrase could restore it. But in the heat of battle, such precision is nearly impossible.",
      "choices": [{"text": "I'll try.", "next": "guardian_fight"}]
    },
    {
      "node_id": "guardian_fight",
      "speaker": "sylva",
      "portrait": "neutral",
      "text": "Then prepare well. The Guardian is strongest at dawn. It uses the trees themselves as weapons. Keep moving, and watch for the root attacks.",
      "choices": [{"text": "Thanks for the warning.", "next": "greeting"}]
    },
    {
      "node_id": "hunt_accept",
      "speaker": "sylva",
      "portrait": "neutral",
      "text": "Confidence is good. Overconfidence gets defenders killed. Track carefully, strike precisely, and may the grove guide your fingers.",
      "choices": [{"text": "Continue", "next": "end"}]
    },
    {
      "node_id": "path_info",
      "speaker": "sylva",
      "portrait": "thinking",
      "text": "The main path is blocked by heavy Corruption. But there's an old ranger trail... if you can clear the creatures along the way.",
      "choices": [
        {"text": "Show me the trail.", "next": "end", "effects": ["reveal_path:ranger_trail"]},
        {"text": "I'll take the main path.", "next": "main_path_warning"}
      ]
    },
    {
      "node_id": "main_path_warning",
      "speaker": "sylva",
      "portrait": "worried",
      "text": "Your choice. The main path has higher creature density and at least one elite. Good luck.",
      "choices": [{"text": "Continue", "next": "end"}]
    },
    {
      "node_id": "grove_info",
      "speaker": "sylva",
      "portrait": "neutral",
      "text": "The Evergrove is the oldest forest in Keystonia. The Letter Spirits planted the first trees with words of growth. Now the Corruption seeks to unwrite them.",
      "choices": [
        {"text": "How long have you guarded it?", "next": "sylva_backstory"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "sylva_backstory",
      "speaker": "sylva",
      "portrait": "sad",
      "text": "Twenty years. My mother was a ranger. Her mother before her. We've always served the grove. We'll continue until the Corruption is gone - or until we are.",
      "choices": [{"text": "You won't fight alone.", "next": "sylva_ally"}]
    },
    {
      "node_id": "sylva_ally",
      "speaker": "sylva",
      "portrait": "happy",
      "text": "*rare smile* Then the grove has gained a new friend. Here - take this. A ranger's charm. It'll help you find hidden paths.",
      "choices": [{"text": "Thank you.", "next": "end", "effects": ["add_item:ranger_charm"]}]
    }
  ]
}
```

### Stonepass - Forgemaster Thrain

**Location:** Stonepass, Ancestral Forge
**Role:** Dwarven crafting, mining quests, deep lore

```json
{
  "dialogue_id": "thrain_standard",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "thrain",
      "portrait": "neutral",
      "text": "Hmph. Surface-walker. What business have ye in the deep halls?",
      "choices": [
        {"text": "I need dwarven equipment.", "next": "shop_intro"},
        {"text": "I'm here about the Corruption.", "next": "corruption_talk"},
        {"text": "Tell me of your people.", "next": "dwarf_history"},
        {"text": "Apologies for intruding.", "next": "respect_response"}
      ]
    },
    {
      "node_id": "shop_intro",
      "speaker": "thrain",
      "portrait": "thinking",
      "text": "Dwarven work ain't cheap, and it ain't quick. But it lasts. Ye got the gold and the patience?",
      "choices": [
        {"text": "Show me what you have.", "next": "end", "effects": ["open_shop:thrain"]},
        {"text": "What makes dwarven gear special?", "next": "gear_quality"},
        {"text": "Never mind.", "next": "greeting"}
      ]
    },
    {
      "node_id": "gear_quality",
      "speaker": "thrain",
      "portrait": "proud",
      "text": "Each piece is forged with Keysteel from the deep veins. We type the runes of making into every link. The metal remembers. It fights alongside ye.",
      "choices": [
        {"text": "Impressive.", "next": "shop_intro"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "corruption_talk",
      "speaker": "thrain",
      "portrait": "angry",
      "text": "The Corruption! *slams fist* It seeps through the cracks. Twists our tunnels. Our scouts... many haven't returned.",
      "choices": [
        {"text": "Let me help.", "next": "help_offer"},
        {"text": "What happened?", "next": "corruption_story"},
        {"text": "I'm sorry.", "next": "sympathy_response"}
      ]
    },
    {
      "node_id": "help_offer",
      "speaker": "thrain",
      "portrait": "surprised",
      "text": "Ye'd help us? Most surface-walkers don't care what happens below. Very well - we need someone to clear the lower mines. The pay is good, and ye'll have our gratitude.",
      "choices": [
        {"text": "I accept.", "next": "end", "effects": ["add_quest:clear_lower_mines"]},
        {"text": "Tell me more first.", "next": "mines_info"}
      ]
    },
    {
      "node_id": "mines_info",
      "speaker": "thrain",
      "portrait": "worried",
      "text": "The lower mines have been overrun. Corrupted creatures pour from a rift we can't close. We've sealed the tunnels, but they're breaking through. We need someone to push them back.",
      "choices": [
        {"text": "I'll do it.", "next": "end", "effects": ["add_quest:clear_lower_mines"]},
        {"text": "That sounds dangerous.", "next": "danger_acknowledge"}
      ]
    },
    {
      "node_id": "danger_acknowledge",
      "speaker": "thrain",
      "portrait": "neutral",
      "text": "Aye, it is. I won't lie to ye. But we've prepared supplies - potions, repair kits, even a map of the tunnels. Ye won't go in unprepared.",
      "choices": [
        {"text": "Alright, I'll help.", "next": "end", "effects": ["add_quest:clear_lower_mines"]},
        {"text": "I need more time.", "next": "greeting"}
      ]
    },
    {
      "node_id": "corruption_story",
      "speaker": "thrain",
      "portrait": "sad",
      "text": "Three weeks ago, the miners broke into an ancient chamber. Something was sealed there. When they breached it... the Corruption poured out. We lost twelve good dwarves that day.",
      "choices": [
        {"text": "What was in the chamber?", "next": "chamber_mystery"},
        {"text": "Let me help stop it.", "next": "help_offer"}
      ]
    },
    {
      "node_id": "chamber_mystery",
      "speaker": "thrain",
      "portrait": "mysterious",
      "text": "The survivors spoke of writing on the walls. Ancient script, older than our kingdom. And at the center... a single word, pulsing with dark power. We don't know what it says.",
      "choices": [
        {"text": "I need to see it.", "next": "help_offer"},
        {"text": "That's concerning.", "next": "greeting"}
      ]
    },
    {
      "node_id": "sympathy_response",
      "speaker": "thrain",
      "portrait": "neutral",
      "text": "Sympathy buys nothing. But... I appreciate it. Few surface-walkers understand loss. Perhaps ye're different.",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "dwarf_history",
      "speaker": "thrain",
      "portrait": "proud",
      "text": "We are the Forgeborn - descendants of those who shaped the first letters in metal. When others wrote in ink, we wrote in steel. Our words endure.",
      "choices": [
        {"text": "An impressive legacy.", "next": "legacy_response"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "legacy_response",
      "speaker": "thrain",
      "portrait": "happy",
      "text": "Ye understand! Most surface-walkers see only short beards and pickaxes. But we are craftsmen of the word made physical. Visit our museum sometime - see what our ancestors created.",
      "choices": [{"text": "I'd like that.", "next": "greeting"}]
    },
    {
      "node_id": "respect_response",
      "speaker": "thrain",
      "portrait": "surprised",
      "text": "Hm. Polite for a surface-walker. Perhaps ye're worth talking to after all. What brings ye to Stonepass?",
      "choices": [{"text": "Continue", "next": "greeting"}]
    }
  ]
}
```

### Mistfen - Arcanist Vera

**Location:** Mistfen, Arcane Spire
**Role:** Magic items, spell research, mystical quests

```json
{
  "dialogue_id": "vera_standard",
  "nodes": [
    {
      "node_id": "greeting",
      "speaker": "vera",
      "portrait": "mysterious",
      "text": "The mists part for you. Interesting. The Spire doesn't welcome everyone. What do you seek, traveler?",
      "choices": [
        {"text": "I need magical supplies.", "next": "shop_intro"},
        {"text": "I'm researching the Corruption.", "next": "corruption_research"},
        {"text": "What is this place?", "next": "spire_info"},
        {"text": "Just exploring.", "next": "explore_warning"}
      ]
    },
    {
      "node_id": "shop_intro",
      "speaker": "vera",
      "portrait": "neutral",
      "text": "Magical supplies... I can provide scrolls, enchantments, and certain... artifacts. But magic has a cost beyond gold. Are you prepared?",
      "choices": [
        {"text": "Show me.", "next": "end", "effects": ["open_shop:vera"]},
        {"text": "What kind of cost?", "next": "magic_cost"},
        {"text": "Never mind.", "next": "greeting"}
      ]
    },
    {
      "node_id": "magic_cost",
      "speaker": "vera",
      "portrait": "thinking",
      "text": "Every enchantment requires a word of power. Use it, and that word is consumed - at least for a time. Choose your spells wisely.",
      "choices": [
        {"text": "I understand.", "next": "end", "effects": ["open_shop:vera"]},
        {"text": "That's too risky.", "next": "greeting"}
      ]
    },
    {
      "node_id": "corruption_research",
      "speaker": "vera",
      "portrait": "excited",
      "text": "A kindred spirit! The Corruption is the most fascinating - and dangerous - magical phenomenon in recorded history. What specifically interests you?",
      "choices": [
        {"text": "Its magical nature.", "next": "corruption_magic"},
        {"text": "How to counteract it.", "next": "corruption_counter"},
        {"text": "The entity behind it.", "next": "corruption_entity"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "corruption_magic",
      "speaker": "vera",
      "portrait": "thinking",
      "text": "The Corruption isn't just dark magic - it's anti-language. Where our words create, it un-creates. Every letter it touches becomes meaningless noise.",
      "choices": [
        {"text": "Can it be reversed?", "next": "corruption_counter"},
        {"text": "Fascinating.", "next": "greeting"}
      ]
    },
    {
      "node_id": "corruption_counter",
      "speaker": "vera",
      "portrait": "neutral",
      "text": "Precision is the key. The Corruption exploits errors - typos, mistakes, uncertain strokes. Perfect typing generates a field of purity around the typist. Master your craft, and the Corruption cannot touch you.",
      "choices": [
        {"text": "So accuracy is literal defense?", "next": "accuracy_defense"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "accuracy_defense",
      "speaker": "vera",
      "portrait": "happy",
      "text": "Exactly! You understand what many never grasp. Here - take this amulet. It amplifies your accuracy aura. The Corruption will find you... harder to touch.",
      "choices": [{"text": "Thank you.", "next": "end", "effects": ["add_item:accuracy_amulet"]}]
    },
    {
      "node_id": "corruption_entity",
      "speaker": "vera",
      "portrait": "worried",
      "text": "You tread dangerous ground. Some believe the Corruption has... consciousness. An entity of pure entropy, seeking to unwrite all creation. The Typo Primordial given form.",
      "choices": [
        {"text": "Can it be killed?", "next": "entity_kill"},
        {"text": "That's terrifying.", "next": "entity_fear"}
      ]
    },
    {
      "node_id": "entity_kill",
      "speaker": "vera",
      "portrait": "mysterious",
      "text": "Kill? Perhaps not. But... corrected? The Perfect Word, if it exists, could rewrite the error at the heart of everything. Find it, and you might save the world.",
      "choices": [{"text": "I'll search for it.", "next": "greeting"}]
    },
    {
      "node_id": "entity_fear",
      "speaker": "vera",
      "portrait": "neutral",
      "text": "Fear is rational. But knowledge is power. The more we understand the Corruption, the better we can fight it. Don't let fear stop you from learning.",
      "choices": [{"text": "Continue", "next": "greeting"}]
    },
    {
      "node_id": "spire_info",
      "speaker": "vera",
      "portrait": "proud",
      "text": "The Arcane Spire has stood for millennia. Built by the first word-mages, it serves as a beacon of magical knowledge. The mists protect it from the Corruption.",
      "choices": [
        {"text": "The mists are protective?", "next": "mist_explanation"},
        {"text": "Continue", "next": "greeting"}
      ]
    },
    {
      "node_id": "mist_explanation",
      "speaker": "vera",
      "portrait": "thinking",
      "text": "The mists are words given form - protective incantations spoken so often they've become permanent. They filter out corruption, allowing only those with purpose to enter.",
      "choices": [
        {"text": "Remarkable magic.", "next": "greeting"},
        {"text": "Can I learn this?", "next": "learn_magic"}
      ]
    },
    {
      "node_id": "learn_magic",
      "speaker": "vera",
      "portrait": "happy",
      "text": "Perhaps. The foundation is the same - perfect typing, absolute precision. But word-magic requires years of study. Still... I could teach you the basics.",
      "choices": [
        {"text": "I'd like that.", "next": "end", "effects": ["add_quest:learn_word_magic"]},
        {"text": "Maybe another time.", "next": "greeting"}
      ]
    },
    {
      "node_id": "explore_warning",
      "speaker": "vera",
      "portrait": "worried",
      "text": "Exploration is welcome, but be careful. The Spire's lower levels contain... experiments. Not all of them are stable. Stay on the main floors unless you're prepared for danger.",
      "choices": [{"text": "I'll be careful.", "next": "end"}]
    }
  ]
}
```

---

## Boss Pre-Fight Dialogue

### Grove Guardian

```json
{
  "dialogue_id": "boss_grove_guardian",
  "nodes": [
    {
      "node_id": "approach",
      "speaker": "narrator",
      "portrait": null,
      "text": "The ancient tree shudders. Bark cracks. Eyes of amber light open in the trunk.",
      "auto_advance": true,
      "delay_ms": 2000,
      "choices": [{"text": "", "next": "guardian_awake"}]
    },
    {
      "node_id": "guardian_awake",
      "speaker": "grove_guardian",
      "portrait": "angry",
      "text": "INTRUDER... IN THE SACRED... GROVE...",
      "choices": [
        {"text": "I'm here to help!", "next": "help_attempt"},
        {"text": "I mean no harm.", "next": "peace_attempt"},
        {"text": "[Ready weapons]", "next": "combat_ready"}
      ]
    },
    {
      "node_id": "help_attempt",
      "speaker": "grove_guardian",
      "portrait": "confused",
      "text": "HELP... NONE CAN HELP... THE CORRUPTION... CONSUMES... I CANNOT... STOP...",
      "choices": [
        {"text": "Fight the Corruption, not me!", "next": "corruption_response"},
        {"text": "[Ready weapons]", "next": "combat_ready"}
      ]
    },
    {
      "node_id": "peace_attempt",
      "speaker": "grove_guardian",
      "portrait": "sad",
      "text": "HARM... I CAUSE HARM... TO ALL... CANNOT CONTROL... PLEASE... END THIS...",
      "choices": [
        {"text": "I'll try to purify you.", "next": "purify_hint"},
        {"text": "[Ready weapons]", "next": "combat_ready"}
      ]
    },
    {
      "node_id": "corruption_response",
      "speaker": "grove_guardian",
      "portrait": "angry",
      "text": "I CANNOT... THE DARKNESS... IS ME... NOW... FORGIVE... ME...",
      "choices": [{"text": "[Prepare for battle]", "next": "combat_start"}]
    },
    {
      "node_id": "purify_hint",
      "speaker": "grove_guardian",
      "portrait": "hopeful",
      "text": "PURIFY... THE ANCIENT... WORDS... TYPE THEM... PERFECTLY... FREE ME...",
      "choices": [{"text": "[Begin purification attempt]", "next": "combat_start_purify"}]
    },
    {
      "node_id": "combat_ready",
      "speaker": "grove_guardian",
      "portrait": "angry",
      "text": "SO BE IT... DEFENDER... PROVE YOUR... WORTH...",
      "choices": [{"text": "[Begin battle]", "next": "combat_start"}]
    },
    {
      "node_id": "combat_start",
      "speaker": "narrator",
      "portrait": null,
      "text": "The Grove Guardian rises to its full height. Roots burst from the ground. The battle begins!",
      "choices": [{"text": "", "next": "end", "effects": ["start_boss:grove_guardian"]}]
    },
    {
      "node_id": "combat_start_purify",
      "speaker": "narrator",
      "portrait": null,
      "text": "The Guardian's corruption pulses. Type the ancient words of purification perfectly to weaken it!",
      "choices": [{"text": "", "next": "end", "effects": ["start_boss:grove_guardian", "enable_purification"]}]
    }
  ]
}
```

### Stone Colossus

```json
{
  "dialogue_id": "boss_stone_colossus",
  "nodes": [
    {
      "node_id": "approach",
      "speaker": "narrator",
      "portrait": null,
      "text": "The cavern trembles. Stone grinds against stone. A massive figure rises from the rubble.",
      "auto_advance": true,
      "delay_ms": 2000,
      "choices": [{"text": "", "next": "colossus_awake"}]
    },
    {
      "node_id": "colossus_awake",
      "speaker": "stone_colossus",
      "portrait": "angry",
      "text": "[Runes carved in its chest glow red] SEALED... FOR AGES... NOW... FREE...",
      "choices": [
        {"text": "Who sealed you?", "next": "history"},
        {"text": "Return to your slumber!", "next": "defiance"},
        {"text": "[Study the runes]", "next": "rune_study"}
      ]
    },
    {
      "node_id": "history",
      "speaker": "stone_colossus",
      "portrait": "angry",
      "text": "THE FORGEBORN... BETRAYED... THEIR CREATION... SEALED ME... IN DARKNESS... NOW... REVENGE...",
      "choices": [
        {"text": "The dwarves had reasons.", "next": "dwarf_defense"},
        {"text": "[Ready weapons]", "next": "combat_ready"}
      ]
    },
    {
      "node_id": "dwarf_defense",
      "speaker": "stone_colossus",
      "portrait": "angry",
      "text": "REASONS... FEAR... OF POWER... THEY COULD NOT... CONTROL... I AM... THE PERFECT... WORD... MADE STONE...",
      "choices": [{"text": "[Begin battle]", "next": "combat_start"}]
    },
    {
      "node_id": "defiance",
      "speaker": "stone_colossus",
      "portrait": "amused",
      "text": "SMALL... CREATURE... YOUR WORDS... ARE WEAK... YOUR FINGERS... SLOW... YOU CANNOT... STOP... ME...",
      "choices": [
        {"text": "We'll see about that.", "next": "combat_ready"},
        {"text": "[Study the runes]", "next": "rune_study"}
      ]
    },
    {
      "node_id": "rune_study",
      "speaker": "narrator",
      "portrait": null,
      "text": "The runes spell out an ancient binding phrase. If typed perfectly during battle, it could weaken the Colossus significantly.",
      "choices": [
        {"text": "[Memorize the phrase]", "next": "combat_start_rune", "effects": ["learn_weakness:binding_phrase"]},
        {"text": "[Begin battle now]", "next": "combat_start"}
      ]
    },
    {
      "node_id": "combat_ready",
      "speaker": "stone_colossus",
      "portrait": "angry",
      "text": "THEN... FACE... YOUR END...",
      "choices": [{"text": "[Begin battle]", "next": "combat_start"}]
    },
    {
      "node_id": "combat_start",
      "speaker": "narrator",
      "portrait": null,
      "text": "The Stone Colossus raises its massive fists. The cavern shakes with each step it takes toward you!",
      "choices": [{"text": "", "next": "end", "effects": ["start_boss:stone_colossus"]}]
    },
    {
      "node_id": "combat_start_rune",
      "speaker": "narrator",
      "portrait": null,
      "text": "You've learned the binding phrase. Type it perfectly when the Colossus charges to stun it!",
      "choices": [{"text": "", "next": "end", "effects": ["start_boss:stone_colossus", "enable_binding"]}]
    }
  ]
}
```

### Mist Wraith

```json
{
  "dialogue_id": "boss_mist_wraith",
  "nodes": [
    {
      "node_id": "approach",
      "speaker": "narrator",
      "portrait": null,
      "text": "The fog thickens unnaturally. Whispers echo from every direction. A figure coalesces from the mist itself.",
      "auto_advance": true,
      "delay_ms": 2000,
      "choices": [{"text": "", "next": "wraith_appear"}]
    },
    {
      "node_id": "wraith_appear",
      "speaker": "mist_wraith",
      "portrait": "mysterious",
      "text": "Ssso... another ssseeker... of knowledge... Welcome... to my... domain...",
      "choices": [
        {"text": "What are you?", "next": "identity"},
        {"text": "Release the Spire from your grip!", "next": "defiance"},
        {"text": "[Remain silent, observe]", "next": "observe"}
      ]
    },
    {
      "node_id": "identity",
      "speaker": "mist_wraith",
      "portrait": "sad",
      "text": "Once... I was... Archmage... Vorthan... Ssseeker of... the Perfect Word... I found... only... Corruption...",
      "choices": [
        {"text": "You can still fight it!", "next": "hope_attempt"},
        {"text": "Then you must be stopped.", "next": "combat_ready"}
      ]
    },
    {
      "node_id": "hope_attempt",
      "speaker": "mist_wraith",
      "portrait": "angry",
      "text": "Fight? I AM... the Corruption now... Every word I ssspeak... spreadsss it... There isss... no hope... for me...",
      "choices": [
        {"text": "Then I'll end your suffering.", "next": "mercy_path"},
        {"text": "[Ready weapons]", "next": "combat_ready"}
      ]
    },
    {
      "node_id": "mercy_path",
      "speaker": "mist_wraith",
      "portrait": "grateful",
      "text": "Mercy... yesss... But firsst... you mussst... prove... worthy... Sssurvive my tesst... and I will... tell you... the sssecret...",
      "choices": [{"text": "What secret?", "next": "secret_hint"}]
    },
    {
      "node_id": "secret_hint",
      "speaker": "mist_wraith",
      "portrait": "mysterious",
      "text": "The Perfect Word... I nearly... found it... It liesss... in the heart... of the Corruption... itself... Now... prove... yoursself...",
      "choices": [{"text": "[Begin trial]", "next": "combat_start_trial"}]
    },
    {
      "node_id": "defiance",
      "speaker": "mist_wraith",
      "portrait": "amused",
      "text": "The Ssspire... isss mine... The mistsss... obey only... me... You are... nothing... but another... meal... for the fog...",
      "choices": [
        {"text": "We'll see about that.", "next": "combat_ready"},
        {"text": "[Observe the mist patterns]", "next": "observe"}
      ]
    },
    {
      "node_id": "observe",
      "speaker": "narrator",
      "portrait": null,
      "text": "You notice the Wraith flickers when certain words are spoken nearby. Words of clarity seem to hurt it.",
      "choices": [
        {"text": "[Use this knowledge]", "next": "combat_start_clarity", "effects": ["learn_weakness:clarity_words"]},
        {"text": "[Attack now]", "next": "combat_start"}
      ]
    },
    {
      "node_id": "combat_ready",
      "speaker": "mist_wraith",
      "portrait": "angry",
      "text": "Foolisssh... defender... The mistsss... will consume... you...",
      "choices": [{"text": "[Begin battle]", "next": "combat_start"}]
    },
    {
      "node_id": "combat_start",
      "speaker": "narrator",
      "portrait": null,
      "text": "The Mist Wraith dissolves into the fog, attacking from every direction at once!",
      "choices": [{"text": "", "next": "end", "effects": ["start_boss:mist_wraith"]}]
    },
    {
      "node_id": "combat_start_trial",
      "speaker": "narrator",
      "portrait": null,
      "text": "The Wraith tests you not with violence, but with riddles of fog. Type the answers clearly to dispel its illusions!",
      "choices": [{"text": "", "next": "end", "effects": ["start_boss:mist_wraith", "enable_trial_mode"]}]
    },
    {
      "node_id": "combat_start_clarity",
      "speaker": "narrator",
      "portrait": null,
      "text": "You've learned the Wraith's weakness! Type words of clarity to dispel its fog form temporarily!",
      "choices": [{"text": "", "next": "end", "effects": ["start_boss:mist_wraith", "enable_clarity"]}]
    }
  ]
}
```

---

## Ambient & Contextual Dialogue

### Weather-Based NPC Comments

```json
{
  "dialogue_id": "ambient_weather",
  "conditions": {
    "weather": "varies"
  },
  "comments": {
    "rain": [
      {"speaker": "villager", "text": "This rain... the letters blur on wet parchment."},
      {"speaker": "villager", "text": "Stay dry, defender. Wet fingers slip on the keys."},
      {"speaker": "villager", "text": "The crops need rain, but my old bones don't agree."}
    ],
    "storm": [
      {"speaker": "villager", "text": "Thunder! The Letter Spirits are angry today."},
      {"speaker": "villager", "text": "Best stay indoors. Lightning seeks the highest point - and the fastest typist."},
      {"speaker": "villager", "text": "Storms like this... they bring strange creatures from the deep forests."}
    ],
    "fog": [
      {"speaker": "villager", "text": "Can barely see my hand in front of my face..."},
      {"speaker": "villager", "text": "The mist creeps in from Mistfen. Unnatural, if you ask me."},
      {"speaker": "villager", "text": "Watch your step in this fog. The Corruption hides in the gray."}
    ],
    "clear": [
      {"speaker": "villager", "text": "Beautiful day for practice! The letters seem to glow in the sunlight."},
      {"speaker": "villager", "text": "Clear skies mean clear minds. Type well today, defender!"},
      {"speaker": "villager", "text": "Not a cloud in sight. Even the Corruption seems to retreat on days like this."}
    ],
    "snow": [
      {"speaker": "villager", "text": "Snow from the northern mountains. Keep your fingers warm."},
      {"speaker": "villager", "text": "The children love the snow. The defenders know it means cold keyboards."},
      {"speaker": "villager", "text": "White as blank parchment. A new page to write upon."}
    ]
  }
}
```

### Time-Based NPC Comments

```json
{
  "dialogue_id": "ambient_time",
  "conditions": {
    "time_of_day": "varies"
  },
  "comments": {
    "morning": [
      {"speaker": "villager", "text": "Fresh morning! The keyboard is still warm from the dawn prayers."},
      {"speaker": "villager", "text": "Early bird gets the best loot, they say."},
      {"speaker": "villager", "text": "Morning practice makes perfect. Start the day right!"}
    ],
    "afternoon": [
      {"speaker": "villager", "text": "Midday already? Time flies when you're typing."},
      {"speaker": "villager", "text": "The market's busy at this hour. Good deals to be found."},
      {"speaker": "villager", "text": "Taking a break from the fields. Even farmers need rest."}
    ],
    "evening": [
      {"speaker": "villager", "text": "The sun sets early these days. Winter approaches."},
      {"speaker": "villager", "text": "Heading to the inn for a warm meal. Join us?"},
      {"speaker": "villager", "text": "Evening prayers at the shrine. The Letter Spirits listen best at dusk."}
    ],
    "night": [
      {"speaker": "villager", "text": "Dangerous to be out at night. The Corruption is strongest now."},
      {"speaker": "guard", "text": "Stay alert, defender. We've had sightings on the eastern road."},
      {"speaker": "villager", "text": "Can't sleep. Too many worries. The world feels heavier at night."}
    ]
  }
}
```

### Player Achievement Reactions

```json
{
  "dialogue_id": "ambient_achievements",
  "conditions": {
    "achievement": "varies"
  },
  "comments": {
    "first_boss_kill": [
      {"speaker": "villager", "text": "You defeated the {boss_name}! The village is safer because of you!"},
      {"speaker": "child", "text": "Mommy, that's the hero who beat the monster!"},
      {"speaker": "elder", "text": "Impressive. You have the makings of a true defender."}
    ],
    "high_wpm": [
      {"speaker": "scribe", "text": "Your typing speed is legendary! The Scribe's Guild speaks of you."},
      {"speaker": "villager", "text": "Fingers like lightning! I've never seen anyone type so fast."},
      {"speaker": "merchant", "text": "With speed like that, you should enter the tournaments!"}
    ],
    "high_accuracy": [
      {"speaker": "scholar", "text": "Not a single error! The Letter Spirits smile upon you."},
      {"speaker": "teacher", "text": "Perfect accuracy... you could teach at the Academy."},
      {"speaker": "villager", "text": "They say you haven't made a typo in weeks. Is it true?"}
    ],
    "wealthy": [
      {"speaker": "merchant", "text": "Ah, my favorite customer! Shall I show you the premium stock?"},
      {"speaker": "beggar", "text": "Spare a coin for the less fortunate, generous defender?"},
      {"speaker": "villager", "text": "With pockets that deep, you could fund the whole village defense!"}
    ],
    "long_streak": [
      {"speaker": "villager", "text": "You've been defending us for {streak} days straight! Don't you ever rest?"},
      {"speaker": "innkeeper", "text": "You're here every day! At this rate, I should name a room after you."},
      {"speaker": "guard", "text": "Consistent. Reliable. The mark of a true defender."}
    ]
  }
}
```

### Low Health / Resource Warnings

```json
{
  "dialogue_id": "ambient_warnings",
  "conditions": {
    "status": "varies"
  },
  "comments": {
    "low_health": [
      {"speaker": "healer", "text": "You look injured! Let me tend to those wounds."},
      {"speaker": "villager", "text": "Defender, you're bleeding! Visit the healer quickly!"},
      {"speaker": "guard", "text": "You're in no condition to fight. Rest and recover."}
    ],
    "low_gold": [
      {"speaker": "merchant", "text": "Times are tough? I might have some odd jobs if you need coin."},
      {"speaker": "villager", "text": "The bounty board has work for those willing to take it."},
      {"speaker": "beggar", "text": "Even less than me? Here, take this coin. You need it more."}
    ],
    "damaged_equipment": [
      {"speaker": "blacksmith", "text": "That equipment's seen better days. Bring it to my forge."},
      {"speaker": "guard", "text": "Your gear's falling apart! Don't go into battle like that."},
      {"speaker": "villager", "text": "I can hear your armor creaking from here. Get it repaired!"}
    ],
    "high_corruption_area": [
      {"speaker": "guard", "text": "The Corruption is thick here. Watch yourself."},
      {"speaker": "ranger", "text": "This area's nearly lost. Be careful, defender."},
      {"speaker": "villager", "text": "Why would anyone come here willingly? Turn back!"}
    ]
  }
}
```

---

## Dialogue Tags and Modifiers

### Emotion Modifiers

```json
{
  "modifiers": {
    "emphasis": {
      "format": "*text*",
      "description": "Italicized for emphasis"
    },
    "shout": {
      "format": "TEXT",
      "description": "All caps for shouting"
    },
    "whisper": {
      "format": "(text)",
      "description": "Parentheses for whispered speech"
    },
    "stutter": {
      "format": "t-text",
      "description": "Hyphenated for stuttering"
    },
    "pause": {
      "format": "text... text",
      "description": "Ellipsis for dramatic pauses"
    },
    "action": {
      "format": "[action]",
      "description": "Brackets for non-verbal actions"
    },
    "sfx": {
      "format": "*sound*",
      "description": "Sound effects in asterisks"
    }
  }
}
```

### Voice Line Audio Cues

```json
{
  "audio_cues": {
    "elder_typhos": {
      "voice_type": "elderly_male",
      "accent": "wise_mentor",
      "pitch": 0.9,
      "reverb": 0.1
    },
    "lyra": {
      "voice_type": "adult_female",
      "accent": "friendly_innkeeper",
      "pitch": 1.0,
      "reverb": 0.0
    },
    "garrett": {
      "voice_type": "adult_male",
      "accent": "gruff_craftsman",
      "pitch": 0.85,
      "reverb": 0.2
    },
    "helena": {
      "voice_type": "adult_female",
      "accent": "military_commander",
      "pitch": 0.95,
      "reverb": 0.1
    },
    "marcus": {
      "voice_type": "adult_male",
      "accent": "scholarly",
      "pitch": 1.05,
      "reverb": 0.3
    },
    "thrain": {
      "voice_type": "adult_male",
      "accent": "dwarven",
      "pitch": 0.8,
      "reverb": 0.4
    },
    "vera": {
      "voice_type": "adult_female",
      "accent": "mystical",
      "pitch": 1.1,
      "reverb": 0.5
    },
    "grove_guardian": {
      "voice_type": "creature",
      "accent": "ancient_spirit",
      "pitch": 0.5,
      "reverb": 0.8
    },
    "mist_wraith": {
      "voice_type": "spectral",
      "accent": "whispering",
      "pitch": 1.2,
      "reverb": 0.9
    }
  }
}
```

---

## Implementation Notes

### Dialogue Loading

```gdscript
# Example dialogue loader structure
func load_dialogue(dialogue_id: String) -> Dictionary:
    var path = "res://data/dialogue/" + dialogue_id + ".json"
    var file = FileAccess.open(path, FileAccess.READ)
    return JSON.parse_string(file.get_as_text())

func start_dialogue(dialogue_id: String, starting_node: String = "greeting") -> void:
    current_dialogue = load_dialogue(dialogue_id)
    current_node = find_valid_node(starting_node)
    display_node(current_node)

func find_valid_node(node_id: String) -> Dictionary:
    for node in current_dialogue.nodes:
        if node.node_id == node_id:
            if evaluate_condition(node.get("condition", "")):
                return node
    return current_dialogue.nodes[0]  # Fallback to first node
```

### Variable Substitution

```gdscript
func substitute_variables(text: String) -> String:
    var result = text
    result = result.replace("{player_name}", PlayerData.name)
    result = result.replace("{wpm}", str(PlayerData.wpm))
    result = result.replace("{accuracy}", str(PlayerData.accuracy))
    result = result.replace("{gold}", str(PlayerData.gold))
    result = result.replace("{level}", str(PlayerData.level))
    result = result.replace("{region}", WorldState.current_region)
    result = result.replace("{time_of_day}", WorldState.time_of_day)
    return result
```

### Dialogue File Organization

```
data/dialogue/
├── tutorial/
│   ├── typhos_intro.json
│   ├── typhos_tutorial_progress.json
│   └── typhos_postgame.json
├── village/
│   ├── lyra_standard.json
│   ├── garrett_shop.json
│   ├── garrett_quest.json
│   └── elise_standard.json
├── quest_givers/
│   ├── helena_standard.json
│   └── marcus_standard.json
├── regional/
│   ├── evergrove/
│   │   └── sylva_standard.json
│   ├── stonepass/
│   │   └── thrain_standard.json
│   └── mistfen/
│       └── vera_standard.json
├── bosses/
│   ├── grove_guardian.json
│   ├── stone_colossus.json
│   └── mist_wraith.json
└── ambient/
    ├── weather.json
    ├── time_of_day.json
    ├── achievements.json
    └── warnings.json
```

---

**Document version:** 1.0
**Total dialogue nodes:** 200+
**Total unique NPCs:** 15+
**Coverage:** Tutorial, Village, Regional, Bosses, Ambient
