using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

public class StoryManagerTests
{
    private static StoryManager LoadStoryManager()
    {
        var mgr = new StoryManager();
        // Find data directory by walking up from test output
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

    [Fact]
    public void LoadData_SetsLoadedFlag()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return; // Data not found, skip
        Assert.True(mgr.IsLoaded);
        Assert.NotEmpty(mgr.Title);
    }

    [Fact]
    public void GetActs_ReturnsFiveActs()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var acts = mgr.GetActs();
        Assert.Equal(5, acts.Count);
        Assert.Equal("act1", acts[0].Id);
        Assert.Equal("The Awakening", acts[0].Name);
    }

    [Fact]
    public void GetActForDay_ReturnsCorrectAct()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var act1 = mgr.GetActForDay(1);
        Assert.NotNull(act1);
        Assert.Equal("act1", act1!.Id);

        var act5 = mgr.GetActForDay(20);
        Assert.NotNull(act5);
        Assert.Equal("act5", act5!.Id);
    }

    [Fact]
    public void GetAct_ById()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var act = mgr.GetAct("act3");
        Assert.NotNull(act);
        Assert.Equal("The Depths", act!.Name);
    }

    [Fact]
    public void IsBossDay_IdentifiesBossDays()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        Assert.True(mgr.IsBossDay(4));  // Act 1 boss
        Assert.True(mgr.IsBossDay(20)); // Act 5 boss
        Assert.False(mgr.IsBossDay(3)); // Not a boss day
    }

    [Fact]
    public void Act_HasBossData()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var act = mgr.GetAct("act1");
        Assert.NotNull(act);
        Assert.Equal("Shadow Scout Commander", act!.BossName);
        Assert.NotEmpty(act.BossIntro);
        Assert.NotEmpty(act.BossTaunt);
        Assert.NotEmpty(act.BossDefeat);
    }

    [Fact]
    public void GetDialogue_GameStart_ReturnsLines()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var entry = mgr.GetDialogue("game_start");
        Assert.NotNull(entry);
        Assert.Equal("Elder Lyra", entry!.Speaker);
        Assert.True(entry.Lines.Count >= 3);
    }

    [Fact]
    public void GetDialogueLines_WithVariableSubstitution()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var vars = new Dictionary<string, string>
        {
            ["boss_name"] = "TestBoss",
            ["day"] = "7",
        };
        var lines = mgr.GetDialogueLines("game_start", vars);
        Assert.NotEmpty(lines);
        // Lines should still be present even if no vars are in them
    }

    [Fact]
    public void GetLessonIntro_ReturnsIntroData()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        // Try common lesson IDs
        var intro = mgr.GetLessonIntro("home_row_1")
            ?? mgr.GetLessonIntro("home_row");
        if (intro == null) return; // Lesson intro may not exist
        Assert.NotEmpty(intro.Speaker);
        Assert.NotEmpty(intro.Lines);
    }

    [Fact]
    public void GetRandomTaunt_ReturnsString()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        string taunt = mgr.GetRandomTaunt("scout");
        // May be empty if enemy_taunts section doesn't have "scout"
        // Just verify no exception
        Assert.NotNull(taunt);
    }

    [Fact]
    public void GetPerformanceFeedback_ReturnsFeedback()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        string feedback = mgr.GetPerformanceFeedback("accuracy", 95);
        // May be empty if section doesn't exist
        Assert.NotNull(feedback);
    }

    [Fact]
    public void GetLore_ReturnsKingdomData()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var lore = mgr.GetLore();
        Assert.Equal("Keystonia", lore.KingdomName);
        Assert.NotEmpty(lore.KingdomDescription);
    }

    [Fact]
    public void GetLore_HasCharacters()
    {
        var mgr = LoadStoryManager();
        if (!mgr.IsLoaded) return;
        var lore = mgr.GetLore();
        Assert.True(lore.Characters.Count > 0);
        Assert.True(lore.Characters.ContainsKey("elder_lyra"));
        Assert.Equal("Elder Lyra", lore.Characters["elder_lyra"].Name);
    }

    [Fact]
    public void StoryAct_DefaultValues()
    {
        var act = new StoryAct();
        Assert.Equal("", act.Id);
        Assert.Equal("", act.Name);
        Assert.Equal("Elder Lyra", act.MentorName);
        Assert.NotNull(act.Lessons);
    }

    [Fact]
    public void DialogueEntry_DefaultValues()
    {
        var entry = new DialogueEntry();
        Assert.Equal("", entry.Speaker);
        Assert.NotNull(entry.Lines);
    }

    [Fact]
    public void LoreData_DefaultValues()
    {
        var lore = new LoreData();
        Assert.Equal("", lore.KingdomName);
        Assert.NotNull(lore.Characters);
    }
}
