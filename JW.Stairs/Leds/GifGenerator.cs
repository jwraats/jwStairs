// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Formats.Gif;
using SixLabors.ImageSharp.Processing;

namespace Iot.Device.Ws28xx
{
    /// <summary>
    /// Generates animated GIF previews of LED animations
    /// </summary>
    public class GifGenerator
    {
        // Stair step LED mapping
        // Zigzag wiring pattern:
        // - Odd steps (1,3,5,7,9,11,13): Left → Right (reversed = false)
        // - Even steps (2,4,6,8,10,12): Right → Left (reversed = true)
        // - Exception: Step 14 also runs Left → Right (reversed = false)
        private static readonly StepInfo[] STEPS = new[]
        {
            new StepInfo(1, 0, 47, "straight", false),
            new StepInfo(2, 48, 97, "straight", true),
            new StepInfo(3, 98, 147, "straight", false),
            new StepInfo(4, 148, 198, "straight", true),
            new StepInfo(5, 199, 248, "straight", false),
            new StepInfo(6, 249, 298, "straight", true),
            new StepInfo(7, 299, 347, "straight", false),
            new StepInfo(8, 348, 397, "straight", true),
            new StepInfo(9, 398, 451, "curved", false),
            new StepInfo(10, 452, 505, "curved", true),
            new StepInfo(11, 506, 559, "curved", false),
            new StepInfo(12, 560, 609, "top", true),
            new StepInfo(13, 610, 658, "top", false),
            new StepInfo(14, 659, 709, "top", false)
        };

        // Image dimensions
        private const int ImageWidth = 400;
        private const int ImageHeight = 500;
        private const int StepHeight = 30;
        private const int StepGap = 4;
        private const int LeftMargin = 30;
        private const int TopMargin = 30;

        /// <summary>
        /// Generates an animated GIF from a list of frames
        /// </summary>
        /// <param name="frames">List of animation frames with LED colors</param>
        /// <param name="maxFrames">Maximum number of frames to include (for performance)</param>
        /// <param name="speedMultiplier">Speed multiplier (1.0 = normal, 2.0 = 2x speed)</param>
        /// <returns>GIF image as byte array</returns>
        public byte[] GenerateGif(List<Frame> frames, int maxFrames = 100, double speedMultiplier = 1.0)
        {
            if (frames == null || frames.Count == 0)
            {
                return GenerateSingleFrameGif(new LedColor[710]);
            }

            // Limit frames for performance
            var framesToProcess = frames.Take(maxFrames).ToList();

            using var gif = new Image<Rgba32>(ImageWidth, ImageHeight);
            var gifMetaData = gif.Metadata.GetGifMetadata();
            gifMetaData.RepeatCount = 0; // Infinite loop

            bool isFirstFrame = true;
            foreach (var frame in framesToProcess)
            {
                using var frameImage = RenderFrame(frame);
                
                // Calculate frame delay (in centiseconds for GIF format)
                int delayCs = Math.Max(1, (int)(frame.WaitTillNextFrame / (10.0 * speedMultiplier)));
                
                var frameMetaData = frameImage.Frames.RootFrame.Metadata.GetGifMetadata();
                frameMetaData.FrameDelay = delayCs;
                
                if (isFirstFrame)
                {
                    // Replace the root frame
                    gif.Frames.RootFrame.ProcessPixelRows(frameImage.Frames.RootFrame, (accessor1, accessor2) =>
                    {
                        for (int y = 0; y < accessor1.Height; y++)
                        {
                            var row1 = accessor1.GetRowSpan(y);
                            var row2 = accessor2.GetRowSpan(y);
                            row2.CopyTo(row1);
                        }
                    });
                    gif.Frames.RootFrame.Metadata.GetGifMetadata().FrameDelay = delayCs;
                    isFirstFrame = false;
                }
                else
                {
                    gif.Frames.AddFrame(frameImage.Frames.RootFrame);
                }
            }

            using var ms = new MemoryStream();
            var encoder = new GifEncoder
            {
                ColorTableMode = GifColorTableMode.Local
            };
            gif.SaveAsGif(ms, encoder);
            return ms.ToArray();
        }

        /// <summary>
        /// Generates a GIF from LED colors array (single frame)
        /// </summary>
        public byte[] GenerateSingleFrameGif(LedColor[] ledColors)
        {
            using var image = RenderLedColors(ledColors);
            using var ms = new MemoryStream();
            image.SaveAsGif(ms);
            return ms.ToArray();
        }

        /// <summary>
        /// Generates a preview GIF by simulating an animation
        /// </summary>
        public async Task<byte[]> GenerateAnimationPreviewAsync(
            string animationType,
            int ledCount,
            int frameCount = 60,
            int frameDelayMs = 50,
            System.Drawing.Color? color = null,
            System.Drawing.Color? blankColor = null,
            CancellationToken cancellationToken = default)
        {
            var frames = new List<Frame>();
            var simulator = new LedSimulator(ledCount);
            var effects = new Animations(simulator, ledCount);

            // Capture frames from the animation
            var capturedFrames = new List<LedColor[]>();
            int captureCount = 0;
            
            simulator.SetOnUpdateCallback(() =>
            {
                if (captureCount < frameCount)
                {
                    var colors = simulator.GetLedColors();
                    capturedFrames.Add(colors.ToArray());
                    captureCount++;
                }
            });

            using var cts = new CancellationTokenSource();
            
            // Run animation briefly to capture frames
            Task? animationTask = null;
            switch (animationType.ToLower())
            {
                case "knightrider":
                    effects.SetColorOrder(ColorOrder.RGB);
                    animationTask = Task.Run(() => effects.KnightRider(cts.Token, 200), cancellationToken);
                    break;
                case "knightrider_green":
                    effects.SetColorOrder(ColorOrder.GRB);
                    animationTask = Task.Run(() => effects.KnightRider(cts.Token, 200), cancellationToken);
                    break;
                case "knightrider_blue":
                    effects.SetColorOrder(ColorOrder.BGR);
                    animationTask = Task.Run(() => effects.KnightRider(cts.Token, 200), cancellationToken);
                    break;
                case "rainbow":
                    animationTask = Task.Run(() => effects.Rainbow(cts.Token, 200), cancellationToken);
                    break;
                case "theatrechase":
                    var theaterColor = color ?? System.Drawing.Color.Red;
                    var theaterBlank = blankColor ?? System.Drawing.Color.Black;
                    animationTask = Task.Run(() => effects.TheatreChase(theaterColor, theaterBlank, cts.Token, 200), cancellationToken);
                    break;
                case "colorwipe":
                    var wipeColor = color ?? System.Drawing.Color.Blue;
                    animationTask = Task.Run(() => effects.ColorWipe(wipeColor, 500), cancellationToken);
                    break;
                case "color":
                    var solidColor = color ?? System.Drawing.Color.White;
                    effects.SetColor(solidColor, ledCount);
                    capturedFrames.Add(simulator.GetLedColors().ToArray());
                    break;
                default:
                    // Unknown animation - return empty frame
                    capturedFrames.Add(new LedColor[ledCount]);
                    break;
            }

            // Wait for frames to be captured
            if (animationTask != null)
            {
                var timeout = Task.Delay(Math.Max(frameCount * 20, 2000), cancellationToken);
                while (captureCount < frameCount && !timeout.IsCompleted)
                {
                    await Task.Delay(10, cancellationToken);
                }
                cts.Cancel();
            }

            // Convert captured frames to Frame objects
            foreach (var ledColors in capturedFrames)
            {
                var frame = new Frame
                {
                    OrderNr = frames.Count,
                    WaitTillNextFrame = frameDelayMs,
                    Leds = new List<Led>()
                };
                
                for (int i = 0; i < ledColors.Length; i++)
                {
                    frame.Leds.Add(new Led
                    {
                        LedNr = i,
                        ColorRed = ledColors[i].R,
                        ColorGreen = ledColors[i].G,
                        ColorBlue = ledColors[i].B,
                        ColorAlpha = 0
                    });
                }
                frames.Add(frame);
            }

            return GenerateGif(frames, frameCount, 1.0);
        }

        private Image<Rgba32> RenderFrame(Frame frame)
        {
            var ledColors = new LedColor[710];
            foreach (var led in frame.Leds)
            {
                if (led.LedNr >= 0 && led.LedNr < ledColors.Length)
                {
                    ledColors[led.LedNr] = new LedColor
                    {
                        R = (byte)Math.Clamp(led.ColorRed, 0, 255),
                        G = (byte)Math.Clamp(led.ColorGreen, 0, 255),
                        B = (byte)Math.Clamp(led.ColorBlue, 0, 255)
                    };
                }
            }
            return RenderLedColors(ledColors);
        }

        private Image<Rgba32> RenderLedColors(LedColor[] ledColors)
        {
            var image = new Image<Rgba32>(ImageWidth, ImageHeight);
            
            // Fill background
            image.Mutate(ctx => ctx.BackgroundColor(new Rgba32(15, 15, 26)));

            // Render each step (from top to bottom, step 14 at top)
            for (int i = STEPS.Length - 1; i >= 0; i--)
            {
                var step = STEPS[i];
                int yPos = TopMargin + (STEPS.Length - 1 - i) * (StepHeight + StepGap);
                
                // Calculate step width based on section
                int stepWidth = step.Section switch
                {
                    "curved" => ImageWidth - LeftMargin * 2 + 40,
                    _ => ImageWidth - LeftMargin * 2
                };
                
                int xOffset = step.Section == "curved" ? LeftMargin - 20 : LeftMargin;
                
                // Draw step background (darker)
                for (int y = yPos; y < yPos + StepHeight && y < ImageHeight; y++)
                {
                    for (int x = xOffset; x < xOffset + stepWidth && x < ImageWidth; x++)
                    {
                        if (x >= 0)
                        {
                            image[x, y] = new Rgba32(45, 55, 72);
                        }
                    }
                }
                
                // Draw LEDs
                int ledCount = step.End - step.Start + 1;
                float ledSpacing = (float)stepWidth / ledCount;
                int ledY = yPos + StepHeight / 2;
                
                for (int ledIdx = 0; ledIdx < ledCount; ledIdx++)
                {
                    // For reversed steps (even steps), reverse the LED order for display
                    // so LEDs appear left-to-right visually while wiring goes right-to-left
                    int ledNr = step.Reversed 
                        ? step.End - ledIdx  // Reversed: start from end
                        : step.Start + ledIdx; // Normal: start from start
                    var color = ledColors.Length > ledNr ? ledColors[ledNr] : new LedColor();
                    
                    int ledX = xOffset + (int)(ledIdx * ledSpacing + ledSpacing / 2);
                    
                    if (ledX >= 0 && ledX < ImageWidth && ledY < ImageHeight)
                    {
                        // Draw LED glow if color is not black
                        if (color.R > 0 || color.G > 0 || color.B > 0)
                        {
                            // Draw a small glow effect
                            for (int gy = -2; gy <= 2; gy++)
                            {
                                for (int gx = -2; gx <= 2; gx++)
                                {
                                    int px = ledX + gx;
                                    int py = ledY + gy;
                                    if (px >= 0 && px < ImageWidth && py >= 0 && py < ImageHeight)
                                    {
                                        float dist = MathF.Sqrt(gx * gx + gy * gy);
                                        float intensity = Math.Max(0, 1 - dist / 3);
                                        var existing = image[px, py];
                                        image[px, py] = new Rgba32(
                                            (byte)Math.Min(255, existing.R + (int)(color.R * intensity)),
                                            (byte)Math.Min(255, existing.G + (int)(color.G * intensity)),
                                            (byte)Math.Min(255, existing.B + (int)(color.B * intensity))
                                        );
                                    }
                                }
                            }
                            
                            // Draw LED center
                            image[ledX, ledY] = new Rgba32(color.R, color.G, color.B);
                        }
                    }
                }
                
                // Draw step number
                // (Simple approach - just mark the position)
            }

            return image;
        }

        private record StepInfo(int Step, int Start, int End, string Section, bool Reversed);
    }
}
