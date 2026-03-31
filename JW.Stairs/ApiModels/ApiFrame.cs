/// <summary>
/// Represents a single animation frame within a scene. Each frame defines LED states and timing.
/// </summary>
public class ApiFrame
{
    /// <summary>
    /// The sequence number of this frame within the scene. Must be unique per scene.
    /// </summary>
    /// <example>0</example>
    public int OrderNr { get; set; }

    /// <summary>
    /// Milliseconds to wait before advancing to the next frame. Use 0 for static scenes.
    /// </summary>
    /// <example>100</example>
    public int WaitTillNextFrame { get; set; }

    /// <summary>
    /// The list of LEDs and their color values for this frame. If omitted, all LEDs default to off (black).
    /// </summary>
    public List<ApiLed> Leds { get; set; } = [];
}