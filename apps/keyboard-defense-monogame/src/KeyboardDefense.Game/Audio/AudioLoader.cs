using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Xna.Framework.Audio;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Game.Audio;

/// <summary>
/// Loads WAV audio files from Content/Audio/ and registers them with AudioManager.
/// Uses SoundEffect.FromStream() for direct WAV loading (no MGCB pipeline needed).
/// </summary>
public static class AudioLoader
{
    /// <summary>
    /// Map from WAV filename (without extension) to AudioManager.Sfx enum value.
    /// </summary>
    private static readonly Dictionary<string, AudioManager.Sfx> SfxMap = new()
    {
        ["ui_keytap"] = AudioManager.Sfx.UiKeytap,
        ["ui_confirm"] = AudioManager.Sfx.UiConfirm,
        ["ui_cancel"] = AudioManager.Sfx.UiCancel,
        ["ui_hover"] = AudioManager.Sfx.UiHover,
        ["ui_error"] = AudioManager.Sfx.UiError,
        ["ui_open"] = AudioManager.Sfx.UiOpen,
        ["ui_close"] = AudioManager.Sfx.UiClose,
        ["type_correct"] = AudioManager.Sfx.TypeCorrect,
        ["type_mistake"] = AudioManager.Sfx.TypeWrong,
        ["type_backspace"] = AudioManager.Sfx.TypeBackspace,
        ["word_complete"] = AudioManager.Sfx.WordComplete,
        ["word_perfect"] = AudioManager.Sfx.WordPerfect,
        ["word_failed"] = AudioManager.Sfx.WordFailed,
        ["combo_up"] = AudioManager.Sfx.ComboUp,
        ["combo_break"] = AudioManager.Sfx.ComboBreak,
        ["combo_max"] = AudioManager.Sfx.ComboMax,
        ["hit_enemy"] = AudioManager.Sfx.EnemyHit,
        ["enemy_death"] = AudioManager.Sfx.EnemyDeath,
        ["enemy_spawn"] = AudioManager.Sfx.EnemySpawn,
        ["enemy_reach_base"] = AudioManager.Sfx.EnemyReachBase,
        ["hit_player"] = AudioManager.Sfx.EnemyReachBase,
        ["boss_appear"] = AudioManager.Sfx.BossAppear,
        ["boss_roar"] = AudioManager.Sfx.BossRoar,
        ["boss_defeated"] = AudioManager.Sfx.BossDefeat,
        ["tower_shot"] = AudioManager.Sfx.TowerShot,
        ["tower_arrow"] = AudioManager.Sfx.TowerShot,
        ["tower_build"] = AudioManager.Sfx.TowerBuild,
        ["build_place"] = AudioManager.Sfx.TowerBuild,
        ["tower_upgrade"] = AudioManager.Sfx.TowerUpgrade,
        ["upgrade_purchase"] = AudioManager.Sfx.TowerUpgrade,
        ["tower_sell"] = AudioManager.Sfx.TowerSell,
        ["wave_start"] = AudioManager.Sfx.WaveStart,
        ["wave_complete"] = AudioManager.Sfx.WaveComplete,
        ["wave_end"] = AudioManager.Sfx.WaveComplete,
        ["night_fall"] = AudioManager.Sfx.NightFall,
        ["dawn_break"] = AudioManager.Sfx.DawnBreak,
        ["gold_pickup"] = AudioManager.Sfx.GoldPickup,
        ["resource_pickup"] = AudioManager.Sfx.GoldPickup,
        ["xp_gain"] = AudioManager.Sfx.XpGain,
        ["level_up"] = AudioManager.Sfx.LevelUp,
        ["heal"] = AudioManager.Sfx.Heal,
        ["heal_tick"] = AudioManager.Sfx.Heal,
        ["critical_hit"] = AudioManager.Sfx.CriticalHit,
        ["status_apply"] = AudioManager.Sfx.StatusApply,
        ["status_expire"] = AudioManager.Sfx.StatusExpire,
        ["explore"] = AudioManager.Sfx.Explore,
        ["build"] = AudioManager.Sfx.Build,
        ["build_complete"] = AudioManager.Sfx.Build,
        ["gather"] = AudioManager.Sfx.Gather,
        ["victory"] = AudioManager.Sfx.Victory,
        ["victory_fanfare"] = AudioManager.Sfx.Victory,
        ["defeat"] = AudioManager.Sfx.Defeat,
        ["defeat_stinger"] = AudioManager.Sfx.Defeat,
        ["shield_block"] = AudioManager.Sfx.ShieldBlock,
        ["shield_activate"] = AudioManager.Sfx.ShieldBlock,
        ["miss_whiff"] = AudioManager.Sfx.MissWhiff,
        ["loot_drop"] = AudioManager.Sfx.LootDrop,
        ["quest_complete"] = AudioManager.Sfx.QuestComplete,
        ["research_complete"] = AudioManager.Sfx.ResearchComplete,
        ["achievement_unlock"] = AudioManager.Sfx.AchievementUnlock,
        ["title_unlock"] = AudioManager.Sfx.TitleUnlock,
    };

    /// <summary>
    /// Map from WAV filename to MusicTrack enum.
    /// </summary>
    private static readonly Dictionary<string, AudioManager.MusicTrack> MusicMap = new()
    {
        ["menu"] = AudioManager.MusicTrack.Menu,
        ["day_calm"] = AudioManager.MusicTrack.Calm,
        ["night_tense"] = AudioManager.MusicTrack.Battle,
        ["boss_battle"] = AudioManager.MusicTrack.Boss,
        ["victory"] = AudioManager.MusicTrack.Victory,
    };

    /// <summary>
    /// Load all SFX and music from Content/Audio/ and register with AudioManager.
    /// </summary>
    public static int LoadAll()
    {
        string audioRoot = FindAudioRoot();
        int loaded = 0;

        // Load SFX
        string sfxDir = Path.Combine(audioRoot, "sfx");
        if (Directory.Exists(sfxDir))
        {
            foreach (string wavFile in Directory.GetFiles(sfxDir, "*.wav"))
            {
                string id = Path.GetFileNameWithoutExtension(wavFile);
                if (!SfxMap.TryGetValue(id, out var sfxEnum))
                    continue;

                try
                {
                    using var stream = File.OpenRead(wavFile);
                    var effect = SoundEffect.FromStream(stream);
                    AudioManager.Instance.RegisterSfx(sfxEnum, effect);
                    loaded++;
                }
                catch (Exception)
                {
                    // Non-fatal
                }
            }
        }

        // Load music
        string musicDir = Path.Combine(audioRoot, "music");
        if (Directory.Exists(musicDir))
        {
            foreach (string wavFile in Directory.GetFiles(musicDir, "*.wav"))
            {
                string id = Path.GetFileNameWithoutExtension(wavFile);
                if (!MusicMap.TryGetValue(id, out var trackEnum))
                    continue;

                try
                {
                    using var stream = File.OpenRead(wavFile);
                    var effect = SoundEffect.FromStream(stream);
                    AudioManager.Instance.RegisterMusicEffect(trackEnum, effect);
                    loaded++;
                }
                catch (Exception)
                {
                    // Non-fatal
                }
            }
        }

        return loaded;
    }

    private static string FindAudioRoot()
    {
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;

        // Walk up from executable looking for Content/Audio
        string dir = baseDir;
        for (int i = 0; i < 6; i++)
        {
            string candidate = Path.Combine(dir, "Content", "Audio");
            if (Directory.Exists(candidate))
                return candidate;
            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir) break;
            dir = parent;
        }

        return Path.Combine(baseDir, "Content", "Audio");
    }
}
