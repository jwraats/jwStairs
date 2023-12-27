# JW.Stairs

WIP

## Introduction

JW.Stairs is an API-driven project for controlling LED lights on staircases, alot of credits go to [dotnet/iot](https://github.com/dotnet/iot/tree/main/src/devices/Ws28xx/). It's a fun, hobbyist project, currently a work in progress, designed to bring smart lighting to for example my staircase. This project is currently used to lightup my staircase with 710 LEDs, intergrated with Home Assistant for automation, such as lighting up when someone is on the stairs and turning off after a set period.

## Features
- API for LED control.
- Animations that are from dotnet iot + some custom.
- Options to create your own scenes.

## Hardware Requirements

- Raspberry Pi Zero 2W
- LED strip WS2812B in this example.

## Software Requirements

- .NET (Optional for self-contained deployment)
- Home Assistant (for integration)

## Setup

### Raspberry Pi Configuration

1. Enable SPI on Raspberry Pi:
   ```bash
   sudo raspi-config
   ```
   Navigate to `Interface Options` and enable `SPI`.

2. Install .NET Runtime (Optional for self-contained deployment):
   ```bash
   curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel STS
   echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
   echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
   source ~/.bashrc
   ```

### Project Build and Deployment

1. Build and publish the project for Linux ARM (example):
   ```bash
   dotnet publish --runtime linux-arm --self-contained
   scp -r ./bin/Release/net8.0/linux-arm/publish/* username@IP:/home/username/publish/
   ```

2. Run the application on the Pi:
   ```bash
   dotnet ./JW.Stairs.dll --urls=http://0.0.0.0:5001
   ```

## Troubleshooting

- **SPI Data Transfer Error**:
  If you encounter the error `Error 90 performing SPI data transfer`, increase the SPI buffer size by adding `spidev.bufsiz=65536` to `/boot/cmdline.txt`.
