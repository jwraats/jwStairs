/// <summary>
/// Represents the color state of a single LED in the strip.
/// </summary>
public class ApiLed
{
    /// <summary>
    /// The LED index in the strip (0-709). See documentation for step-to-LED mapping.
    /// </summary>
    /// <example>0</example>
    public int LedNr { get; set; }

    /// <summary>
    /// Red color channel value (0-255).
    /// </summary>
    /// <example>255</example>
    public int ColorRed { get; set; }

    /// <summary>
    /// Green color channel value (0-255).
    /// </summary>
    /// <example>113</example>
    public int ColorGreen { get; set; }

    /// <summary>
    /// Blue color channel value (0-255).
    /// </summary>
    /// <example>67</example>
    public int ColorBlue { get; set; }

    /// <summary>
    /// Alpha (transparency) channel value (0-255). Typically 0 for standard RGB strips.
    /// </summary>
    /// <example>0</example>
    public int ColorAlpha { get; set; }
}