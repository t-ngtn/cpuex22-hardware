# cpuex22-hardware
FPGA implementation of processor for original ISA

## contents
```text
.
├── core
│   ├── 2nd                   // Processor for original ISA
│   ├── fibcore               // Simple Processor for Fibonacci function
│   ├── sim                   // Simulation of server.py
│   └── uart                  // Module for UART communication
├── fpu                  
│   ├── pipeline              // Pipelined FPU (below)
│   └── single                // Module that performs floating-point number operations in one cycle
└── memory
    ├── cpuex2021-4-dram-main // Empty. It's my senior's. thx.
    ├── memocon.sv            // Module connecting memory and cache
    └── SAcache4.sv           // Set Associative cache
```
