// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

namespace Iot.Device.Ws28xx
{
    /// <summary>
    /// Interface for LED device drivers (hardware or simulator)
    /// </summary>
    public interface ILedDevice
    {
        /// <summary>
        /// Backing image to be updated on the driver
        /// </summary>
        RawPixelContainer Image { get; }

        /// <summary>
        /// Sends backing image to the LED driver
        /// </summary>
        void Update();
    }
}
