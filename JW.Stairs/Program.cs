using Microsoft.EntityFrameworkCore;
using System.Device.Spi;
using Iot.Device.Ws28xx;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.AspNetCore.Http.HttpResults;
using System.Text.Json.Serialization;
using System.Reflection;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);
// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "JW Stairs LED Controller",
        Version = "v1",
        Description = "REST API for controlling WS2812B LED strips on a smart staircase. "
            + "Manage scenes with animation frames, play built-in effects, or create custom light shows. "
            + "The staircase has 710 LEDs across 14 steps (LED indices 0–709)."
    });

    var xmlFilename = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFilename);
    if (File.Exists(xmlPath))
        options.IncludeXmlComments(xmlPath);
});
builder.Services.AddMemoryCache();
builder.Services.AddControllersWithViews()
    .AddJsonOptions(options => 
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

// Add CORS policy for frontend
// In production, configure allowed origins in appsettings.json under "AllowedCorsOrigins"
var allowedOrigins = builder.Configuration.GetSection("AllowedCorsOrigins").Get<string[]>();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        if (allowedOrigins != null && allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        }
        else
        {
            // Default: allow any origin for local network access (typical for IoT devices)
            policy.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        }
    });
});

builder.Services.AddDbContext<LedDbContext>();
var app = builder.Build();

// Enable CORS
app.UseCors();

// Serve static files from wwwroot (for production frontend)
app.UseDefaultFiles();
app.UseStaticFiles();

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

app.MapGet("/scenes", async (LedDbContext db) => await db.Scenes.Select(s => new ApiScene() { Id = s.Id, Name = s.Name }).ToListAsync())
    .WithName("GetScenes")
    .WithTags("Scenes")
    .WithSummary("Get all scenes")
    .WithDescription("Returns a list of all saved scenes. Each scene can contain multiple animation frames.")
    .Produces<List<ApiScene>>(StatusCodes.Status200OK);

app.MapGet("/scenes/{id}", async (LedDbContext db, int id) =>
{
    var item = await db.Scenes.FindAsync(id);
    if (item == null) return Results.NotFound();
    var apiItem = new ApiScene() { Id = item.Id, Name = item.Name };
    return Results.Ok(apiItem);
})
    .WithName("GetScene")
    .WithTags("Scenes")
    .WithSummary("Get a scene by ID")
    .WithDescription("Returns a single scene by its unique identifier.")
    .Produces<ApiScene>(StatusCodes.Status200OK)
    .ProducesProblem(StatusCodes.Status404NotFound);

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
})
    .WithName("CreateScene")
    .WithTags("Scenes")
    .WithSummary("Create a new scene")
    .WithDescription("Creates a new scene with the given name. The scene ID is auto-generated. After creation, add frames to it using the Frames endpoints.")
    .Produces<ApiScene>(StatusCodes.Status201Created);

app.MapPost("/scenes/{sceneId}/frame", async (IMemoryCache memoryCache, LedDbContext db, int sceneId, ApiFrame apiItem) =>
{
    var sceneItem = await db.Scenes.FindAsync(sceneId);
    if (sceneItem == null) return Results.NotFound();
    memoryCache.Remove(sceneItem.Name);

    return await SaveSceneFrame(db, apiItem, sceneId);
})
    .WithName("AddFrame")
    .WithTags("Frames")
    .WithSummary("Add a single frame to a scene")
    .WithDescription("Adds one animation frame to the specified scene. Each frame defines LED colors and timing. "
        + "The orderNr must be unique within the scene. If leds are omitted, all LEDs default to off.")
    .Produces<ApiFrame>(StatusCodes.Status201Created)
    .ProducesProblem(StatusCodes.Status400BadRequest)
    .ProducesProblem(StatusCodes.Status404NotFound);

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
})
    .WithName("AddFrames")
    .WithTags("Frames")
    .WithSummary("Add multiple frames to a scene")
    .WithDescription("Adds multiple animation frames to the specified scene in a single request. "
        + "Each frame's orderNr must be unique within the scene. Stops on the first validation error.")
    .Produces(StatusCodes.Status201Created)
    .ProducesProblem(StatusCodes.Status400BadRequest)
    .ProducesProblem(StatusCodes.Status404NotFound);

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
})
    .WithName("GetFrames")
    .WithTags("Frames")
    .WithSummary("Get all frames for a scene")
    .WithDescription("Returns all animation frames for the specified scene, ordered by orderNr. Each frame includes its LED color data.")
    .Produces<List<ApiFrame>>(StatusCodes.Status200OK)
    .ProducesProblem(StatusCodes.Status404NotFound);

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
})
    .WithName("GetFrame")
    .WithTags("Frames")
    .WithSummary("Get a specific frame by order number")
    .WithDescription("Returns a single frame from the specified scene, identified by its orderNr.")
    .Produces<ApiFrame>(StatusCodes.Status200OK)
    .ProducesProblem(StatusCodes.Status404NotFound);

app.MapPut("/scenes/{id}", async (LedDbContext db, int id, ApiScene apiItem) =>
{
    var item = await db.Scenes.FindAsync(id);
    if (item == null) return Results.NotFound();

    item.Name = apiItem.Name;

    await db.SaveChangesAsync();
    return Results.NoContent();
})
    .WithName("UpdateScene")
    .WithTags("Scenes")
    .WithSummary("Update a scene")
    .WithDescription("Updates the name of an existing scene.")
    .Produces(StatusCodes.Status204NoContent)
    .ProducesProblem(StatusCodes.Status404NotFound);

app.MapDelete("/scenes/{id}", async (LedDbContext db, int id) =>
{
    var item = await db.Scenes.FindAsync(id);
    if (item == null) return Results.NotFound();

    db.Scenes.Remove(item);
    await db.SaveChangesAsync();
    return Results.Ok();
})
    .WithName("DeleteScene")
    .WithTags("Scenes")
    .WithSummary("Delete a scene")
    .WithDescription("Permanently deletes a scene and all its associated frames and LED data.")
    .Produces(StatusCodes.Status200OK)
    .ProducesProblem(StatusCodes.Status404NotFound);

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
})
    .WithName("GetShows")
    .WithTags("Shows")
    .WithSummary("List all available shows")
    .WithDescription("Returns a list of all available animations, including built-in effects (knightrider, rainbow, etc.) and custom saved scenes.")
    .Produces<List<string>>(StatusCodes.Status200OK);

// !! ========= Animations ========= !!
app.MapGet("/animation/{show}", async (IMemoryCache memoryCache, LedDbContext db, string show, string? color, string? blankColor, int percentage = 100, bool repeat = false, ColorOrder colorOrder = ColorOrder.RGB) =>
{
    if (percentage < 1)
        return Results.BadRequest($"Percentage is lower then 1 {percentage}%!");
    cancellationTokenSource.Cancel();
    effects.SwitchOffLeds();
    effects.SetColorOrder(colorOrder);

    cancellationTokenSource = new CancellationTokenSource();
    Task? animationTask = null;
    switch (show)
    {
        case "knightrider":
            effects.SetColorOrder(ColorOrder.RGB);
            animationTask = Task.Run(() => effects.KnightRider(cancellationTokenSource.Token, percentage));
            break;
        case "knightrider_green":
            effects.SetColorOrder(ColorOrder.GRB);
            animationTask = Task.Run(() => effects.KnightRider(cancellationTokenSource.Token, percentage));
            break;
        case "knightrider_blue":
            effects.SetColorOrder(ColorOrder.BGR);
            animationTask = Task.Run(() => effects.KnightRider(cancellationTokenSource.Token, percentage));
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
})
    .WithName("PlayAnimation")
    .WithTags("Animations")
    .WithSummary("Play an animation or scene")
    .WithDescription("Plays a built-in animation or a custom saved scene on the LED strip. "
        + "Any currently running animation is stopped first.\n\n"
        + "**Built-in animations:** knightrider, knightrider_green, knightrider_blue, theatrechase, rainbow, colorwipe, color\n\n"
        + "**Parameters:**\n"
        + "- **show**: Animation name or custom scene name\n"
        + "- **color**: Hex color without # (e.g. `FF0000` for red). Required for: theatrechase, colorwipe, color\n"
        + "- **blankColor**: Secondary hex color without #. Required for: theatrechase\n"
        + "- **percentage**: Speed control (1-100+). 100 = normal speed, 50 = half speed, 200 = double speed\n"
        + "- **repeat**: Loop the animation continuously until another animation is started\n"
        + "- **colorOrder**: LED color channel order (RGB, RBG, GRB, GBR, BRG, BGR). Default: RGB")
    .Produces(StatusCodes.Status200OK)
    .ProducesProblem(StatusCodes.Status400BadRequest)
    .ProducesProblem(StatusCodes.Status404NotFound);

// Fallback route for SPA - serve index.html for unmatched routes
app.MapFallbackToFile("index.html");

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