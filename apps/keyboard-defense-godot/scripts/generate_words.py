#!/usr/bin/env python3
"""
Word List Generator

Generates themed word lists for typing lessons.
Supports various themes, length filters, and output formats.

Usage:
    python scripts/generate_words.py --theme fantasy --count 50
    python scripts/generate_words.py --theme coding --min-length 4 --max-length 8
    python scripts/generate_words.py --charset "asdfghjkl" --count 30
    python scripts/generate_words.py --theme nature --json
"""

import argparse
import json
import random
import sys
from pathlib import Path
from typing import List, Set, Dict, Any

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


# ============================================================================
# WORD DATABASES BY THEME
# ============================================================================

THEME_WORDS: Dict[str, List[str]] = {
    "fantasy": [
        # Characters
        "knight", "wizard", "mage", "archer", "rogue", "paladin", "ranger",
        "warrior", "cleric", "druid", "bard", "monk", "sorcerer", "warlock",
        "hero", "villain", "king", "queen", "prince", "princess", "lord",
        "lady", "duke", "baron", "squire", "peasant", "merchant", "smith",
        # Creatures
        "dragon", "phoenix", "griffin", "unicorn", "pegasus", "hydra",
        "basilisk", "chimera", "golem", "elemental", "demon", "angel",
        "giant", "troll", "ogre", "goblin", "orc", "elf", "dwarf", "gnome",
        "fairy", "sprite", "nymph", "dryad", "centaur", "minotaur",
        "werewolf", "vampire", "skeleton", "zombie", "ghost", "wraith",
        "specter", "lich", "necromancer", "imp", "gargoyle", "harpy",
        # Items
        "sword", "shield", "armor", "helmet", "gauntlet", "boots",
        "staff", "wand", "orb", "amulet", "ring", "crown", "cloak",
        "robe", "scroll", "tome", "potion", "elixir", "gem", "crystal",
        "rune", "sigil", "artifact", "relic", "treasure", "gold",
        # Magic
        "spell", "enchant", "curse", "hex", "charm", "ward", "barrier",
        "portal", "summon", "banish", "heal", "smite", "blast", "bolt",
        "flame", "frost", "storm", "thunder", "lightning", "shadow",
        "light", "dark", "void", "arcane", "divine", "infernal", "mystic",
        # Places
        "castle", "tower", "dungeon", "cavern", "forest", "mountain",
        "valley", "river", "lake", "ocean", "island", "kingdom", "realm",
        "empire", "citadel", "fortress", "temple", "shrine", "altar",
        "crypt", "tomb", "ruins", "portal", "nexus", "sanctum", "grove",
    ],

    "coding": [
        # Keywords
        "function", "variable", "constant", "class", "object", "method",
        "property", "interface", "abstract", "static", "public", "private",
        "return", "import", "export", "module", "package", "library",
        "framework", "runtime", "compile", "execute", "debug", "test",
        # Data types
        "string", "integer", "float", "boolean", "array", "dictionary",
        "list", "tuple", "set", "map", "queue", "stack", "tree", "graph",
        "node", "pointer", "reference", "null", "void", "type", "generic",
        # Operations
        "loop", "iterate", "recursive", "async", "await", "promise",
        "callback", "event", "handler", "listener", "trigger", "dispatch",
        "parse", "serialize", "validate", "transform", "filter", "reduce",
        "sort", "search", "insert", "delete", "update", "query", "fetch",
        # Concepts
        "algorithm", "pattern", "design", "architecture", "component",
        "service", "client", "server", "database", "cache", "memory",
        "storage", "network", "protocol", "request", "response", "stream",
        "buffer", "thread", "process", "instance", "singleton", "factory",
        # Tools
        "editor", "terminal", "console", "debugger", "profiler", "logger",
        "linter", "formatter", "bundler", "compiler", "interpreter",
        "version", "branch", "commit", "merge", "deploy", "release",
    ],

    "nature": [
        # Trees
        "oak", "pine", "maple", "willow", "birch", "cedar", "spruce",
        "elm", "ash", "beech", "hickory", "walnut", "cherry", "apple",
        "redwood", "sequoia", "cypress", "palm", "bamboo", "fern",
        # Flowers
        "rose", "lily", "tulip", "daisy", "orchid", "violet", "iris",
        "lotus", "jasmine", "lavender", "sunflower", "poppy", "peony",
        "carnation", "dahlia", "magnolia", "hibiscus", "marigold",
        # Animals
        "wolf", "bear", "deer", "fox", "rabbit", "squirrel", "owl",
        "eagle", "hawk", "falcon", "raven", "crow", "sparrow", "robin",
        "salmon", "trout", "bass", "pike", "catfish", "sturgeon",
        "butterfly", "dragonfly", "beetle", "bee", "wasp", "ant",
        # Terrain
        "mountain", "valley", "canyon", "cliff", "ridge", "peak",
        "forest", "jungle", "meadow", "prairie", "desert", "tundra",
        "swamp", "marsh", "bog", "wetland", "lake", "river", "stream",
        "waterfall", "spring", "pond", "ocean", "sea", "bay", "cove",
        # Weather
        "rain", "snow", "sleet", "hail", "fog", "mist", "cloud",
        "storm", "thunder", "lightning", "wind", "breeze", "gale",
        "tornado", "hurricane", "blizzard", "drought", "flood",
        # Seasons
        "spring", "summer", "autumn", "winter", "dawn", "dusk",
        "sunrise", "sunset", "twilight", "midnight", "noon",
    ],

    "medieval": [
        # Weapons
        "sword", "dagger", "axe", "mace", "flail", "halberd", "spear",
        "lance", "pike", "crossbow", "longbow", "arrow", "bolt", "shield",
        "buckler", "catapult", "trebuchet", "battering", "ram",
        # Armor
        "helm", "helmet", "coif", "mail", "chainmail", "plate", "armor",
        "cuirass", "greaves", "gauntlet", "vambrace", "pauldron",
        "gorget", "sabaton", "gambeson", "surcoat", "tabard",
        # Structures
        "castle", "keep", "tower", "wall", "gate", "drawbridge", "moat",
        "battlement", "parapet", "turret", "dungeon", "cellar", "hall",
        "chamber", "throne", "chapel", "cloister", "monastery", "abbey",
        "cathedral", "market", "tavern", "inn", "smithy", "stable",
        # Roles
        "king", "queen", "prince", "princess", "lord", "lady", "knight",
        "squire", "page", "herald", "steward", "chamberlain", "chancellor",
        "bishop", "priest", "monk", "nun", "peasant", "serf", "freeman",
        "merchant", "artisan", "blacksmith", "carpenter", "mason",
        # Activities
        "joust", "tournament", "siege", "battle", "crusade", "quest",
        "feast", "hunt", "falconry", "archery", "swordplay", "duel",
    ],

    "science": [
        # Physics
        "atom", "electron", "proton", "neutron", "quark", "photon",
        "energy", "force", "mass", "velocity", "momentum", "gravity",
        "wave", "particle", "quantum", "nuclear", "fusion", "fission",
        "radiation", "magnetic", "electric", "thermal", "kinetic",
        # Chemistry
        "element", "compound", "molecule", "bond", "reaction", "catalyst",
        "acid", "base", "solution", "mixture", "crystal", "polymer",
        "organic", "inorganic", "oxide", "sulfate", "chloride", "nitrate",
        # Biology
        "cell", "nucleus", "membrane", "protein", "enzyme", "gene",
        "chromosome", "mutation", "evolution", "species", "organism",
        "bacteria", "virus", "fungus", "plant", "animal", "tissue",
        "organ", "system", "metabolism", "respiration", "photosynthesis",
        # Space
        "star", "planet", "moon", "asteroid", "comet", "meteor",
        "galaxy", "nebula", "supernova", "quasar", "pulsar", "blackhole",
        "orbit", "gravity", "light", "cosmos", "universe", "solar",
        # Math
        "number", "integer", "fraction", "decimal", "percent", "ratio",
        "equation", "formula", "variable", "constant", "function",
        "graph", "vector", "matrix", "calculus", "algebra", "geometry",
    ],

    "common": [
        # Most common English words (useful for practice)
        "the", "and", "for", "are", "but", "not", "you", "all", "can",
        "had", "her", "was", "one", "our", "out", "day", "get", "has",
        "him", "his", "how", "its", "may", "new", "now", "old", "see",
        "two", "way", "who", "boy", "did", "own", "say", "she", "too",
        "use", "been", "call", "come", "each", "find", "from", "have",
        "here", "just", "know", "like", "long", "make", "many", "more",
        "much", "must", "name", "only", "over", "part", "said", "same",
        "some", "take", "than", "them", "then", "they", "this", "time",
        "very", "want", "well", "what", "when", "with", "word", "work",
        "year", "about", "after", "being", "could", "every", "first",
        "found", "great", "house", "large", "learn", "never", "other",
        "place", "point", "right", "small", "sound", "spell", "still",
        "study", "their", "there", "these", "thing", "think", "three",
        "under", "water", "where", "which", "while", "world", "would",
        "write", "people", "before", "called", "change", "around",
    ],

    "bigrams": [
        # Words with common bigrams (th, er, on, an, etc.)
        "the", "there", "them", "then", "other", "another", "weather",
        "whether", "rather", "gather", "father", "mother", "brother",
        "earth", "worth", "birth", "north", "south", "youth", "truth",
        "her", "here", "where", "every", "ever", "never", "over",
        "under", "wonder", "thunder", "blunder", "plunder", "tender",
        "render", "sender", "gender", "fender", "vendor", "mentor",
        "enter", "center", "winter", "hunter", "butter", "letter",
        "better", "matter", "latter", "batter", "scatter", "shatter",
        "chatter", "flatter", "pattern", "lantern", "eastern", "western",
    ],

    "double_letters": [
        # Words with double letters
        "book", "look", "took", "cook", "hook", "nook", "brook", "crook",
        "stood", "good", "wood", "hood", "food", "mood", "blood", "flood",
        "cool", "fool", "pool", "tool", "wool", "school", "drool", "spool",
        "ball", "call", "fall", "hall", "mall", "tall", "wall", "small",
        "bell", "cell", "dell", "fell", "hell", "sell", "tell", "well",
        "bill", "fill", "gill", "hill", "kill", "mill", "pill", "will",
        "doll", "poll", "roll", "toll", "full", "bull", "pull", "skull",
        "bass", "boss", "fuss", "hiss", "kiss", "loss", "mass", "mess",
        "miss", "moss", "pass", "toss", "buzz", "fizz", "fuzz", "jazz",
        "class", "glass", "grass", "brass", "cross", "dress", "press",
        "bless", "chess", "guess", "stress", "access", "assess", "success",
    ],
}


# ============================================================================
# CHARSET-BASED GENERATION
# ============================================================================

def generate_from_charset(charset: str, count: int, min_len: int, max_len: int) -> List[str]:
    """Generate pseudo-words from a character set."""
    words = set()
    charset = charset.lower()
    vowels = set("aeiou") & set(charset)
    consonants = set(charset) - vowels

    # If no vowels, just generate random strings
    if not vowels:
        while len(words) < count:
            length = random.randint(min_len, max_len)
            word = "".join(random.choice(charset) for _ in range(length))
            words.add(word)
        return list(words)

    # Generate pronounceable-ish words
    while len(words) < count:
        length = random.randint(min_len, max_len)
        word = []
        use_vowel = random.choice([True, False])

        for _ in range(length):
            if use_vowel and vowels:
                word.append(random.choice(list(vowels)))
            elif consonants:
                word.append(random.choice(list(consonants)))
            else:
                word.append(random.choice(charset))
            use_vowel = not use_vowel

        words.add("".join(word))

    return list(words)


# ============================================================================
# FILTERING
# ============================================================================

def filter_by_length(words: List[str], min_len: int, max_len: int) -> List[str]:
    """Filter words by length."""
    return [w for w in words if min_len <= len(w) <= max_len]


def filter_by_charset(words: List[str], charset: str) -> List[str]:
    """Filter words to only use characters from charset."""
    charset_set = set(charset.lower())
    return [w for w in words if all(c in charset_set for c in w.lower())]


def deduplicate(words: List[str]) -> List[str]:
    """Remove duplicates while preserving order."""
    seen = set()
    result = []
    for w in words:
        w_lower = w.lower()
        if w_lower not in seen:
            seen.add(w_lower)
            result.append(w_lower)
    return result


# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

def format_as_json(words: List[str], theme: str) -> str:
    """Format words as JSON for lessons.json."""
    return json.dumps(words, indent=2)


def format_as_lesson(words: List[str], lesson_id: str, name: str, description: str) -> str:
    """Format as a complete lesson entry."""
    lesson = {
        "id": lesson_id,
        "name": name,
        "description": description,
        "mode": "wordlist",
        "wordlist": words,
        "lengths": {
            "scout": [3, 4],
            "raider": [4, 6],
            "armored": [6, 8]
        }
    }
    return json.dumps(lesson, indent=2)


def format_as_list(words: List[str]) -> str:
    """Format as simple newline-separated list."""
    return "\n".join(words)


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Generate themed word lists for typing lessons")
    parser.add_argument("--theme", "-t", choices=list(THEME_WORDS.keys()),
                        help="Theme for word generation")
    parser.add_argument("--charset", "-c", type=str,
                        help="Generate from character set (e.g., 'asdfghjkl')")
    parser.add_argument("--count", "-n", type=int, default=50,
                        help="Number of words to generate (default: 50)")
    parser.add_argument("--min-length", type=int, default=3,
                        help="Minimum word length (default: 3)")
    parser.add_argument("--max-length", type=int, default=10,
                        help="Maximum word length (default: 10)")
    parser.add_argument("--json", "-j", action="store_true",
                        help="Output as JSON array")
    parser.add_argument("--lesson", type=str,
                        help="Output as complete lesson entry with given ID")
    parser.add_argument("--name", type=str, default="Generated Lesson",
                        help="Lesson name (used with --lesson)")
    parser.add_argument("--description", type=str, default="Auto-generated word list",
                        help="Lesson description (used with --lesson)")
    parser.add_argument("--filter-charset", type=str,
                        help="Filter theme words to only use these characters")
    parser.add_argument("--list-themes", action="store_true",
                        help="List available themes and exit")
    parser.add_argument("--seed", type=int,
                        help="Random seed for reproducibility")

    args = parser.parse_args()

    if args.list_themes:
        print("Available themes:")
        for theme, words in THEME_WORDS.items():
            print(f"  {theme}: {len(words)} words")
        sys.exit(0)

    if args.seed is not None:
        random.seed(args.seed)

    # Generate or select words
    words: List[str] = []

    if args.charset:
        words = generate_from_charset(
            args.charset,
            args.count,
            args.min_length,
            args.max_length
        )
        theme_name = f"charset_{args.charset[:10]}"
    elif args.theme:
        words = THEME_WORDS[args.theme].copy()
        theme_name = args.theme

        # Apply charset filter if specified
        if args.filter_charset:
            words = filter_by_charset(words, args.filter_charset)

        # Apply length filter
        words = filter_by_length(words, args.min_length, args.max_length)

        # Shuffle and limit
        random.shuffle(words)
        words = words[:args.count]
    else:
        print("Error: Specify either --theme or --charset")
        sys.exit(1)

    # Deduplicate
    words = deduplicate(words)

    # Sort alphabetically for consistency
    words.sort()

    # Output
    if args.lesson:
        print(format_as_lesson(words, args.lesson, args.name, args.description))
    elif args.json:
        print(format_as_json(words, theme_name))
    else:
        print(f"Generated {len(words)} words:\n")
        print(format_as_list(words))


if __name__ == "__main__":
    main()
