// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

namespace Iot.Device.Ws28xx
{
    /// <summary>
    /// LED device simulator that stores LED state in memory for web visualization
    /// </summary>
    public class LedSimulator : ILedDevice
    {
        private readonly SimulatorPixelContainer _image;

        /// <summary>
        /// Constructs a LedSimulator instance
        /// </summary>
        /// <param name="width">Number of LEDs in the strip</param>
        /// <param name="height">Height of the LED array (defaults to 1 for a strip)</param>
        public LedSimulator(int width, int height = 1)
        {
            _image = new SimulatorPixelContainer(width, height);
        }

        /// <summary>
        /// Gets the backing image for the LED strip
        /// </summary>
        public RawPixelContainer Image => _image;

        /// <summary>
        /// Gets the LED colors as a simple array
        /// </summary>
        public LedColor[] GetLedColors() => _image.GetLedColors();

        /// <summary>
        /// Sets a callback to be invoked when the display is updated
        /// </summary>
        public void SetOnUpdateCallback(Action onUpdate)
        {
            _image.SetOnUpdateCallback(onUpdate);
        }

        /// <summary>
        /// Simulates sending the image to the LEDs (notifies listeners)
        /// </summary>
        public void Update()
        {
            _image.NotifyUpdate();
        }
    }
}
