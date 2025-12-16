# Power-On Reset (POR) Module Documentation

## Table of Contents
- [Introduction](#introduction)
- [Power-On Reset Fundamentals](#power-on-reset-fundamentals)
- [Analog POR Operation](#analog-por-operation)
- [dummy_por Module](#dummy_por-module)
- [dummy_schmittbuf Module](#dummy_schmittbuf-module)
- [Power-Good Detector Primitive](#power-good-detector-primitive)
- [Complete Signal Flow](#complete-signal-flow)
- [External Reset Signal Path](#external-reset-signal-path)

## Introduction

The Power-On Reset (POR) module is a behavioral model that simulates the operation of an analog POR circuit. Its primary function is to generate clean reset signals that hold the chip in reset state until power supplies stabilize, ensuring all digital logic initializes from a known, safe state.

## Power-On Reset Fundamentals

### Why POR is Necessary

When a chip powers on, the supply voltage (such as 3.3V or 1.8V) does not instantaneously reach its target value. Instead, it gradually ramps up from 0V, creating several challenges:

- **Voltage Instability**: During the ramp-up phase, the voltage remains insufficient for reliable digital logic operation
- **Unpredictable States**: Flip-flops and registers can initialize to random, undefined states
- **Timing Issues**: Different circuit blocks may power up at different rates, causing synchronization problems

### POR Solution

The POR circuit addresses these issues by:

1. Holding the chip in reset state during the entire power supply ramp-up period
2. Monitoring the supply voltage until it reaches a safe, stable threshold
3. Releasing reset only after confirming stable power conditions
4. Ensuring all components begin operation from a known initial state

## Analog POR Operation

### Circuit Principle

The analog POR circuit operates through the following mechanism:

**Capacitor Charging Phase**
- A controlled current source slowly charges a capacitor connected to the power supply (VDD)
- The capacitor voltage rises gradually as the power supply ramps up
- This voltage represents the monitored power supply state

**Threshold Detection**
- The capacitor voltage feeds into a Schmitt trigger comparator
- The Schmitt trigger compares the capacitor voltage against a predetermined threshold
- While below threshold: reset signal remains active (logic low)
- Above threshold: reset signal releases (logic high)

**Timing Control**
- The RC time constant determines the POR delay duration
- This ensures reset holds long enough for complete power stabilization
- Typical analog POR delay: approximately 15ms in real silicon

## dummy_por Module

### Overview

The `dummy_por` module is not a physical analog circuit but a behavioral Verilog model that replicates the timing and functional characteristics of a real POR circuit for simulation purposes.

### Module Interface

**Power Domain Signals** (when `USE_POWER_PINS` is defined):
```verilog
inout vdd3v3  // 3.3V power supply
inout vdd1v8  // 1.8V power supply
inout vss3v3  // 3.3V ground
inout vss1v8  // 1.8V ground
```

**Reset Output Signals**:
```verilog
output porb_h  // Active-low reset for 3.3V domain
output porb_l  // Active-low reset for 1.8V domain
output por_l   // Active-high reset (inverted porb_l)
```

**Internal Signals**:
```verilog
reg inode      // Internal node modeling capacitor charge state
wire mid       // Intermediate signal between Schmitt triggers
```

### Operational Behavior

**Initialization Phase**

At simulation start:
```verilog
initial begin
    inode = 0;  // Capacitor discharged state
end
```

**Timing Simulation**

The module uses a reduced delay for simulation efficiency:
- Real hardware: ~15ms POR delay
- Simulation model: 500ns delay

**Power Detection Logic**

When `USE_POWER_PINS` is defined:
```verilog
always @(posedge vdd3v3) begin
    #500 inode = 1'b1;  // Capacitor charged after delay
end
```

Without power pins:
```verilog
initial begin
    #500 inode = 1'b1;  // Timed release after 500ns
end
```

**Signal Processing Chain**

First Schmitt Trigger Buffer:
```verilog
dummy__schmittbuf_1 hystbuf1 (
    .A(inode),     // Input: capacitor voltage
    .X(mid),       // Output: intermediate signal
    .VPWR(vdd3v3), // Power connections (if defined)
    .VGND(vss3v3),
    .VPB(vdd3v3),
    .VNB(vss3v3)
);
```

Second Schmitt Trigger Buffer:
```verilog
dummy__schmittbuf_1 hystbuf2 (
    .A(mid),       // Input: cleaned intermediate signal
    .X(porb_h),    // Output: 3.3V domain reset
    .VPWR(vdd3v3),
    .VGND(vss3v3),
    .VPB(vdd3v3),
    .VNB(vss3v3)
);
```

**Output Signal Generation**:
```verilog
assign porb_l = porb_h;   // 1.8V domain reset (copy of 3.3V)
assign por_l = ~porb_l;   // Active-high reset (inverted)
```

### Design Rationale

**Dual Schmitt Trigger Architecture**

Using two Schmitt triggers in series provides:
- Enhanced noise immunity through double hysteresis
- Cleaner output edges with reduced glitches
- Better simulation of real analog POR behavior
- Improved signal integrity for downstream logic

## dummy_schmittbuf Module

### Module Structure

The `dummy_schmittbuf` module implements a behavioral Schmitt trigger buffer with power-aware functionality.

**Interface Signals**:
```verilog
input  A         // Analog-like input signal
output X         // Digital output signal
input  VPWR      // Positive power supply
input  VGND      // Ground reference
input  VPB       // P-substrate/P-well bias
input  VNB       // N-substrate/N-well bias
```

### Internal Architecture

**Signal Processing Stages**

Stage 1 - Input Buffer:
```verilog
buf buf0 (buf0_out_X, A);
```
Function: Initial buffering of input signal without hysteresis

Stage 2 - Power-Good Detection:
```verilog
dummy__udp_pwrgood_pp$PG pwrgood_pp0 (
    pwrgood_pp0_out_X,  // Output
    buf0_out_X,         // Input from buf0
    VPWR,               // Power supply monitor
    VGND                // Ground reference
);
```
Function: Validates power integrity before signal propagation

Stage 3 - Output Buffer:
```verilog
buf buf1 (X, pwrgood_pp0_out_X);
```
Function: Drives final output with sufficient strength

**Complete Signal Path**:
```
A → buf0 → pwrgood_pp0 → buf1 → X
         ↓
    (monitors VPWR/VGND)
```

## Power-Good Detector Primitive

### UDP Definition

The `dummy__udp_pwrgood_pp$PG` is a User-Defined Primitive (UDP) that implements power-good detection logic using a truth table rather than structural Verilog.

**Interface**:
```verilog
primitive dummy__udp_pwrgood_pp$PG (
    output UDP_OUT,   // Power-gated output
    input  UDP_IN,    // Input signal
    input  VPWR,      // Power supply
    input  VGND       // Ground
);
```

### Truth Table

| VPWR | VGND | UDP_IN | UDP_OUT | Condition           |
|------|------|--------|---------|---------------------|
| 1    | 0    | 0      | 0       | Power good, input 0 |
| 1    | 0    | 1      | 1       | Power good, input 1 |
| x    | x    | x      | x       | Power unstable      |
| 0    | 1    | x      | x       | Power reversed      |
| x    | x    | x      | x       | Any other condition |

### Functional Behavior

**Normal Operation** (`VPWR = 1`, `VGND = 0`):
- Output faithfully follows input
- Signal propagates cleanly through the gate

**Power Fault Conditions**:
- Power supply instability: Output becomes `x` (unknown)
- Power supply off: Output forced to `x`
- Voltage anomalies: Output indicates undefined state

This behavior prevents propagation of invalid signals during power transitions, protecting downstream logic from corruption.

## Complete Signal Flow

### Internal POR Signal Chain

```
Power Supply Ramp (vdd3v3)
    ↓
[dummy_por module]
    ↓ (internal delay)
inode (reg) ← 500ns delay from vdd3v3 rising edge
    ↓
hystbuf1 (.A(inode), .X(mid)) ← FIRST dummy__schmittbuf_1
    ↓
mid (wire) ← intermediate clean signal
    ↓
hystbuf2 (.A(mid), .X(porb_h)) ← SECOND dummy__schmittbuf_1
    ↓
porb_h (output) ← 3.3V domain reset (active-low)
    ↓
porb_l = porb_h ← 1.8V domain reset (direct copy)
    ↓
por_l = ~porb_l ← 1.8V domain reset (inverted)
    ↓
[Used by CPU, peripherals, user project]
```

### Module Hierarchy

```
┌─────────────────┐
│     vdd3v3      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   dummy_por     │
│  porb_h         │
│  porb_l         │
│  por_l          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ caravel_core.v  │
│  porb_h         │
│  porb_l         │
│  por_l          │
└────┬────────┬───┘
     │        │
     ▼        ▼
┌─────────┐ ┌──────────────┐
│caravel_ │ │ housekeeping │
│clocking │ │ (porb_l→porb)│
│(porb_l→ │ └──────┬───────┘
│  porb)  │        │
└─────────┘        ▼
            ┌──────────────┐
            │housekeeping_ │
            │    spi       │
            │ porb +       │
            │Internal Logic│
            └──────────────┘
```

## External Reset Signal Path

### Testbench-to-Core Reset Propagation

When using external reset control (with POR removed), the reset signal follows this path:

```
┌─────────────────┐
│   Testbench     │
│    resetb       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  vsdcaravel.v   │
│    resetb       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    chip_io      │
│    resetb       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   pc3de PAD     │
│    resetb       │
└────────┬────────┘
         │ (PAD delay)
         ▼
┌─────────────────┐
│    chip_io      │
│ resetb_core_h   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   caravel.v     │
│    rstb_h       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ caravel_core.v  │
│    rstb_h       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   xres_buf      │
│    rstb_l       │
└────────┬────────┘
         │
         ▼
    (continues to
    internal logic)
```

### Signal Transformations

**Voltage Domain Translation**:
- `resetb` (testbench): Digital control signal
- `resetb_core_h`: High-voltage domain (3.3V)
- `rstb_h`: Core high-voltage reset
- `rstb_l`: Low-voltage domain (1.8V)

**PAD Delay Effects**:
- Physical I/O pad introduces propagation delay
- Delay accounts for pad driver circuitry
- Essential for accurate timing simulation

## Summary

The POR module architecture provides a robust reset mechanism through:

1. **Behavioral Modeling**: Efficient simulation of analog POR timing
2. **Dual Schmitt Triggers**: Enhanced noise immunity and signal quality
3. **Power-Aware Design**: Explicit power supply monitoring and gating
4. **Multiple Reset Domains**: Support for both 3.3V and 1.8V domains
5. **Flexible Configuration**: Optional external reset control

This design ensures reliable chip initialization while maintaining simulation efficiency and flexibility for various verification scenarios.
