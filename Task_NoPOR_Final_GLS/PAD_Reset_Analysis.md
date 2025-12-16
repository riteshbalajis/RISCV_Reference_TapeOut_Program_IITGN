
# PAD Reset Analysis — SCL‑180 vs SKY130

## Overview

This document analyzes the **reset pad behavior in the SCL‑180 PDK**, with specific focus on:

* Whether the reset pad requires an **internal enable**
* Whether **POR‑driven gating** is required
* Whether the reset is **asynchronous**
* Whether the reset pin is **available immediately after VDD**
* Whether **power‑up sequencing constraints** mandate a POR

---

## 1. SCL‑180 Reset Pad Characteristics

### 1.1 Internal Enable Requirement

**No internal enable is required.**

In SCL‑180, the reset pad is treated as a direct functional input:

* It does not depend on a pad‑enable bit
* It is not gated by configuration logic or strap registers
* It is expected to be valid as soon as the pad I/O ring is powered

From RTL usage such as:

```verilog
xres_buf rstb_level (
    .A(rstb_h),
    .X(rstb_l)
);
```

The reset pad is passed directly through a **level‑shifting buffer**, not a configurable GPIO cell.


---

### 1.2 POR‑Driven Gating Requirement

**No POR‑driven gating is required.**

In SCL‑180:

* The reset pin itself is considered a **valid power‑on control signal**
* There is no mandatory requirement that reset be masked until an internal POR finishes
* POR is used only for optional internal cleanup, not for pad safety using scl-180

The reset path feeds logic such as:

```verilog
assign resetb_async = porb & resetb & (!ext_reset);
```

Here, POR is **combined logically**, not required for pad correctness.Reset does not depend on a dedicated POR macro to be safe or meaningful.

---

### 1.3 Asynchronous Nature of Reset

**The reset pin is asynchronous.**


* Reset is used in `always @(posedge clk or negedge resetb)` blocks
* Reset directly clears flops without clock dependency


```verilog
always @(posedge pll_clk or negedge resetb_async) begin
    if (!resetb_async) begin
        use_pll_first <= 1'b0;
    end
end
```

---

### 1.4 Availability After VDD

**The reset is available immediately after VDD.**

SCL‑180 reset pad properties:

* Reset pad lives in the **always‑on I/O domain**
* It does not wait for:

    - PLL lock
    - Clock enable
    - Configuration straps

As soon as VDDIO and VDD core rails turns, the reset pad can be asserted or de‑asserted safely.
 External reset sources can drive reset immediately.

---

### 1.5 Power‑Up Sequencing Constraints

No documented constraints mandate a POR.**

In SCL‑180:

* No requirement that reset must wait for internal POR completion
* No pad documentation stating reset is invalid before POR
* Reset pin is treated as the primary safe startup control

---

## 2. Why SKY130 Required POR (But SCL‑180 Does Not)

### 2.1 SKY130 Reset Pad Limitations

In SKY130:

* Reset pads are implemented using **standard GPIO cells**
* GPIO cells are:

  * Disabled at power‑up
  * Dependent on configuration registers
  * Not guaranteed to drive valid logic levels until configured

As a result:

* Reset pin could float
* Internal logic could come out of reset unpredictably

A dedicated POR macro was mandatory for SKY130 Librarry.

---

### 2.2 SKY130 POR Responsibilities

POR in SKY130 was responsible for:

* Holding all logic in reset until:

  * VDD stabilized
  * GPIO configuration logic powered
  * Reset pad became functional

Without POR:

* Flops could power‑up in random states
* Clock muxes could select unstable sources

---

### 2.3 Architectural Difference Summary

| Feature             | SKY130     | SCL‑180               |
| ------------------- | ---------- | --------------------- |
| Reset pad type      | GPIO‑based | Dedicated reset pad   |
| Requires pad enable | Yes        | No                    |
| Safe at power‑up    | No         | Yes                   |
| POR mandatory       | Yes        | No                    |
| Reset availability  | After POR  | Immediately after VDD |

---

## 3. Final Conclusions

### SCL‑180 Reset Pad

*  No internal enable required
* No POR‑driven gating required
* Asynchronous
* Available immediately after VDD
*  No mandatory POR sequencing constraints

### SKY130 Reset Pad

* Internal enable dependency
* POR mandatory
* Not safe immediately after VDD

**Summary:**

POR was a necessity in SKY130 due to GPIO‑based reset limitations. In SCL‑180, the reset pad is inherently safe, asynchronous, and immediately usable, making POR optional rather than mandatory.

---

