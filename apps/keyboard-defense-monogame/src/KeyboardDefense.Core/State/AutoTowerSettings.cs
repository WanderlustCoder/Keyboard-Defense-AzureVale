namespace KeyboardDefense.Core.State;

/// <summary>
/// Configuration for automated tower behavior in Kingdom Defense mode.
/// Allows players to set preferences and let towers manage themselves.
/// </summary>
public class AutoTowerSettings
{
    /// <summary>
    /// Gets or sets a value indicating whether towers may be built automatically.
    /// </summary>
    public bool AutoBuild { get; set; }
    /// <summary>
    /// Gets or sets the selected auto-build priority profile.
    /// </summary>
    public string BuildPriority { get; set; } = "balanced";
    /// <summary>
    /// Gets or sets a value indicating whether existing towers may be upgraded automatically.
    /// </summary>
    public bool AutoUpgrade { get; set; }
    /// <summary>
    /// Gets or sets a value indicating whether damaged structures may be repaired automatically.
    /// </summary>
    public bool AutoRepair { get; set; } = true;
    /// <summary>
    /// Gets or sets the minimum resource reserve percentage that auto-actions must keep.
    /// </summary>
    public int ResourceReservePercent { get; set; }

    /// <summary>
    /// Gets the supported build priority option keys.
    /// </summary>
    public static readonly string[] BuildPriorityOptions = { "offense", "defense", "balanced" };
    /// <summary>
    /// Gets the supported resource reserve percentage options.
    /// </summary>
    public static readonly int[] ReservePercentOptions = { 0, 25, 50, 75 };
}
