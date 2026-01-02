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

- .NET 10.0 (Optional for self-contained deployment)
- Home Assistant (for integration)
- GLIBC 2.31 or later (Debian 11 Bullseye, Raspberry Pi OS Bullseye, or compatible)

## Setup

### Raspberry Pi Configuration

1. Enable SPI on Raspberry Pi:
   ```bash
   sudo raspi-config
   ```
   Navigate to `Interface Options` and enable `SPI`.

2. Install .NET Runtime (Optional for self-contained deployment):
   ```bash
   curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel LTS
   echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
   echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
   source ~/.bashrc
   ```

### Download from Releases (Recommended)

The easiest way to deploy is to download the pre-built release artifacts:

1. Download the latest release for your Raspberry Pi:
   ```bash
   # For Raspberry Pi Zero 2W, Pi 3, or older 32-bit models (linux-arm)
   wget https://github.com/jwraats/jwStairs/releases/latest/download/jw-stairs-linux-arm.zip
   
   # For Raspberry Pi 4, Pi 5, or 64-bit models (linux-arm64)
   wget https://github.com/jwraats/jwStairs/releases/latest/download/jw-stairs-linux-arm64.zip
   ```

2. Extract for arm
   ```bash
   unzip jw-stairs-linux-arm.zip -d ~/jw-stairs
   ```
   for arm64
   ```bash
   unzip jw-stairs-linux-arm64.zip -d ~/jw-stairs
   ```
   
   and run 
   ```bash
   cd ~/jw-stairs
   chmod +x JW.Stairs
   ./JW.Stairs --urls=http://0.0.0.0:5001
   ```

### Build from Source (Alternative)

1. Build and publish the project for Linux ARM (example):
   ```bash
   dotnet publish --runtime linux-arm --self-contained
   scp -r ./bin/Release/net10.0/linux-arm/publish/* username@IP:/home/username/publish/
   ```

2. Run the application on the Pi:
   ```bash
   dotnet ./JW.Stairs.dll --urls=http://0.0.0.0:5001
   ```

## API Capabilities

The API provides endpoints for LED control and scene management. Access the Swagger UI documentation at `/docs` when running the application.

### Scenes Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/scenes` | GET | Get all scenes |
| `/scenes/{id}` | GET | Get a specific scene by ID |
| `/scenes` | POST | Create a new scene |
| `/scenes/{id}` | PUT | Update an existing scene |
| `/scenes/{id}` | DELETE | Delete a scene |

### Frames Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/scenes/{sceneId}/frames` | GET | Get all frames for a scene |
| `/scenes/{sceneId}/frames/{orderNr}` | GET | Get a specific frame by order number |
| `/scenes/{sceneId}/frame` | POST | Add a single frame to a scene |
| `/scenes/{sceneId}/frames` | POST | Add multiple frames to a scene |

### Shows & Animations

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/shows` | GET | Get a list of all available animations and custom scenes |
| `/animation/{show}` | GET | Play an animation or scene |

#### Built-in Animations

- `knightrider` - Knight Rider style red animation
- `knightrider_green` - Knight Rider style green animation
- `knightrider_blue` - Knight Rider style blue animation
- `theatrechase` - Theatre chase effect (requires `color` and `blankColor` parameters)
- `rainbow` - Rainbow color cycle animation
- `colorwipe` - Color wipe effect (requires `color` parameter)
- `color` - Set all LEDs to a solid color (requires `color` parameter)

#### Animation Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `color` | string | Hex color code (e.g., `FF0000` for red) |
| `blankColor` | string | Hex color code for blank spaces in theatre chase |
| `percentage` | int | Speed percentage (100 = normal, >100 = faster, <100 = slower) |
| `repeat` | bool | Whether to repeat the animation continuously |
| `colorOrder` | enum | Color order: `RGB`, `RBG`, `GRB`, `GBR`, `BRG`, `BGR` |

## Troubleshooting

- **SPI Data Transfer Error**:
  If you encounter the error `Error 90 performing SPI data transfer`, increase the SPI buffer size by adding `spidev.bufsiz=65536` to `/boot/cmdline.txt`.

- **GLIBC Version Error**:
  If you encounter an error like `GLIBC_2.XX not found`, ensure your Raspberry Pi OS is based on Debian 11 Bullseye or later. You can check your GLIBC version with:
  ```bash
  ldd --version
  ```
  The release binaries are built for GLIBC 2.31 (Debian 11 Bullseye) compatibility.
