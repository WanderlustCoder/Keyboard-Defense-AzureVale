using System.Collections.Generic;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Tutorial step definitions for battle and onboarding flows.
/// Ported from scripts/BattleTutorial.gd and game/onboarding_flow.gd.
/// </summary>
public static class TutorialData
{
    // =========================================================================
    // Battle Tutorial (7 steps, trigger-based)
    // =========================================================================

    public static readonly List<BattleTutorialStep> BattleSteps = new()
    {
        new("Welcome",
            "Elder Lyra",
            "Welcome, Defender! I am Elder Lyra, and I will guide you through your first battle.",
            "Keystonia needs your typing skills to survive. Let me show you how to defend our realm.",
            null),

        new("Typing Target",
            "Elder Lyra",
            "See that enemy approaching? Each enemy carries a WORD above them.",
            "Type the word exactly and press Enter to damage the enemy. Try it now!",
            "first_word_typed"),

        new("Threat Meter",
            "Elder Lyra",
            "Well done! Notice the threat meter at the top of your HUD.",
            "As enemies approach your castle, threat increases. Keep it low by defeating enemies quickly!",
            "threat_shown"),

        new("Castle Health",
            "Elder Lyra",
            "Your castle has limited HP. When enemies reach it, they deal damage.",
            "If castle HP hits zero, the battle is lost. Watch your HP carefully!",
            "castle_damaged"),

        new("Combos & Buffs",
            "Elder Lyra",
            "Typing consecutive words correctly builds a COMBO multiplier.",
            "Higher combos mean more gold and damage! But one miss resets your streak.",
            "combo_achieved"),

        new("Victory Hint",
            "Elder Lyra",
            "Survive the night and defeat all waves to win the battle.",
            "Between nights, you can gather resources, build defenses, and upgrade.",
            "near_victory"),

        new("Tutorial Complete",
            "Elder Lyra",
            "You are ready, Defender! The fate of Keystonia rests on your fingers.",
            "Press F1 for help anytime. May your keystrokes be swift and true!",
            null),
    };

    // =========================================================================
    // Onboarding Flow (6 steps, snapshot-based)
    // =========================================================================

    public static readonly List<OnboardingStep> OnboardingSteps = new()
    {
        new("welcome_focus",
            "Welcome to Keystonia",
            "This is a keyboard-first game. All actions happen through typed commands.",
            "Try typing 'help' and pressing Enter to see available commands.",
            new[] { "used_help" }),

        new("day_actions",
            "Day Phase Actions",
            "During the day, you can gather resources, build structures, and explore.",
            "Try: 'gather wood', 'build farm', or 'explore' (each costs Action Points).",
            new[] { "did_gather", "did_build" }),

        new("end_day",
            "Ending the Day",
            "When you're ready, type 'end' to start the night defense phase.",
            "Buildings produce resources at dawn. Plan your construction!",
            new[] { "entered_night" }),

        new("night_typing",
            "Night Defense",
            "Enemies approach! Type their words to defeat them before they reach your castle.",
            "Type the exact word shown above each enemy and press Enter.",
            new[] { "hit_enemy" }),

        new("reach_dawn",
            "Surviving the Night",
            "Defeat all enemies in the wave to reach dawn safely.",
            "Type 'wait' if you need a moment. Towers auto-attack nearby enemies.",
            new[] { "reached_dawn" }),

        new("wrap_up",
            "Ready to Go!",
            "You know the basics! Explore the map, complete quests, and grow your kingdom.",
            "Press F1 for Help, F3 for Stats, F6 for Quests. Good luck, Defender!",
            new[] { "acknowledged" }),
    };
}

/// <summary>
/// A single battle tutorial step with trigger-based progression.
/// </summary>
public record BattleTutorialStep(
    string Title,
    string Speaker,
    string Line1,
    string Line2,
    string? Trigger);

/// <summary>
/// A single onboarding step with snapshot-based completion.
/// </summary>
public record OnboardingStep(
    string Id,
    string Title,
    string Description,
    string Hint,
    string[] CompletionFlags);
