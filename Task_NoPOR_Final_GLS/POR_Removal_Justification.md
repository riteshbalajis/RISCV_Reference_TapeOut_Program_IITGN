# POR Removal Justification

# Why External Reset Is Sufficient in SCL-180 (No POR)

## 1. Why POR Is Fundamentally an Analog Problem

### 1.1 Nature of Power-On Behavior

Power-on behavior is inherently analog:

* Supply rails ramp continuously, not instantaneously
* Threshold voltages are crossed gradually
* Different domains reach valid operating regions at different times

Digital logic cannot reliably reason about these conditions.

---

### 1.2  POR Functionlaity

A real POR circuit:

* Uses analog components (bandgap, RC, comparators)
* Detects when VDD crosses a safe threshold
* Holds reset asserted until voltage and bias are valid

This functionality cannot be faithfully replicated in RT*.

---

## 2. Why RTL-Based POR Is Unsafe

### 2.1 RTL POR Assumptions

An RTL-based POR assumes:

* Clock is running
* Flops power up in a known state evertime it will be in stable state
* Reset signal is already valid

All three assumptions are invalid during power-up.

---

### 2.2 Failure Modes of RTL POR

RTL POR logic may:

* Release reset early due to meta stability
* Miss reset assertion if clocks are unstable
* Power up flops in random states

As a result:

> RTL POR can create a false sense of safety while introducing silent failure modes.

* POR is either analog
* Or provided externally


---

## 3. Why SCL-180 Pads Allow Safe External Reset

### 3.1 Dedicated Reset Pad Architecture

In SCL-180:

* Reset pin is a dedicated pad, not a GPIO as sky-130
* It does not depend on configuration registers
* It is not gated by pad-enable logic

The reset signal is available as soon as VDD is present.

---

### 3.2 Asynchronous Reset Path

Reset is used asynchronously throughout the design:

```verilog
always @(posedge clk or negedge resetb) begin
    if (!resetb) state <= RESET;
end
```

This ensures:

* Reset assertion is independent of clock stability
* Logic can be safely held in reset during clock ramp-up

---

### 3.3 Level Shifting and Domain Safety

The reset pad feeds a level-shifting buffer (`xres_buf`), ensuring:

* Safe crossing from I/O domain to core domain
* No dependence on internal digital state

This provides a clean, deterministic reset path.

---

## 4. Risks Considerations:

### 4.1 Risk: External Reset Not Asserted

**Risk:** Board or testbench forgets to assert reset.

* Reset is a required system-level signal
* External reset generators are standard (PMIC, supervisor, tester)

---

### 4.2 Risk: Reset Deasserted Too Early

**Risk:** Reset released before clocks or PLL are stable.

* Reset deassertion controlled externally
* Clock/reset synchronization stages exist in RTL
* Reset remains asynchronous

---

### 4.3 Risk: No Internal POR Backup

**Risk:** No fallback if external reset fails.


* External reset is more reliable than RTL POR
* Eliminates false confidence from unsafe digital POR

---

## 5. Comparison with SKY130 (Why POR Was Mandatory There)

### 5.1 SKY130 Reset Architecture

In SKY130:

* Reset pin implemented using GPIO cells
* GPIO cells require configuration after power-up
* Reset pin not guaranteed valid at VDD ramp

---

### 5.2 Consequence in SKY130

Without POR:

* Reset pin could float
* Core logic could start unpredictably

Therefore:

> **A mandatory analog POR was required in SKY130 designs.**

---

### 5.3 Architectural Contrast

| Aspect             | SKY130     | SCL-180               |
| ------------------ | ---------- | --------------------- |
| Reset pad type     | GPIO-based | Dedicated reset pad   |
| Safe at power-up   | No         | Yes                   |
| Requires POR       | Yes        | No                    |
| Reset availability | After POR  | Immediately after VDD |

---

## Summary




* POR is an analog problem
* RTL-based POR is unsafe
* SCL-180 reset pads are valid immediately after VDD
* External reset is deterministic and industry-standard
* SKY130 constraints do not apply to SCL-180



In SCL-180, enforcing a digital POR is neither necessary nor safer. The architecture provides a dedicated, asynchronous, power-valid reset pad that enables deterministic startup behavior using an external reset source. Removing POR reduces risk rather than increasing it.

---



