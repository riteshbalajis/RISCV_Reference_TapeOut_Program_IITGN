## POR (Power‑On Reset):

The POR module is a simple behavioral model of a Power‑On Reset (POR) circuit which generates clean reset signals that hold the chip in reset until the power supplies are stable, so that all digital logic starts from a known, safe state.


- When we turn on a chip, the power supply voltage (like 3.3 V or 1.8 V) doesn’t jump instantly to its final value, it slowly ramps up from 0 V to the target voltage.

- During this ramp‑up, the voltage is too low for digital logic to work reliably, so flip‑flops and registers can end up in random, unpredictable states.

- POR holds the chip in reset  until the power supply reaches a safe, stable level, only then does it release the reset and let the chip start normal operation for proper operation of all the components.

### Working of Analog POR:

- A small current source slowly charges a capacitor connected to the power supply (VDD).The voltage on this capacitor rises slowly as power comes up.

- This capacitor voltage is fed into a Schmitt trigger that compares it to a threshold.As long as the capacitor voltage is below the threshold, the Schmitt trigger keeps the reset signal active .

- Once the capacitor voltage crosses the threshold, the Schmitt trigger flips reset Signal. The time it takes to charge the capacitor sets the **POR delay** ensuring that reset is held long enough for power to stabilize.

---

### dummy_por:

dummy_por is not the real analog POR circuit, it’s a behavioral Verilog model that has the behavior of the real POR used for simulation.

---> dummy_por.v <---


**Working of dummy_por :**

**Signals:**

    InOut Signals : Power pins (vdd3v3, vdd1v8, vss3v3, vss1v8) used if USE_POWER_PINS is defined.(Gets input from *** and gives to schmit_buffer module)

    Output Signals : 
      porb_h : active‑low reset for the 3.3 V domain 
      porb_l : active‑low reset for the 1.8 V domain
      por_l  : invert of portb_l
    
    wire: it is used during simulation

At the start of simulation, inode is set to 0, representing that the capacitor is initially discharged (no power).​

POR takes about 15 ms to charge the capacitor in practical , but in simulation we use a much shorter delay (500 ns) so that simulations run faster.

If USE_POWER_PINS is defined:

    Whenever vdd3v3 rises (power comes on), after 500 ns, inode is set to 1 (capacitor charged).

Otherwise (no power pins):

    After 500 ns from the start of simulation, inode is set to 1.

Then Instantiates the first Schmitt trigger buffer:

    Input A is inode (the “capacitor voltage”).

    Output X is mid (intermediate signal).

    Power pins are connected if USE_POWER_PINS is defined.

This models the first Schmitt trigger in the real POR, which provides hysteresis and a clean output edge.



Instantiates the second Schmitt trigger buffer:

    Input A is mid (output of the first Schmitt).

    Output X is porb_h (the main POR reset signal for the 3.3 V domain).

Using two Schmitt triggers in series makes the output even cleaner and more glitch‑resistant, just like in the real analog POR

    porb_l is simply copied from porb_h (same signal, for the 1.8 V domain).

    por_l is the inverted version of porb_l .

### dummy_schmittbuf:

--->dummy_schmittbuf.v<---


### primitive dummy__udp_pwrgood_pp$PG:**

This is a User‑Defined Primitive (UDP) that models a simple power‑good detector.A UDP is a small, custom Verilog primitive (like and, or, buf) that you define with a truth table instead of instantiating other modules.It has only one output and multiple inputs, and is used to model simple combinational logic.



**Signals :**

    Inputs:

        UDP_IN: the input signal (from the previous stage)

        VPWR: power supply (VDD)

        VGND: ground (VSS)

    Output: UDP_OUT

**truth table explanation:**

    When VPWR = 1 and VGND = 0 (power is good), the output follows the input:

        UDP_IN = 0 → UDP_OUT = 0

        UDP_IN = 1 → UDP_OUT = 1

    In all other cases (power off, power glitch, or unknown), the output is x (unknown)

**Working of dummy_schmittbuf :**

    A - input signal (the slow, analog‑like voltage from the POR capacitor).

    X - output (a clean, digital signal).

    VPWR, VGND, VPB, VNB are power/ground pins

1.First buffer (buf0):

    buf buf0 (buf0_out_X, A);
This is just a normal buffer that copies A to buf0_out_X (no hysteresis yet).

    
2.Power‑good detector (pwrgood_pp0):

    dummy__udp_pwrgood_pp$PG pwrgood_pp0 (pwrgood_pp0_out_X, buf0_out_X, VPWR, VGND);

This takes the buffered input and only passes (high) it through when VPWR is high and VGND is low.If power is bad, pwrgood_pp0_out_X becomes x, which will propagate to the output.

  ​
3.Second buffer (buf1):

    buf buf1 (X, pwrgood_pp0_out_X);

This final buffer drives the output X

**signal path :**

    A -> buf0 -> pwrgood_pp0 -> buf1 -> X -> dummy_por(mid/porb_h)

**Complete Flow**

    Power Supply Ramp (vdd3v3)
            ↓
        [dummy_por module]
            ↓ (internal)
        inode (reg)  ← 500ns delay from vdd3v3 rising edge
            ↓
        hystbuf1 (.A(inode), .X(mid))  ← FIRST dummy__schmittbuf_1
            ↓
        mid (wire)  ← intermediate clean signal
            ↓  
        hystbuf2 (.A(mid), .X(porb_h))  ← SECOND dummy__schmittbuf_1  
            ↓
        porb_h (output)  ← 3.3V domain reset (active-low)
            ↓
        porb_l = porb_h  ← 1.8V domain reset (direct copy)
            ↓  
        por_l  = ~porb_l ← 1.8V domain reset (inverted)
            ↓
    [Used by CPU, peripherals, user project]


### Signal Flow of dummy_por:

    +-----------------+
    |    vdd3v3      |
    +-----------------+
            |
            v
    +-----------------+
    |   dummy_por    |
    | porb_h,porb_l, |
    |     por_l      |
    +-----------------+
            |
            v
    +-----------------+
    | caravel_core.v |
    | porb_h,porb_l, |
    |     por_l      |
    +-----------------+
        |          |
        v          v
    +-----------+ +-----------------+
    |caravel_   | |  housekeeping   |
    |clocking   | |   (porb_l→porb) |
    |porb_l→porb| +-----------------+
    +-----------+         |
                        v
                +-----------------+
                |housekeeping_spit|
                | porb + Internal |
                |   Logic         | 
                +-----------------+

### Signal flow of resetb from TestBench:

    +-----------------+
    |      tb        |
    |    resetb      |
    +-----------------+
            |
            v
    +-----------------+
    |  vsdcaravel    |
    |    resetb      |
    +-----------------+
            |
            v
    +-----------------+
    |   chip_io      |
    |    resetb      |
    +-----------------+
            |
            v
    +-----------------+
    |   pc3de PAD    |
    |    resetb      |
    +-----------------+
            |
            v (PAD delay)
    +-----------------+
    |   chip_io      |
    | resetb_core_h  |
    +-----------------+
            |
            v
    +-----------------+
    |  caravel.v     |
    |    rstb_h      |
    +-----------------+
            |
            v
    +-----------------+
    |caravel_core.v  |
    |    rstb_h      |
    +-----------------+
            |
            v
    +-----------------+
    |  xres_bef      |
    |    rstb_l      |
    +-----------------+
            |
            v
        (continues...)


