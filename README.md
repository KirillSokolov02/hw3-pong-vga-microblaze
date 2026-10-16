# Pong Game on VGA — MicroBlaze Soft Processor SoC on Artix-7

Classic Pong game rendered on a 640x480 VGA display using a MicroBlaze soft processor with custom IP cores. Built for the Digilent Arty A35.

## Overview

A complete embedded system-on-FPGA implementing the Pong game. A MicroBlaze 32-bit soft processor manages game state, reads paddle inputs from switches, and communicates with custom hardware IP cores over AXI buses to drive VGA output at 60Hz.

## Project Structure

| File | Description |
|------|-------------|
| `VGAController.vhd` | VGA timing and pixel streaming controller |
| `ImageGen.vhd` | Custom image generation IP core |
| `ImageGen_S00_AXI.vhd` | AXI Lite slave interface for ImageGen |
| `GPIO.vhd` | Custom GPIO IP core |
| `GPIO_S00_AXI.vhd` | AXI Lite slave interface for GPIO |
| `Constants.vhd` | Shared type definitions and constants |

## Hardware

- **Device:** Xilinx Artix-7 XC7A35T (xc7a35tcpg236-1)
- **Board:** Digilent Arty A35
- **Tool:** Vivado 2021.1
- **Language:** VHDL-2008

## Architecture

The system is built around a **MicroBlaze soft processor** with the following components:

- **AXI Interconnect** routes data between MicroBlaze, BRAM, and custom IP cores
- **Custom ImageGen IP** handles ball and paddle rendering
- **Custom GPIO IP** provides switch input interface
- **VGA Controller** generates 640x480 @ 60Hz timing from pixel data

## Building

1. Open the project in Vivado
2. Generate the bitstream
3. Export hardware with bitstream and SDK configuration
4. Build and run the MicroBlaze firmware in SDK
