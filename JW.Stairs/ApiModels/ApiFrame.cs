public class ApiFrame
{
    public int OrderNr { get; set; }
    public int WaitTillNextFrame { get; set; }
    public List<ApiLed> Leds { get; set; } = [];
}