/// <summary>
/// Represents a scene that contains animation frames for the LED staircase.
/// </summary>
public class ApiScene
{
    /// <summary>
    /// The unique identifier of the scene. Auto-generated on creation.
    /// </summary>
    /// <example>1</example>
    public int Id { get; set; }

    /// <summary>
    /// The name of the scene, used to reference it when playing animations.
    /// </summary>
    /// <example>my_cool_show</example>
    public required string Name { get; set; }
}