# conv-engine

**A parameterized hardware convolution engine — the multiply-accumulate core of a CNN layer, written in Verilog and verified in SystemVerilog.**

---

## Overview

`conv-engine` implements *valid* (no-padding) 2D convolution / cross-correlation as a
streaming hardware datapath. Pixels arrive one per clock and flow through a small
window of registers and line buffers while a stationary array of multiply-accumulate
(MAC) taps computes one output per valid window position. Image and kernel dimensions
are elaboration-time parameters, so the same RTL retargets to different sizes without
edits.

This is a learning-focused project built to develop a well-rounded hardware skill set:
RTL datapath design, control FSM, on-chip memory, and modern SystemVerilog verification.

## Motivation

Convolution is the workhorse operation of image-recognition neural networks, and its
MAC datapath is exactly the kind of structure that AI accelerator hardware
(GPUs, TPUs, and dedicated NPUs) is built around. Implementing it from scratch — RTL,
control, memory, and verification — is a compact way to exercise the full stack of
skills relevant to hardware/accelerator roles.

## Architecture

```
            pixel stream (1/clk)
                  │
                  ▼
        ┌───────────────────┐
        │   3×3 window       │◄── shift register
        │   (shift regs)     │
        └─────────┬──────────┘
                  │            ┌───────────┐
          two line buffers ───►│  buf_newer│
          (conveyor chain)     │  buf_older│
                  │            └───────────┘
                  ▼
        ┌───────────────────┐
        │      MAC unit      │ ── 9 multiplies + adder tree
        └─────────┬──────────┘
                  │
                  ▼
            valid output pixel
```

> Block diagram is a placeholder ASCII sketch — a proper port-boundary I/O map lives in
> [`docs/`](docs/) as it's drawn.

**Modules**

| Module        | Role                                                           |
|---------------|----------------------------------------------------------------|
| `conv_top`    | Top-level integration + control FSM                            |
| line buffers  | Two `IMAGE_SIZE`-wide row stores (`buf_newer`, `buf_older`)     |
| window        | 3×3 shift-register window feeding the MAC taps                 |
| MAC unit      | `KERNEL_SIZE²` multiplies + accumulation                       |

The FSM suppresses invalid MAC outputs during pipeline warm-up and at row boundaries,
mirroring the loop-bound logic of the C++ golden model.

## Parameters & bit widths

| Parameter      | Value / derivation                                              |
|----------------|-----------------------------------------------------------------|
| `IMAGE_SIZE`   | `5` (default)                                                   |
| `KERNEL_SIZE`  | `3` (default)                                                  |
| `PIXEL_WIDTH`  | `8`                                                            |
| `WEIGHT_WIDTH` | `8`                                                           |
| `ACC_WIDTH`    | `PIXEL_WIDTH + WEIGHT_WIDTH + $clog2(KERNEL_SIZE*KERNEL_SIZE)` |
| counters       | `[$clog2(IMAGE_SIZE)-1:0]`                                     |

`ACC_WIDTH` is sized to hold the worst-case sum of `KERNEL_SIZE²` products without
overflow (20 bits for a 3×3 kernel). Convention: unsigned values, cross-correlation
(no kernel flip).

## Skills demonstrated

- RTL datapath design (Verilog)
- Control FSM design
- On-chip memory / streaming line-buffer architecture
- SystemVerilog verification — testbench, SVA assertions, functional coverage
- C++ golden-model methodology for reference checking
- Parameterized, synthesis-aware design

## Repository structure

```
conv-engine/
├── README.md      project description (this file)
├── .gitignore     ignores simulation/build artifacts
├── docs/          specs, block diagrams, design decisions
├── rtl/           Verilog RTL source
├── tb/            SystemVerilog testbenches, assertions, coverage
├── model/         C++ golden model
├── sim/           ModelSim .do scripts and run notes
└── scripts/       Python tooling (regression, log parsing) — later phase
```

## Toolchain

Simulation-only workflow (no physical FPGA board):

- **RTL:** Verilog
- **Verification:** SystemVerilog (SVA, functional coverage)
- **Simulator:** ModelSim 10.5b (bundled with Quartus Prime Lite 18.1)
- **Golden model:** C++
- **Scripting (later):** Python / NumPy

## Build & run

> _Coming as the ModelSim `.do` scripts land in [`sim/`](sim/)._

## Verification strategy

The reference is a C++ golden model that computes the expected output for a given
image and kernel. The SystemVerilog testbench will drive the RTL with the same stimulus
and compare against the golden output, backed by SVA assertions on protocol/datapath
invariants and functional coverage on parameter and boundary conditions.

Asymmetric, non-trivial stimulus (e.g. a sequential 1–25 image with a Sobel-like kernel)
is used deliberately to expose transposition and indexing bugs that symmetric inputs hide.

> _Detailed assertion and coverage plans to be added as verification is built out._

## Status & roadmap

- [x] C++ golden model (5×5 image, 3×3 kernel) — verified against hand calculation
- [x] Bit-width and parameter decisions locked
- [x] Block-level I/O map (port-boundary granularity)
- [x] Line buffer module specification
- [x] RTL implementation — line buffers, window, MAC, `conv_top` FSM
- [x] SystemVerilog testbench with golden-model comparison
- [x] SVA assertions
- [ ] Functional coverage
- [ ] Python regression harness + log parsing
- [ ] Synthesis parameter sweep across kernel sizes

## Results

> _Waveforms and coverage reports to be added as milestones are reached._
