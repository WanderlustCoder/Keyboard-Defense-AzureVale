export type WordDifficulty = "easy" | "medium" | "hard";
export type WordLaneId = number;

export interface WordLaneVocabulary {
  easy?: string[];
  medium?: string[];
  hard?: string[];
}

export interface WaveVocabulary {
  wave: number;
  easy?: string[];
  medium?: string[];
  hard?: string[];
  lanes?: Record<WordLaneId, WordLaneVocabulary>;
}

export interface WordBank {
  easy: string[];
  medium: string[];
  hard: string[];
  lanes?: Record<WordLaneId, WordLaneVocabulary>;
  waves?: WaveVocabulary[];
}

export const defaultWordBank: WordBank = {
  easy: [
    "arrow",
    "shield",
    "castle",
    "tower",
    "sword",
    "flame",
    "stone",
    "river",
    "brave",
    "quick",
    "storm",
    "guard",
    "lance",
    "cloak",
    "march",
    "ember",
    "forge",
    "harp",
    "mist",
    "pike",
    "spark"
  ],
  medium: [
    "defense",
    "turret",
    "bastion",
    "ballista",
    "citadel",
    "arsenal",
    "legion",
    "warden",
    "torrent",
    "phoenix",
    "harbor",
    "rampart",
    "ironclad",
    "sentinel",
    "barracks",
    "corsair",
    "glacier",
    "outpost",
    "prowess",
    "trident"
  ],
  hard: [
    "fortitude",
    "barricade",
    "safeguard",
    "cataclysm",
    "conflagrate",
    "lightbringer",
    "retribution",
    "dominion",
    "permafrost",
    "aegiscrown",
    "sanctuary",
    "battlement",
    "celerity",
    "stormbreak",
    "vigilance",
    "aurora",
    "bulwarked",
    "cataphract",
    "interdict",
    "luminescent",
    "maelstrom",
    "steadfast"
  ],
  lanes: {
    0: {
      easy: ["dash", "blink", "flare", "swift", "spark", "glint", "tempo", "fleet", "sprint", "zest"],
      medium: ["quickstep", "skirmish", "wingtip", "gallant", "hurried", "fleetest"],
      hard: ["lightning", "afterburn", "streamline"]
    },
    1: {
      easy: ["brace", "flank", "guard", "march", "stead", "crest", "wedge", "tower"],
      medium: [
        "battler",
        "phalanx",
        "redeem",
        "stronghold",
        "vanguard",
        "fortify",
        "warband",
        "citadel",
        "broadside",
        "bulwark"
      ],
      hard: ["interlock", "reinforce", "stonewall"]
    },
    2: {
      easy: ["calm", "loom", "still", "vail", "gale", "sentry", "watch"],
      medium: [
        "aegis",
        "bastille",
        "sentinel",
        "watchman",
        "luminant",
        "keystone",
        "wardroom",
        "aetheric"
      ],
      hard: ["impenetrable", "iridescence", "transcendent", "resplendent"]
    }
  },
  waves: [
    {
      wave: 1,
      easy: ["scout", "patrol", "probe", "rumor", "trail", "trace"],
      medium: ["ambush", "flurry", "skirmish", "tracking", "intruder"],
      hard: ["incursion", "infiltrate", "vigilance"],
      lanes: {
        0: { easy: ["runner", "sprint", "dash"], medium: ["outrider", "skirmish"] },
        1: { easy: ["brace", "rank"], medium: ["vanguard"], hard: ["phalanx"] },
        2: { easy: ["watch"], medium: ["sentry"], hard: ["overwatch"] }
      }
    },
    {
      wave: 2,
      easy: ["plate", "guard", "wall", "brace", "plated", "steel"],
      medium: ["barrier", "shielding", "fortify", "barricade", "brutish"],
      hard: ["bulwark", "unyield", "unbroken"],
      lanes: {
        0: { medium: ["brutal", "crusher"], hard: ["juggernaut"] },
        1: { medium: ["phalanx", "bastion"], hard: ["interlock"] },
        2: { medium: ["hexward", "warded"], hard: ["spellguard"] }
      }
    },
    {
      wave: 3,
      easy: ["sigil", "rune", "verse", "phase", "glyph"],
      medium: ["archive", "cipher", "ritual", "arcana", "edict"],
      hard: ["archivist", "chronicle", "cataclysm", "interdict"],
      lanes: {
        0: { medium: ["ignite", "sear"], hard: ["conflagrate"] },
        1: { medium: ["chant", "incant"], hard: ["concordance"] },
        2: { medium: ["warding", "aetheric"], hard: ["luminescent"] }
      }
    }
  ]
};
