# 🧠 ProjectWarped3D

> A Verilog-based SIMT (Single Instruction, Multiple Threads) processor core designed to render 3D images using GPU-style parallelism and warp scheduling. Built for simulation on Intel i5 using tools like Icarus Verilog and VS Code.

---

## 🚀 Features

- 🧵 SIMT execution model (warp-based)
- 🎮 3D rendering pipeline (basic rasterization)
- 🧮 Fixed 32-thread warps
- ⏱️ Warp scheduling logic
- 📦 Instruction input via HEX files
- 🎨 Output as framebuffer for image generation

---

## 📁 Project Structure

```bash
simt3d-render/
├── src/                  # Verilog modules (core, scheduler, shader units)
│   ├── simt_core.v
│   ├── warp_scheduler.v
│   ├── alu.v
│   └── memory.v
├── testbench/            # Testbenches
│   └── simt_tb.v
├── hex/                  # Instruction and texture memory HEX files
│   └── program.hex
├── output/               # Output image dumps
│   └── frame_out.ppm
├── docs/                 # Diagrams, architecture explanations
├── README.md
└── Makefile              # Optional: simulation automation
