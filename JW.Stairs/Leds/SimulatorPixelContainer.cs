// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

using System.Drawing;

namespace Iot.Device.Ws28xx
{
    /// <summary>
    /// Simple RGB pixel container for simulation that stores colors in a readable format
    /// </summary>
    public class SimulatorPixelContainer : RawPixelContainer
    {
        private readonly LedColor[] _ledColors;
        private Action? _onUpdate;

        public SimulatorPixelContainer(int width, int height = 1)
            : base(new byte[width * height * 3], width, height, width * 3)
        {
            _ledColors = new LedColor[width * height];
            for (int i = 0; i < _ledColors.Length; i++)
            {
                _ledColors[i] = new LedColor { R = 0, G = 0, B = 0 };
            }
        }

        /// <summary>
        /// Sets a callback to be invoked when the display is updated
        /// </summary>
        public void SetOnUpdateCallback(Action onUpdate)
        {
            _onUpdate = onUpdate;
        }

        /// <summary>
        /// Gets the LED colors array
        /// </summary>
        public LedColor[] GetLedColors() => _ledColors;

        /// <summary>
        /// Notifies that an update occurred
        /// </summary>
        public void NotifyUpdate()
        {
            _onUpdate?.Invoke();
        }

        public override void SetPixel(int x, int y, Color c, ColorOrder co = ColorOrder.RGB)
        {
            var index = y * Width + x;
            if (index >= 0 && index < _ledColors.Length)
            {
                // Apply color order transformation
                Color transformedColor;
                switch (co)
                {
                    case ColorOrder.RBG:
                        transformedColor = Color.FromArgb(0, c.R, c.B, c.G);
                        break;
                    case ColorOrder.GRB:
                        transformedColor = Color.FromArgb(0, c.G, c.R, c.B);
                        break;
                    case ColorOrder.GBR:
                        transformedColor = Color.FromArgb(0, c.G, c.B, c.R);
                        break;
                    case ColorOrder.BRG:
                        transformedColor = Color.FromArgb(0, c.B, c.R, c.G);
                        break;
                    case ColorOrder.BGR:
                        transformedColor = Color.FromArgb(0, c.B, c.G, c.R);
                        break;
                    default:
                        transformedColor = c;
                        break;
                }

                _ledColors[index] = new LedColor
                {
                    R = transformedColor.R,
                    G = transformedColor.G,
                    B = transformedColor.B
                };
            }
        }

        public override void Clear(Color color = default)
        {
            for (int i = 0; i < _ledColors.Length; i++)
            {
                _ledColors[i] = new LedColor { R = color.R, G = color.G, B = color.B };
            }
        }
    }

    /// <summary>
    /// Simple structure to hold LED color data
    /// </summary>
    public struct LedColor
    {
        public byte R { get; set; }
        public byte G { get; set; }
        public byte B { get; set; }
    }
}
