namespace KeyboardDefense.Core.State;

/// <summary>
/// Configuration for automated tower behavior in Kingdom Defense mode.
/// Allows players to set preferences and let towers manage themselves.
/// </summary>
public class AutoTowerSettings
{
    public bool AutoBuild { get; set; }
    public string BuildPriority { get; set; } = "balanced";
    public bool AutoUpgrade { get; set; }
    public bool AutoRepair { get; set; } = true;
    public int ResourceReservePercent { get; set; }

    public static readonly string[] BuildPriorityOptions = { "offense", "defense", "balanced" };
    public static readonly int[] ReservePercentOptions = { 0, 25, 50, 75 };
}
