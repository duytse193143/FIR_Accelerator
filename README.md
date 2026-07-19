#  A Comparative Trade-off Analysis of Direct and Transposed Architectures for 16-tap FIR Filters on FPGA


A PPA (Performance – Power – Area) trade-off analysis between two micro-architectures, **Direct Form** and **Transposed Form**, for a 16-tap FIR filter, implemented at RTL level in Verilog and synthesized on an Intel Cyclone V FPGA (Intel Quartus Prime).



---

##  Introduction

The Finite Impulse Response (FIR) filter plays a fundamental role in modern digital signal processing systems. When deployed on FPGA platforms, the choice of micro-architecture directly affects the balance between **speed**, **logic area**, and **power consumption**.

This project implements and directly compares two classic architectures for a 16-tap FIR filter:

- **Direct Form** – a direct mapping of the convolution equation into hardware, using a balanced binary adder tree.
- **Transposed Form** – based on the Network Transposition theorem, broadcasting the input simultaneously to all multipliers and relocating delay registers into the middle of the adder chain to shorten the critical path.

The output equation of an FIR filter of order N−1:

```
                                                y[n] = Σ (k=0 → N-1) h[k] · x[n-k]
```

---

##  Architecture

### 1. Direct Form

The input is propagated through a tapped delay line; each delayed sample is multiplied by its corresponding coefficient and accumulated through a 4-level balanced binary adder tree (since N = 16).

```
                                       T_cp,direct = T_mult + ⌈log2 N⌉ · T_add   (= T_mult + 4·T_add)
```

The critical path grows logarithmically with the number of taps, creating a **speed bottleneck** as the filter order increases.

<img width="1273" height="772" alt="fig1_direct_form" src="https://github.com/user-attachments/assets/1be6b6f3-19d6-4a5c-bc59-57c79624eb8d" />

                                *Fig. 1. Block diagram of the Direct Form FIR filter architecture.*

### 2. Transposed Form

The input `x[n]` is broadcast simultaneously to all multipliers, and delay registers are relocated into the middle of the adder chain. As a result, the critical path is reduced to just **one multiplier + one adder**, independent of N:

```
                                               T_cp,trans = T_mult + T_add
```

<img width="1396" height="435" alt="fig2_transposed_form" src="https://github.com/user-attachments/assets/b9bfd6a0-a180-43f8-86ac-3e70038c6ee6" />

                             *Fig. 2. Block diagram of the Transposed Form FIR filter architecture.*

---

##  RTL Implementation & Functional Verification

- Verilog HDL, using the same set of signed filter coefficients for both architectures.
- Input/coefficients: 16-bit signed fixed-point → 32-bit multiplication result.
- Output: 36-bit signed to accommodate bit-width growth from accumulating multiple operands.
- Active-high asynchronous reset.
- **Latency:** the Direct Form has one extra clock cycle of latency compared to the Transposed Form:

```
                                                     y_D[n+1] = y_T[n]
```

Both architectures maintain a stable throughput of one output sample per clock cycle.

Functional verification was performed in **ModelSim** using a common testbench with identical clock, reset, and input sequence:

<img width="447" height="155" alt="fig3_modelsim_waveform" src="https://github.com/user-attachments/assets/38afde3b-2c56-48d1-b0e7-c443eb5cb0f1" />

    *Fig. 3. ModelSim waveforms illustrating the one-clock-cycle latency difference between the Direct-Form and Transposed-Form outputs.*

---

##  Synthesis & Measurement Methodology

- Platform: **Intel Cyclone V FPGA** (28nm, Adaptive Logic Module architecture), using **Intel Quartus Prime**.
- Synthesis mode: **Balanced optimization**, to preserve the natural speed/area trade-off and avoid interference from automatic optimizers.
- Quartus's automatic **register retiming** feature was strictly controlled to preserve each architecture's intended register placement.
- Fmax was extracted via **Static Timing Analysis** (Quartus Timing Analyzer) using the actual routing delay model.
- Power was measured using **Power Analyzer** with a uniform switching probability to ensure a fair comparison.

---

##  PPA Results

                               | Design Metrics | Direct Form | Transposed Form |
                               |---|---|---|
                               | **Performance (Fmax) [MHz]** | 17.44 | **282.65** |
                               | **Logic Area [ALMs]** | **61** | 261 |
                               | **Total Registers** | **286** | 554 |
                               | **DSP Blocks** | 15 | **8** |
                               | **Static Power [mW]** | 194.42 | 194.28 |
                               | **Dynamic Power [mW]** | 58.70 | **23.34** |
<img width="1600" height="802" alt="fig4_ppa_comparison" src="https://github.com/user-attachments/assets/f533d54f-7feb-40bf-8bdc-6314dc7e3bb3" />

          *Fig. 4. Visual comparison of PPA metrics between Direct Form and Transposed Form (Quartus compilation & Power Analyzer).*

### Key Observations

- **Speed:** The Transposed Form reaches an Fmax of **282.65 MHz**, an improvement of **~16.2×** over the Direct Form's 17.44 MHz, by cutting the critical path down to a single multiplier + adder, independent of the number of taps N.
- **Area:** The Transposed Form consumes more ALMs (261 vs. 61, a 327.9% increase) and more registers (554 vs. 286, a 93.7% increase), due to replicating the input across all logic nodes and using extra D-flip-flops to maintain the pipeline.
- **DSP Blocks:** Conversely, the Transposed Form uses only **8 DSP blocks** vs. 15 for the Direct Form (a 46.7% decrease), since its distributed-input structure lets Quartus more effectively exploit DSP packing.
- **Static power:** Nearly identical between the two architectures (194.42 mW vs. 194.28 mW), since it is primarily driven by leakage current of the 28nm process rather than architecture.
- **Dynamic power:** This is the decisive factor — the Transposed Form consumes only **23.34 mW** vs. 58.70 mW for the Direct Form (a **~60.2%** reduction), thanks to glitch suppression: registers placed right after each adder act as barriers that block glitch propagation and amplification.

> Note: To fairly compare switching activity, dynamic power was estimated at a uniform 100 MHz clock condition. The 58.70 mW value for the Direct Form is therefore a theoretical estimate (since 100 MHz already exceeds its actual Fmax), used purely to demonstrate the Transposed Form's glitch-suppression capability.

---

##  Conclusion

Based on the experimental data, the **Transposed Form** is the optimal choice for DSP systems requiring **high speed and power savings**, provided hardware area constraints are not too strict. In exchange for its superior speed and power performance, this architecture requires a significantly larger logic resource cost (ALMs, registers).

---

##  Limitations & Future Work

- The current experimental model has only been evaluated on a 16-tap FIR filter with fixed coefficients. For higher-order filters, the Transposed Form's input-distribution routing network may cause **routing congestion**, negatively impacting area and speed.
- The implementation has only been tested on the Cyclone V FPGA platform, which does not fully reflect physical characteristics on more advanced semiconductor technologies.
- Future directions:
  - Integrate area-optimized multiplier algorithms such as **Booth Multiplier** or **Wallace Tree**.
  - Extend the synthesis flow from FPGA to **ASIC** design to cross-check and reinforce the PPA trade-off results.

---

##  References

1. A. V. Oppenheim, R. W. Schafer, *Discrete-Time Signal Processing*, 3rd ed., Pearson, 2010.
2. U. Meyer-Baese, *Digital Signal Processing with Field Programmable Gate Arrays*, 4th ed., Springer, 2014.
3. K. K. Parhi, *VLSI Digital Signal Processing Systems: Design and Implementation*, Wiley, 1999.
4. Intel Corporation, *Cyclone V Device Handbook*, Doc. 683375, 2023.
5. Intel Corporation, *Intel Quartus Prime Standard Edition User Guide: Timing Analyzer*, Doc. 683068, 2018.
6. Intel Corporation, *Intel Quartus Prime Standard Edition User Guide: Power Analysis and Optimization*, Doc. 683506, 2018.

*(See the full list of 11 references in the original paper.)*

---

##  Team

**Group 7 — Integrated Circuit Design, FPT University**
Tran Duy · Ngo Van Thang · Tran Quan Bao · Bui Huu Loi


---

##  Suggested Repository Structure

```
.
├── README.md
├── images/
│   ├── fig1_direct_form.jpeg
│   ├── fig2_transposed_form.jpeg
│   ├── fig3_modelsim_waveform.jpeg
│   └── fig4_ppa_comparison.jpeg
├── rtl/              # Verilog source (Direct Form & Transposed Form)
├── tb/                # ModelSim testbench
└── quartus/           # Quartus project files, synthesis reports
```
