# HW3 — VGA Pong Game on MicroBlaze Embedded System

A **VGA Pong game** implemented on a **Xilinx Artix-7 FPGA** (Digilent Arty A35) using a **MicroBlaze soft processor** with custom IP cores for VGA control, image generation, and GPIO. Designed for **Vivado 2021.1**.

## Overview

This project implements the classic Pong game entirely in hardware, displaying the game on a standard VGA monitor at **640×480 resolution @ 60Hz**. The system is built around a **MicroBlaze soft processor** connected to custom hardware accelerators via an **AXI bus**, demonstrating a complete embedded system-on-FPGA (SoC) architecture.

The game features two paddles controlled via DIP switches on the Arty A35 board, a moving ball with physics simulation, and score tracking. The MicroBlaze processor runs firmware that configures the custom IP cores, reads switch inputs, and manages game state through the AXI interconnect.

## Architecture

### System Block Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    MicroBlaze SoC System                        │
│                                                                 │
│  ┌──────────┐   LMB    ┌──────────────┐   LMB    ┌──────────┐  │
│  │          │──────────▶│   LMB BRAM   │──────────│          │  │
│  │          │            │ (Dual Port)  │          │          │  │
│  │          │◀───────────└──────────────┘◀─────────│          │  │
│  │          │                                            │  │
│  │          │   LMB    ┌──────────────┐   LMB    │          │  │
│  │          │──────────▶│   LMB BRAM   │──────────│          │  │
│  │          │            │ (BRAM Ctrl)  │          │          │  │
│  │          │◀───────────└──────────────┘◀─────────│          │  │
│  │          │                                            │  │
│  │ Micro   │   AXI    ┌──────────────┐   AXI    │          │  │
│  │  Blaze  │─────────▶│  AXI Inter-  │──────────│          │  │
│  │ CPU     │◀─────────│   Connect    │◀─────────│          │  │
│  │          │   AXI    │  (xbar)      │   AXI    │          │  │
│  │          │          └──────────────┘          │          │  │
│  └──────────┘           │ │ │ │                  └──────────┘  │
│                         │ │ │ │                                 │
│              ┌──────────┘ │ │ └──────────┐                      │
│              │            │ │            │                      │
│     ┌────────▼──┐  ┌──────▼────┐ ┌──────▼──────┐       ┌───────▼──────┐
│     │  MDM 1    │  │AXI UART   │ │hw3_gpio_0   │ │ImageGen_1  │VGAController_0│
│     │(Debug)    │  │lite_0     │ │(GPIO)       │ │(Image Gen)│(VGA Timing)  │
│     └───────────┘  └───────────┘ └─────────────┘ └───────────┘ └──────────────┘
│                                                                 │
│  ┌────────────────────────────────────────────────────────────────┐
│  │  CLK Wizard (100 MHz input) → Reset Controller                │
│  └────────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. MicroBlaze Processor

The **MicroBlaze 32-bit soft processor** serves as the central control unit. It:

- Runs custom firmware that configures and communicates with all peripheral IP cores
- Manages game state, input polling, and output rendering through memory-mapped AXI registers
- Uses local memory bus (LMB) with dual-port BRAM for fast instruction and data access
- Includes the MDM (Microcontroller Debug Module) for in-system debugging

#### 2. AXI Interconnect (xbar)

A **4-port AXI Interconnect** routes communication between the MicroBlaze and peripherals:

| Port | Peripheral | Function |
|------|-----------|----------|
| S00 | MicroBlaze Local Memory | Instruction + Data BRAM |
| M00 | AXI UARTlite | Serial console/debug |
| M01 | hw3_gpio_0 | GPIO for switch inputs |
| M02 | ImageGen_1 | Image generation control |
| M03 | VGAController_0 | VGA timing control |

#### 3. Custom IP Cores

**ImageGen_1** — Pong game image generator:
- Reads paddle positions from switches and ball cursor positions
- Computes RGB pixel output for each scanline position
- Outputs ball and paddle positions as integer cursors
- Supports scores for both players (up to 10)
- Uses prescaler counters for paddle movement debouncing (40000-cycle) and ball movement (35000-cycle)

**VGAController_0** — VGA timing controller:
- Generates horizontal and vertical sync signals
- Uses a pixel clock prescaler for 25MHz VGA timing
- Implements standard VGA 640×480 @ 60Hz timing

**hw3_gpio_0** — GPIO interface:
- 5-bit input: `up1_in`, `down1_in`, `up2_in`, `down2_in`, `start_in`
- Maps directly to DIP switches on the Arty A35 board
- Provides player paddle controls to the image generator

#### 4. Clock Management

- **Input**: 100 MHz clock from Arty A35 board oscillator
- **CLK Wizard**: Generates required clock domains
- **Reset Controller**: Stable reset for all system components

## VGA Timing Specifications

The project uses standard **640×480 @ 60Hz** (VGA mode) timing:

| Parameter | Horizontal | Vertical | Description |
|-----------|-----------|----------|-------------|
| **Visible Area** | 640 | 480 | Active display pixels |
| **Front Porch** | 16 | 10 | Border before sync |
| **Sync Pulse** | 96 | 2 | Sync signal duration |
| **Back Porch** | 48 | 33 | Border after sync |
| **Total** | **800** | **525** | Total lines/row |
| **Frequency** | ~31.5 kHz | ~60 Hz | Refresh rates |

### Game Elements

| Element | Size/Value | Description |
|---------|-----------|-------------|
| Paddle Width | 8 pixels | Vertical paddle dimension |
| Paddle Height | 150 pixels | Paddle vertical span |
| Ball Size | 11 pixels | Square ball dimension |
| Prescaler (Paddle) | 40000 | Debounce/decimate paddle movement |
| Prescaler (Ball) | 35000 | Ball speed control |

## Input/Output Interface

### Inputs (Arty A35 DIP Switches)

| Signal | Direction | Purpose |
|--------|----------|---------|
| `up1_in` | Input | Player 1 paddle up |
| `down1_in` | Input | Player 1 paddle down |
| `up2_in` | Input | Player 2 paddle up |
| `down2_in` | Input | Player 2 paddle down |
| `start_in` | Input | Game start/reset trigger |

### Outputs (VGA Connector)

| Signal | Direction | Purpose |
|--------|----------|---------|
| `hSync` | Output | Horizontal sync (active low) |
| `vSync` | Output | Vertical sync (active low) |
| `r[3:0]` | Output | Red (4-bit) |
| `g[3:0]` | Output | Green (4-bit) |
| `b[3:0]` | Output | Blue (4-bit) |

The 4-bit RGB output provides **16 colors per channel** (4096 total), though the game typically uses a limited palette for clear visibility.

## Project Structure

```
hw3/
├── project_1.xpr              # Vivado 2021.1 main project
├── hw3/
│   ├── VGA_controller/        # VGA timing controller IP
│   │   └── VGA_controller.srcs/
│   │       └── sources_1/imports/
│   │           ├── VGAController.vhd   # VGA sync generator
│   │           └── Group1_HW1/Constants.vhd
│   ├── image_gen/             # Pong image generator IP
│   │   ├── image_gen.xpr
│   │   └── image_gen.srcs/
│   │       └── sources_1/imports/
│   │           ├── image_gen.vhd       # Main Pong game logic
│   │           └── Group1_HW1/
│   │               ├── ClockDivider.vhd
│   │               └── Constants.vhd
│   ├── ip_repo/               # Custom IP repository
│   │   ├── src/
│   │   │   ├── Constants.vhd
│   │   │   └── VGAController.vhd
│   │   ├── ImageGen_1.0/      # ImageGen AXI IP package
│   │   │   ├── hdl/
│   │   │   │   ├── ImageGen_v1_0.vhd
│   │   │   │   └── ImageGen_v1_0_S00_AXI.vhd
│   │   │   ├── src/
│   │   │   │   └── Constants.vhd
│   │   │   └── drivers/       # C driver for MicroBlaze
│   │   │       └── ImageGen_v1_0/
│   │   │           ├── src/
│   │   │           │   ├── ImageGen.c
│   │   │           │   ├── ImageGen.h
│   │   │           │   └── ImageGen_selftest.c
│   │   └── gpio/
│   │       └── hw3_gpio_1.0/  # GPIO AXI IP package
│   │           ├── hdl/
│   │           │   ├── hw3_gpio_v1_0.vhd
│   │           │   └── hw3_gpio_v1_0_S00_AXI.vhd
│   │           └── drivers/   # C driver for MicroBlaze
│   │               └── hw3_gpio_v1_0/
│   │                   └── src/
│   │                       ├── hw3_gpio.c
│   │                       ├── hw3_gpio.h
│   │                       └── hw3_gpio_selftest.c
│   └── gpio/                  # Simple GPIO wrapper
│       └── gpio.srcs/
│           └── sources_1/imports/
│               └── Downloads/
│                   └── GPIO.vhd
├── .gitignore                 # Excludes Vivado build artifacts
└── README.md                  # This file
```

## Building

### Prerequisites

- **Xilinx Vivado 2021.1** (or later, 64-bit)
- **Digilent Arty A35 board** with Artix-7 FPGA (XC7A35TCPG236-1)
- VGA monitor with standard analog RGB inputs
- USB cable for programming via Arty A35's USB port

### Compilation Steps

1. Open **Vivado 2021.1**
2. Select **File → Open Project**
3. Open `project_1.xpr`
4. Select **Flow → Run Synthesis**
5. After synthesis completes, select **Flow → Run Implementation**
6. Generate bitstream with **Flow → Generate Bitstream**
7. Open **Hardware Manager** and connect to the Arty A35 board
8. Program the FPGA with the generated `.bit` file

### Device Configuration

| Parameter | Value |
|-----------|-------|
| **Family** | Artix-7 |
| **Device** | XC7A35TCPG236-1 |
| **Package** | CPG236 |
| **Speed Grade** | -1 |
| **I/O Voltage** | 3.3V |
| **Board** | Digilent Arty A35 |
| **Board Clock** | 100 MHz |
| **Top-Level Entity** | design_1 (Block Design) |
| **Vivado Version** | 2021.1 |

### Resource Usage (Estimated)

| Resource | Estimated Usage |
|----------|----------------|
| **LUTs** | ~15-20% of available |
| **FFs** | ~10-15% of available |
| **BRAM** | ~5% (LMB + AXI BRAM controllers) |
| **DSPs** | Minimal (integer-only arithmetic) |
| **IOs** | ~10-15 pins used |
| **BUFGs** | 1-2 (VGA pixel clock) |

## Game Mechanics

### Paddle Control

Each player has two switches: one for moving up and one for moving down. The paddle position is read directly from the DIP switches and passed to the image generator. Prescaler counters (40000-cycle) debounce and decimate the paddle input to prevent overly rapid movement.

### Ball Physics

The ball moves diagonally across the screen with horizontal and vertical velocity. It bounces off the top and bottom walls and off the paddles. The ball cursor positions (in scanline coordinates) are passed to the image generator for rendering.

### Scoring

- Two separate score registers (`score_1`, `score_2`) track each player's points
- Scores range from **0 to 10**
- Each player's score is rendered as a bitmap on the VGA display
- The `start_in` signal resets the game and both scores

### Image Generation Pipeline

```
Pixel clock (25 MHz)
    ↓
┌──────────────┐     hPosCurrent   ┌──────────────────┐
│  VGA         │◀─────────────────│   ImageGen       │
│  Controller  │     vPosCurrent  │   (Pong Game)    │
│              │                   │                  │
│ Generates    │◀───── paddle1    │ Reads switches   │
│ hSync/vSync  │       cursor     │ paddle2 cursor   │
│              │◀───── score_1    │ score_1, score_2 │
│              │◀───── score_2    │ ballCursorX,     │
│              │◀───── ball       │   ballCursorY    │
│              │─────────────────▶│──────────────────│
│              │    r[3:0],       │ Outputs RGB      │
│              │    g[3:0],       │ pixel data       │
│              │    b[3:0]        │ for current pixel│
└──────────────┘                  └──────────────────┘
```

## VHDL Conventions

- **IEEE 1164** — Standard logic types (`std_logic`, `std_logic_vector`)
- **IEEE numeric_std** — Unsigned arithmetic and type conversions
- **Package constants** — All timing and game constants in `Constants.vhd`
- **Component-based architecture** — Clean interface separation between modules
- **Synchronous design** — All registers clocked on rising edge
- **Active-low sync** — VGA sync signals are active-low (standard TTL level)

## Memory Map (AXI)

| Address | Peripheral | Width | Purpose |
|---------|-----------|-------|---------|
| 0x4120_0000 | ImageGen_1 | 32-bit | Image gen control/status |
| 0x4121_0000 | hw3_gpio | 32-bit | GPIO switch inputs |
| 0x4060_0000 | AXI UARTlite | 32-bit | Serial console |
| 0x40A0_0000 | VGAController | 32-bit | VGA timing control |
| 0x0000_0000 | LMB BRAM | 32-bit | MicroBlaze local memory |

## Debug Interface

- **MDM (Microcontroller Debug Module)** — Enables hardware debugging via XMD (Xilinx Microprocessor Debugger) or VIVADO SDK
- **AXI UARTlite** — Serial console output (115200 baud, 8N1 typical)
- **SignalTap equivalent** — Can use Vivado Integrated Logic Analyzer (ILA) for on-fabric signal tracing

## Design Methodology

### Hardware-Software Co-Design

This project demonstrates a **hybrid approach** where:
- The **MicroBlaze processor** handles high-level game logic and user input
- **Custom hardware IP** (ImageGen, VGAController) handles real-time pixel generation
- **AXI bus** provides standardized communication between all components
- **Memory-mapped registers** enable software-to-hardware control

### Real-Time Image Generation

The image generator operates entirely in hardware at the VGA pixel clock rate (25 MHz), independent of the MicroBlaze processor. This ensures:

- **No tearing or flickering** — pixel generation is deterministic
- **Smooth gameplay** — ball and paddle updates are prescaler-synchronized
- **Precise timing** — all pixel-level operations are clock-accurate

### Modularity

Each IP core is self-contained with:
- VHDL implementation (`*.vhd`)
- AXI interface wrapper (`*_S00_AXI.vhd`)
- C driver library (`*.c`, `*.h`)
- TCL build scripts for IP packaging

## Troubleshooting

### No Display
- Verify VGA cable is properly connected
- Check that the Arty A35 board is powered
- Ensure the bitstream has been successfully programmed
- Verify the VGA monitor is set to the correct input source

### Image Not Centered
- Check the VGA timing constants in `Constants.vhd`
- Verify the pixel clock configuration in the CLK Wizard IP

### Paddles Not Responding
- Verify DIP switch connections on the Arty A35
- Check the GPIO IP configuration
- Ensure the `start_in` signal is asserted to begin the game

### Ball Not Moving
- Verify the prescaler value in `Constants.vhd` (35000 for ball)
- Check the ball physics logic in `image_gen.vhd`

## References

- [Xilinx PG085: AXI Peripheral Design Guide](https://docs.xilinx.com/r/en-US/pg085-axi-peripheral-design-guide/Overview)
- [Xilinx PG058: MicroBlaze Reference Guide](https://docs.xilinx.com/r/en-US/pg152-microblaze-reference-guide/Introduction)
- [Digilent Arty A35 Reference Manual](https://digilent.com/reference/arty/start)
- [VESA Timing Standards for VGA](https://www.vesa.org/)
- [IEEE 1076 VHDL Standard](https://standards.ieee.org/standard/1076-2008.html)

> *Note: This README was generated by AI to describe the project. The source code itself was written by the user.*
