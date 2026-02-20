using System;
using System.Collections.Generic;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Open world tick for exploration, threat, and roaming enemies.
/// Ported from sim/world_tick.gd.
/// </summary>
public static class WorldTick
{
    public const double WorldTickInterval = 1.0;
    public const double TimeAdvanceRate = 0.02;
    public const double PoiSpawnChance = 0.15;
    public const double RoamingSpawnChance = 0.10;
    public const int MaxActivePois = 5;
    public const int MaxRoamingEnemies = 8;
    public const double ThreatDecayRate = 0.01;
    public const double ThreatGrowthRate = 0.02;
    public const double WaveAssaultThreshold = 0.8;
    public const double WaveCooldownDuration = 30.0;

    public static Dictionary<string, object> Tick(GameState state, double delta)
    {
        state.WorldTickAccum += (float)delta;
        var events = new List<string>();
        bool changed = false;

        if (state.WaveCooldown > 0)
            state.WaveCooldown = (float)Math.Max(0, state.WaveCooldown - delta);

        while (state.WorldTickAccum >= WorldTickInterval)
        {
            state.WorldTickAccum -= (float)WorldTickInterval;

            state.TimeOfDay += (float)TimeAdvanceRate;
            if (state.TimeOfDay >= 1.0f)
                state.TimeOfDay -= 1.0f;

            switch (state.ActivityMode)
            {
                case "exploration":
                    TickThreatLevel(state);
                    var waveEvent = CheckWaveAssaultTrigger(state);
                    if (waveEvent != "") events.Add(waveEvent);
                    break;

                case "encounter":
                    if (state.Enemies.Count == 0)
                    {
                        EndEncounter(state);
                        events.Add("Encounter resolved. Continue exploring.");
                    }
                    break;

                case "wave_assault":
                    if (state.Enemies.Count == 0 && state.NightSpawnRemaining <= 0)
                    {
                        EndWaveAssault(state);
                        events.Add("Wave repelled! The kingdom is safe... for now.");
                    }
                    break;
            }

            changed = true;
        }

        return new Dictionary<string, object>
        {
            ["events"] = events,
            ["changed"] = changed
        };
    }

    private static string CheckWaveAssaultTrigger(GameState state)
    {
        if (state.WaveCooldown > 0) return "";
        if (state.ThreatLevel < WaveAssaultThreshold) return "";
        StartWaveAssault(state);
        return "WAVE ASSAULT! Enemies converge on the castle!";
    }

    private static void StartWaveAssault(GameState state)
    {
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        int baseSize = 2 + state.Day / 2;
        int threatBonus = (int)(state.ThreatLevel * 3);
        int waveSize = baseSize + threatBonus;
        state.NightWaveTotal = waveSize;
        state.NightSpawnRemaining = waveSize;
        state.Enemies.Clear();
        state.ThreatLevel = 0.3f;
    }

    private static void EndWaveAssault(GameState state)
    {
        state.ActivityMode = "exploration";
        state.Phase = "day";
        state.Ap = state.ApMax;
        state.WaveCooldown = (float)WaveCooldownDuration;
        state.Day++;
    }

    private static void EndEncounter(GameState state)
    {
        state.ActivityMode = "exploration";
        state.Phase = "day";
    }

    private static void TickThreatLevel(GameState state)
    {
        double contribution = 0;
        int threshold = 5;

        foreach (var entity in state.RoamingEnemies)
        {
            if (entity.GetValueOrDefault("pos") is not GridPoint pos) continue;
            int dist = Math.Abs(pos.X - state.BasePos.X) + Math.Abs(pos.Y - state.BasePos.Y);
            if (dist <= threshold)
            {
                double proximity = 1.0 + (double)(threshold - dist) / threshold;
                string zone = SimMap.GetZoneAt(state, pos);
                double zoneMult = SimMap.GetZoneThreatMultiplier(zone);
                contribution += zoneMult * proximity;
            }
        }

        if (contribution > 0)
            state.ThreatLevel = (float)Math.Min(1.0, state.ThreatLevel + ThreatGrowthRate * contribution);
        else
            state.ThreatLevel = (float)Math.Max(0.0, state.ThreatLevel - ThreatDecayRate);
    }
}
