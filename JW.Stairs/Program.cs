using Microsoft.EntityFrameworkCore;
using System.Device.Spi;
using Iot.Device.Ws28xx;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.AspNetCore.Http.HttpResults;

var builder = WebApplication.CreateBuilder(args);
// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddMemoryCache();

builder.Services.AddDbContext<LedDbContext>();
var app = builder.Build();

app.UseSwagger(); // Serves the Swagger JSON
app.UseSwaggerUI(options =>
{
    // Serve the Swagger UI at the /docs endpoint
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "Remote Stairs");
    options.RoutePrefix = "docs"; // Set the Swagger UI at this route
});

var jwStairsSettings = new JWStairsSettings();
builder.Configuration.GetSection("JWStairs").Bind(jwStairsSettings);

SpiConnectionSettings settings = new(0, 0)
{
    ClockFrequency = 2_400_000,
    Mode = SpiMode.Mode0,
    DataBitLength = 8
};

using SpiDevice spi = SpiDevice.Create(settings);
var ledCount = jwStairsSettings.LedCount;
Animations? effects = new Animations(new Ws2812b(spi, ledCount), ledCount);
CancellationTokenSource cancellationTokenSource = new CancellationTokenSource();

app.MapGet("/", () => "Leds!");

app.MapGet("/scenes", async (LedDbContext db) => await db.Scenes.Select(s => new ApiScene() { Id = s.Id, Name = s.Name }).ToListAsync());

app.MapGet("/scenes/{id}", async (LedDbContext db, int id) =>
{
    var item = await db.Scenes.FindAsync(id);
    if (item == null) return Results.NotFound();
    var apiItem = new ApiScene() { Id = item.Id, Name = item.Name };
    return Results.Ok(apiItem);
});

app.MapPost("/scenes", async (LedDbContext db, ApiScene apiItem) =>
{
    Scene item = new Scene()
    {
        Name = apiItem.Name
    };
    db.Scenes.Add(item);
    await db.SaveChangesAsync();
    apiItem.Id = item.Id;
    return Results.Created($"/scenes/{item.Id}", apiItem);
});

app.MapPost("/scenes/{sceneId}/frame", async (IMemoryCache memoryCache, LedDbContext db, int sceneId, ApiFrame apiItem) =>
{
    var sceneItem = await db.Scenes.FindAsync(sceneId);
    if (sceneItem == null) return Results.NotFound();
    memoryCache.Remove(sceneItem.Name);

    return await SaveSceneFrame(db, apiItem, sceneId);
});

app.MapPost("/scenes/{sceneId}/frames", async (IMemoryCache memoryCache, LedDbContext db, int sceneId, List<ApiFrame> apiItems) =>
{
    var sceneItem = await db.Scenes.FindAsync(sceneId);
    if (sceneItem == null) return Results.NotFound();
    memoryCache.Remove(sceneItem.Name);

    foreach (var apiItem in apiItems)
    {
        var result = await SaveSceneFrame(db, apiItem, sceneId);
        if (result is BadRequest)
            return result;
    }
    return Results.Created($"/scenes/{sceneItem.Id}/frames", null);
});

app.MapGet("/scenes/{sceneId}/frames", async (LedDbContext db, int sceneId) =>
{
    var frameItems = await db.Frames.Include(f => f.Leds).Where(frame => frame.SceneId == sceneId).OrderBy(o => o.OrderNr).Select(frameItem => new ApiFrame()
    {
        OrderNr = frameItem.OrderNr,
        Leds = frameItem.Leds.Select(led => new ApiLed()
        {
            LedNr = led.LedNr,
            ColorRed = led.ColorRed,
            ColorGreen = led.ColorGreen,
            ColorBlue = led.ColorBlue,
            ColorAlpha = led.ColorAlpha
        }).ToList(),
        WaitTillNextFrame = frameItem.WaitTillNextFrame
    }).ToListAsync();
    if (frameItems == null) return Results.NotFound();
    return Results.Ok(frameItems);
});

app.MapGet("/scenes/{sceneId}/frames/{orderNr}", async (LedDbContext db, int sceneId, int orderNr) =>
{
    var frameItem = await db.Frames.Include(f => f.Leds).FirstOrDefaultAsync(frame => frame.SceneId == sceneId && frame.OrderNr == orderNr);
    if (frameItem == null) return Results.NotFound();

    var apiLeds = frameItem.Leds?.Select(led => new ApiLed()
    {
        LedNr = led.LedNr,
        ColorRed = led.ColorRed,
        ColorGreen = led.ColorGreen,
        ColorBlue = led.ColorBlue,
        ColorAlpha = led.ColorAlpha
    }).ToList() ?? new List<ApiLed>();
    var apiItem = new ApiFrame() { OrderNr = frameItem.OrderNr, Leds = apiLeds, WaitTillNextFrame = frameItem.WaitTillNextFrame };
    return Results.Ok(apiItem);
});

app.MapPut("/scenes/{id}", async (LedDbContext db, int id, ApiScene apiItem) =>
{
    var item = await db.Scenes.FindAsync(id);
    if (item == null) return Results.NotFound();

    item.Name = apiItem.Name;

    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.MapDelete("/scenes/{id}", async (LedDbContext db, int id) =>
{
    var item = await db.Scenes.FindAsync(id);
    if (item == null) return Results.NotFound();

    db.Scenes.Remove(item);
    await db.SaveChangesAsync();
    return Results.Ok();
});

app.MapGet("/shows", async (LedDbContext db) =>
{
    var shows = new List<string>(){
        "knightrider",
        "knightrider_green",
        "knightrider_blue",
        "theatrechase",
        "rainbow",
        "colorwipe",
        "color"
    };
    shows.AddRange(await db.Scenes.Select(s => s.Name).ToListAsync());
    return shows;
});

// !! ========= Animations ========= !!
app.MapGet("/animation/{show}", async (IMemoryCache memoryCache, LedDbContext db, string show, string? color, string? blankColor, int percentage = 100, bool repeat = false) =>
{
    if (percentage < 1)
        return Results.BadRequest($"Percentage is lower then 1 {percentage}%!");
    cancellationTokenSource.Cancel();
    effects.SwitchOffLeds();

    cancellationTokenSource = new CancellationTokenSource();
    Task? animationTask = null;
    switch (show)
    {
        case "knightrider":
            animationTask = Task.Run(() => effects.KnightRider(cancellationTokenSource.Token, KnightRiderColor.Red, percentage));
            break;
        case "knightrider_green":
            animationTask = Task.Run(() => effects.KnightRider(cancellationTokenSource.Token, KnightRiderColor.Green, percentage));
            break;
        case "knightrider_blue":
            animationTask = Task.Run(() => effects.KnightRider(cancellationTokenSource.Token, KnightRiderColor.Blue, percentage));
            break;
        case "theatrechase":
            if (color != null && blankColor != null)
                animationTask = Task.Run(() => effects.TheatreChase(System.Drawing.ColorTranslator.FromHtml($"#{color}"), System.Drawing.ColorTranslator.FromHtml($"#{blankColor}"), cancellationTokenSource.Token, percentage));
            break;
        case "rainbow":
            animationTask = Task.Run(() => effects.Rainbow(cancellationTokenSource.Token, percentage));
            break;
        case "colorwipe":
            if (color != null)
                animationTask = Task.Run(() => effects.ColorWipe(System.Drawing.ColorTranslator.FromHtml($"#{color}"), percentage));
            break;
        case "color":
            if (color != null)
                animationTask = Task.Run(() => effects.SetColor(System.Drawing.ColorTranslator.FromHtml($"#{color}"), ledCount));
            break;
        default:
            var scene = await memoryCache.GetOrCreateAsync(show, async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromDays(1);
                // Fetch data from database
                return await db.Scenes.Include(s => s.Frames).ThenInclude(f => f.Leds).FirstOrDefaultAsync(scene => scene.Name == show);
            });
            if (scene == null) return Results.NotFound();

            animationTask = Task.Run(() => effects.PlayScene(scene.Frames.OrderBy(o => o.OrderNr).ToList(), cancellationTokenSource, percentage, repeat));
            break;
    }

    return Results.Ok();
});

app.Run();


async Task<IResult> SaveSceneFrame(LedDbContext db, ApiFrame apiItem, int sceneId)
{
    if (apiItem.Leds == null)
    {
        apiItem.Leds = new List<ApiLed>();
        for (int i = 0; i <= ledCount; i++)
        {
            apiItem.Leds.Add(new ApiLed()
            {
                LedNr = i,
                ColorRed = 0,
                ColorGreen = 0,
                ColorBlue = 0,
                ColorAlpha = 0
            });
        }
    }

    if (apiItem.Leds.MinBy(l => l.LedNr)?.LedNr < 0 || apiItem.Leds.MaxBy(l => l.LedNr)?.LedNr > (ledCount - 1))
    {
        return Results.BadRequest($"LedNr is less then 0 or greater then {ledCount - 1} there are only {ledCount} leds.");
    }

    if (await db.Frames.AnyAsync(f => f.SceneId == sceneId && f.OrderNr == apiItem.OrderNr))
    {
        return Results.BadRequest($"Scene {sceneId} already has a ordernr {apiItem.OrderNr}!");
    }

    Frame frameItem = new Frame()
    {
        SceneId = sceneId,
        OrderNr = apiItem.OrderNr,
        WaitTillNextFrame = apiItem.WaitTillNextFrame,
    };
    db.Frames.Add(frameItem);
    await db.SaveChangesAsync();

    foreach (var led in apiItem.Leds)
    {
        Led ledItem = new Led()
        {
            LedNr = led.LedNr,
            FrameId = frameItem.Id,
            ColorRed = led.ColorRed,
            ColorGreen = led.ColorGreen,
            ColorBlue = led.ColorBlue,
            ColorAlpha = led.ColorAlpha
        };
        db.Leds.Add(ledItem);
    }
    await db.SaveChangesAsync();
    return Results.Created($"/scenes/{sceneId}/frames/{frameItem.OrderNr}", apiItem);
}