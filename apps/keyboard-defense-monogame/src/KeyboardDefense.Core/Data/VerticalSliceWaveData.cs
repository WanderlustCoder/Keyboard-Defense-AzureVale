using System;
using System.IO;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Vertical-slice one-wave profile data.
/// Loads data/vertical_slice_wave.json and provides validated defaults.
/// </summary>
public static class VerticalSliceWaveData
{
    private static VerticalSliceWaveProfile _profile = VerticalSliceWaveProfile.CreateDefault();

    public static VerticalSliceWaveProfile Current => _profile;

    public static void LoadData(string dataDir)
    {
        _profile = VerticalSliceWaveProfile.CreateDefault();

        var path = Path.Combine(dataDir, "vertical_slice_wave.json");
        if (!File.Exists(path))
            return;

        try
        {
            var text = File.ReadAllText(path);
            var root = JObject.Parse(text);
            _profile = ParseAndValidate(root, _profile);
        }
        catch
        {
            _profile = VerticalSliceWaveProfile.CreateDefault();
        }
    }

    private static VerticalSliceWaveProfile ParseAndValidate(JObject root, VerticalSliceWaveProfile fallback)
    {
        var start = root["start_state"] as JObject;
        var wave = root["wave"] as JObject;

        string version = ReadString(root["version"], fallback.Version);
        string profileId = ReadString(root["profile_id"], fallback.ProfileId);
        string description = ReadString(root["description"], fallback.Description);

        int startDay = ClampInt(ReadInt(start?["day"], fallback.StartDay), 1, 365);
        int startHp = ClampInt(ReadInt(start?["hp"], fallback.StartHp), 1, 999);
        int startGold = ClampInt(ReadInt(start?["gold"], fallback.StartGold), 0, 99999);
        int startThreat = ClampInt(ReadInt(start?["threat"], fallback.StartThreat), 0, 99);
        string lessonId = LessonsData.NormalizeLessonId(ReadString(start?["lesson_id"], fallback.LessonId));
        bool practiceMode = ReadBool(start?["practice_mode"], fallback.PracticeMode);

        int spawnTotal = ClampInt(ReadInt(wave?["spawn_total"], fallback.WaveSpawnTotal), 1, 128);
        float spawnIntervalSeconds = ClampFloat(
            ReadFloat(wave?["spawn_interval_sec"], fallback.SpawnIntervalSeconds), 0.1f, 10f);
        float enemyStepIntervalSeconds = ClampFloat(
            ReadFloat(wave?["enemy_step_interval_sec"], fallback.EnemyStepIntervalSeconds), 0.1f, 10f);
        int enemyStepDistance = ClampInt(
            ReadInt(wave?["enemy_step_distance"], fallback.EnemyStepDistance), 1, 10);
        int enemyContactDamage = ClampInt(
            ReadInt(wave?["enemy_contact_damage"], fallback.EnemyContactDamage), 1, 50);
        int typedHitDamage = ClampInt(
            ReadInt(wave?["typed_hit_damage"], fallback.TypedHitDamage), 1, 50);
        int typedMissDamage = ClampInt(
            ReadInt(wave?["typed_miss_damage"], fallback.TypedMissDamage), 0, 50);
        int towerTickDamage = ClampInt(
            ReadInt(wave?["tower_tick_damage"], fallback.TowerTickDamage), 0, 50);

        return new VerticalSliceWaveProfile
        {
            Version = version,
            ProfileId = profileId,
            Description = description,
            StartDay = startDay,
            StartHp = startHp,
            StartGold = startGold,
            StartThreat = startThreat,
            LessonId = lessonId,
            PracticeMode = practiceMode,
            WaveSpawnTotal = spawnTotal,
            SpawnIntervalSeconds = spawnIntervalSeconds,
            EnemyStepIntervalSeconds = enemyStepIntervalSeconds,
            EnemyStepDistance = enemyStepDistance,
            EnemyContactDamage = enemyContactDamage,
            TypedHitDamage = typedHitDamage,
            TypedMissDamage = typedMissDamage,
            TowerTickDamage = towerTickDamage,
        };
    }

    private static string ReadString(JToken? token, string fallback)
    {
        var value = token?.Value<string>();
        if (string.IsNullOrWhiteSpace(value))
            return fallback;
        return value.Trim();
    }

    private static int ReadInt(JToken? token, int fallback)
    {
        if (token == null) return fallback;
        return int.TryParse(token.ToString(), out int value) ? value : fallback;
    }

    private static float ReadFloat(JToken? token, float fallback)
    {
        if (token == null) return fallback;
        return float.TryParse(token.ToString(), out float value) ? value : fallback;
    }

    private static bool ReadBool(JToken? token, bool fallback)
    {
        if (token == null) return fallback;
        return bool.TryParse(token.ToString(), out bool value) ? value : fallback;
    }

    private static int ClampInt(int value, int min, int max)
    {
        return Math.Clamp(value, min, max);
    }

    private static float ClampFloat(float value, float min, float max)
    {
        return Math.Clamp(value, min, max);
    }
}

public sealed class VerticalSliceWaveProfile
{
    public string Version { get; init; } = "1.0.0";
    public string ProfileId { get; init; } = "vertical_slice_default";
    public string Description { get; init; } = "Default single-wave profile";
    public int StartDay { get; init; } = 1;
    public int StartHp { get; init; } = 20;
    public int StartGold { get; init; } = 10;
    public int StartThreat { get; init; } = 0;
    public string LessonId { get; init; } = "full_alpha";
    public bool PracticeMode { get; init; } = false;
    public int WaveSpawnTotal { get; init; } = 6;
    public float SpawnIntervalSeconds { get; init; } = 1.0f;
    public float EnemyStepIntervalSeconds { get; init; } = 1.0f;
    public int EnemyStepDistance { get; init; } = 1;
    public int EnemyContactDamage { get; init; } = 1;
    public int TypedHitDamage { get; init; } = 2;
    public int TypedMissDamage { get; init; } = 1;
    public int TowerTickDamage { get; init; } = 1;

    public static VerticalSliceWaveProfile CreateDefault() => new();
}
