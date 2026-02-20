using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Event triggering and resolution system.
/// Ported from sim/events.gd.
/// </summary>
public static class Events
{
    public static Dictionary<string, object> TriggerEvent(GameState state, string eventId, Dictionary<string, object> eventData)
    {
        state.PendingEvent = new Dictionary<string, object>
        {
            ["event_id"] = eventId,
            ["title"] = eventData.GetValueOrDefault("title", "Unknown Event"),
            ["description"] = eventData.GetValueOrDefault("description", ""),
            ["choices"] = eventData.GetValueOrDefault("choices", new List<object>()),
        };
        return new() { ["ok"] = true, ["message"] = $"Event triggered: {eventData.GetValueOrDefault("title", eventId)}" };
    }

    public static bool HasPendingEvent(GameState state) => state.PendingEvent.Count > 0;

    public static Dictionary<string, object> SkipEvent(GameState state)
    {
        if (!HasPendingEvent(state))
            return new() { ["ok"] = false, ["error"] = "No pending event." };
        string title = state.PendingEvent.GetValueOrDefault("title", "").ToString() ?? "";
        state.PendingEvent.Clear();
        return new() { ["ok"] = true, ["message"] = $"Skipped event: {title}" };
    }

    public static Dictionary<string, object> ResolveChoice(GameState state, int choiceIndex)
    {
        if (!HasPendingEvent(state))
            return new() { ["ok"] = false, ["error"] = "No pending event." };

        var choices = state.PendingEvent.GetValueOrDefault("choices") as List<object>;
        if (choices == null || choiceIndex < 0 || choiceIndex >= choices.Count)
            return new() { ["ok"] = false, ["error"] = "Invalid choice." };

        var choice = choices[choiceIndex] as Dictionary<string, object>;
        if (choice == null)
            return new() { ["ok"] = false, ["error"] = "Invalid choice data." };

        var effects = choice.GetValueOrDefault("effects") as List<object> ?? new();
        var messages = new List<string>();

        foreach (var effect in effects)
        {
            if (effect is Dictionary<string, object> effectDict)
            {
                string msg = EventEffects.ApplyEffect(state, effectDict);
                if (!string.IsNullOrEmpty(msg)) messages.Add(msg);
            }
        }

        string eventTitle = state.PendingEvent.GetValueOrDefault("title", "").ToString() ?? "";
        state.PendingEvent.Clear();

        return new()
        {
            ["ok"] = true,
            ["message"] = $"Resolved: {eventTitle}",
            ["effects"] = messages
        };
    }
}
