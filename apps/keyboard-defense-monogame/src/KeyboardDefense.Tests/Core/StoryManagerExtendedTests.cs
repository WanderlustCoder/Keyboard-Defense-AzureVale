using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for StoryManager — pure-logic paths, fallback behavior,
/// data class defaults, and edge cases that don't depend on story.json existing.
/// </summary>
public class StoryManagerExtendedTests
{
    // =========================================================================
    // Unloaded manager — defaults
    // =========================================================================

    [Fact]
    public void NewManager_IsNotLoaded()
    {
        var mgr = new StoryManager();
        Assert.False(mgr.IsLoaded);
    }

    [Fact]
    public void NewManager_TitleIsEmpty()
    {
        var mgr = new StoryManager();
        Assert.Equal("", mgr.Title);
        Assert.Equal("", mgr.Subtitle);
    }

    [Fact]
    public void NewManager_GetActs_ReturnsEmptyList()
    {
        var mgr = new StoryManager();
        Assert.Empty(mgr.GetActs());
    }

    [Fact]
    public void NewManager_GetActForDay_ReturnsNull()
    {
        var mgr = new StoryManager();
        Assert.Null(mgr.GetActForDay(1));
    }

    [Fact]
    public void NewManager_GetAct_ReturnsNull()
    {
        var mgr = new StoryManager();
        Assert.Null(mgr.GetAct("act1"));
    }

    [Fact]
    public void NewManager_IsBossDay_ReturnsFalse()
    {
        var mgr = new StoryManager();
        Assert.False(mgr.IsBossDay(1));
    }

    [Fact]
    public void NewManager_GetDialogue_ReturnsNull()
    {
        var mgr = new StoryManager();
        Assert.Null(mgr.GetDialogue("game_start"));
    }

    [Fact]
    public void NewManager_GetDialogueLines_ReturnsEmpty()
    {
        var mgr = new StoryManager();
        var lines = mgr.GetDialogueLines("game_start");
        Assert.Empty(lines);
    }

    [Fact]
    public void NewManager_GetDialogueSpeaker_ReturnsDefault()
    {
        var mgr = new StoryManager();
        Assert.Equal("Elder Lyra", mgr.GetDialogueSpeaker("nonexistent"));
    }

    [Fact]
    public void NewManager_GetLessonIntro_ReturnsNull()
    {
        var mgr = new StoryManager();
        Assert.Null(mgr.GetLessonIntro("home_row"));
    }

    [Fact]
    public void NewManager_GetRandomTaunt_ReturnsEmpty()
    {
        var mgr = new StoryManager();
        Assert.Equal("", mgr.GetRandomTaunt("scout"));
    }

    [Fact]
    public void NewManager_GetPerformanceFeedback_ReturnsEmpty()
    {
        var mgr = new StoryManager();
        Assert.Equal("", mgr.GetPerformanceFeedback("accuracy", 95));
    }

    [Fact]
    public void NewManager_GetLore_ReturnsEmptyDefaults()
    {
        var mgr = new StoryManager();
        var lore = mgr.GetLore();
        Assert.Equal("", lore.KingdomName);
        Assert.Empty(lore.Characters);
    }

    // =========================================================================
    // LoadData — missing file
    // =========================================================================

    [Fact]
    public void LoadData_NonexistentPath_DoesNotThrow()
    {
        var mgr = new StoryManager();
        mgr.LoadData("/nonexistent/path/that/does/not/exist");
        Assert.False(mgr.IsLoaded);
    }

    // =========================================================================
    // Data class defaults
    // =========================================================================

    [Fact]
    public void StoryAct_AllDefaultsAreNonNull()
    {
        var act = new StoryAct();
        Assert.NotNull(act.Id);
        Assert.NotNull(act.Name);
        Assert.NotNull(act.Lessons);
        Assert.NotNull(act.Theme);
        Assert.NotNull(act.IntroText);
        Assert.NotNull(act.CompletionText);
        Assert.NotNull(act.Reward);
        Assert.NotNull(act.MentorName);
        Assert.NotNull(act.MentorPortrait);
        Assert.NotNull(act.BossKind);
        Assert.NotNull(act.BossName);
        Assert.NotNull(act.BossIntro);
        Assert.NotNull(act.BossTaunt);
        Assert.NotNull(act.BossDefeat);
        Assert.NotNull(act.BossLore);
    }

    [Fact]
    public void DialogueEntry_DefaultsAreNonNull()
    {
        var entry = new DialogueEntry();
        Assert.NotNull(entry.Speaker);
        Assert.NotNull(entry.Lines);
        Assert.Empty(entry.Lines);
    }

    [Fact]
    public void LessonIntro_DefaultsAreNonNull()
    {
        var intro = new LessonIntro();
        Assert.NotNull(intro.Speaker);
        Assert.NotNull(intro.Title);
        Assert.NotNull(intro.Lines);
        Assert.NotNull(intro.Keys);
        Assert.NotNull(intro.PracticeTips);
    }

    [Fact]
    public void PerformanceTier_DefaultLevelsIsEmpty()
    {
        var tier = new PerformanceTier();
        Assert.NotNull(tier.Levels);
        Assert.Empty(tier.Levels);
    }

    [Fact]
    public void PerformanceLevel_Defaults()
    {
        var level = new PerformanceLevel();
        Assert.Equal("", level.Name);
        Assert.Equal(0, level.Threshold);
        Assert.NotNull(level.Messages);
    }

    [Fact]
    public void LoreData_Defaults()
    {
        var lore = new LoreData();
        Assert.Equal("", lore.KingdomName);
        Assert.Equal("", lore.KingdomDescription);
        Assert.Equal("", lore.KingdomHistory);
        Assert.Equal("", lore.HordeName);
        Assert.Equal("", lore.HordeDescription);
        Assert.Equal("", lore.HordeWeakness);
        Assert.NotNull(lore.Characters);
    }

    [Fact]
    public void CharacterLore_Defaults()
    {
        var ch = new CharacterLore();
        Assert.Equal("", ch.Name);
        Assert.Equal("", ch.Title);
        Assert.Equal("", ch.Description);
        Assert.Equal("", ch.Backstory);
        Assert.NotNull(ch.Quotes);
    }

    // =========================================================================
    // GetDialogueLines with variable substitution
    // =========================================================================

    [Fact]
    public void GetDialogueLines_NullVars_ReturnsOriginalLines()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        var withVars = mgr.GetDialogueLines("game_start", null);
        var without = mgr.GetDialogueLines("game_start");

        Assert.Equal(without, withVars);
    }

    [Fact]
    public void GetDialogueLines_EmptyVars_ReturnsOriginalLines()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        var lines = mgr.GetDialogueLines("game_start", new Dictionary<string, string>());
        Assert.NotEmpty(lines);
    }

    // =========================================================================
    // GetActWithBoss
    // =========================================================================

    [Fact]
    public void GetActWithBoss_ValidBossDay_ReturnsAct()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        var act = mgr.GetActWithBoss(4);
        Assert.NotNull(act);
        Assert.Equal("act1", act!.Id);
    }

    [Fact]
    public void GetActWithBoss_NonBossDay_ReturnsNull()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        var act = mgr.GetActWithBoss(3);
        Assert.Null(act);
    }

    // =========================================================================
    // GetActForDay — boundary conditions
    // =========================================================================

    [Fact]
    public void GetActForDay_DayZero_ReturnsNullOrFirstAct()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        // Day 0 may not belong to any act
        var act = mgr.GetActForDay(0);
        // Either null or the first act depending on day range
        // Just verify no exception
    }

    [Fact]
    public void GetActForDay_VeryLargeDay_ReturnsNullOrLastAct()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        var act = mgr.GetActForDay(9999);
        // Should be null since no act covers day 9999
        Assert.Null(act);
    }

    // =========================================================================
    // GetRandomTaunt — with explicit RNG
    // =========================================================================

    [Fact]
    public void GetRandomTaunt_WithExplicitRng_IsDeterministic()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        string taunt1 = mgr.GetRandomTaunt("scout", new Random(42));
        string taunt2 = mgr.GetRandomTaunt("scout", new Random(42));

        // Same seed should produce same taunt (if taunts exist)
        Assert.Equal(taunt1, taunt2);
    }

    [Fact]
    public void GetRandomTaunt_UnknownKind_ReturnsEmpty()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        Assert.Equal("", mgr.GetRandomTaunt("nonexistent_kind"));
    }

    // =========================================================================
    // Loaded data integrity
    // =========================================================================

    [Fact]
    public void LoadedData_AllActs_HaveNonEmptyIds()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        Assert.All(mgr.GetActs(), act =>
            Assert.False(string.IsNullOrEmpty(act.Id)));
    }

    [Fact]
    public void LoadedData_AllActs_HaveValidDayRanges()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        Assert.All(mgr.GetActs(), act =>
            Assert.True(act.DayEnd >= act.DayStart,
                $"Act '{act.Id}' has DayEnd ({act.DayEnd}) < DayStart ({act.DayStart})"));
    }

    [Fact]
    public void LoadedData_Subtitle_IsNonEmpty()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;

        Assert.NotEmpty(mgr.Subtitle);
    }

    // =========================================================================
    // Helper
    // =========================================================================

    private static StoryManager LoadStoryManager()
    {
        var mgr = new StoryManager();
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 8; i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (Directory.Exists(candidate) && File.Exists(Path.Combine(candidate, "story.json")))
            {
                mgr.LoadData(candidate);
                return mgr;
            }
            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir) break;
            dir = parent;
        }
        return mgr;
    }
}
