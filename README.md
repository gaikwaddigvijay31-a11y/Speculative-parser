# Speculative Parser – FPGA HFT Market Data Processing

A SystemVerilog-based speculative market data parser designed for FPGA-oriented High-Frequency Trading (HFT) systems.

The project focuses on parsing fixed-width binary market data messages, decoding order-related events, and building a simulation-driven RTL verification workflow using Icarus Verilog and GitHub Actions.

## Project Overview

The speculative parser receives market data through a 64-bit AXI-Stream interface and assembles four consecutive 64-bit words into a 256-bit message buffer.

It identifies the message type and decodes the associated fields into a structured `parsed_msg_t` output.

### Supported Message Types

- ADD
- DELETE
- REPLACE
- EXECUTE
- TRADE

Unknown message types are rejected and recorded in the parser error counter.

## Architecture

```text
             AXI-Stream Input
                    |
                    v
          64-bit Input Interface
                    |
                    v
             Message Buffer
              (256 bits)
                    |
                    v
             Field Extraction
                    |
                    v
           Message Type Detection
                    |
          +---------+---------+
          |         |         |
          v         v         v
         ADD      DELETE    REPLACE
          |         |         |
          +---------+---------+
                    |
              +-----+-----+
              |           |
              v           v
           EXECUTE      TRADE
              |           |
              +-----+-----+
                    |
                    v
              Priority MUX
                    |
                    v
             Parsed Message
                    |
                    v
            Statistics Counters
```

## RTL Features

- 64-bit AXI-Stream input interface.
- 256-bit message assembly buffer.
- Four-word message collection.
- Message type detection.
- Parallel message decoding logic.
- Priority-based output selection.
- Structured SystemVerilog message output.
- Valid message counter.
- Parse error counter.
- Synchronous message processing with asynchronous active-low reset.

## Project Structure

```text
speculative-parser/
│
├── rtl/
│   ├── fixed_point_pkg.sv
│   └── speculative_parser.sv
│
├── tb/
│   └── tb_speculative_parser.sv
│
├── .github/
│   └── workflows/
│       └── rtl-verification.yml
│
└── README.md
```

## Requirements

The project uses:

- Ubuntu Linux / WSL
- Icarus Verilog
- GTKWave (optional, for waveform inspection)
- Git
- GitHub Actions

## Simulation

### 1. Clone the repository

```bash
git clone https://github.com/gaikwaddigvijay31-a11y/speculative-parser.git
```

### 2. Enter the project directory

```bash
cd speculative-parser
```

### 3. Install Icarus Verilog

```bash
sudo apt update
sudo apt install -y iverilog
```

### 4. Compile the RTL and testbench

```bash
iverilog -g2012 -Wall \
-s tb_speculative_parser \
-o sim_speculative.out \
rtl/fixed_point_pkg.sv \
rtl/speculative_parser.sv \
tb/tb_speculative_parser.sv
```

### 5. Run simulation

```bash
vvp sim_speculative.out
```

### 6. View waveforms

```bash
gtkwave speculative_parser.vcd
```

## Verification

The SystemVerilog testbench is intended to verify:

| Test | Description |
|---|---|
| ADD | ADD message decoding |
| DELETE | DELETE message decoding |
| REPLACE | REPLACE message decoding |
| EXECUTE | EXECUTE message decoding |
| TRADE | TRADE message decoding |
| Unknown Type | Invalid message rejection |
| Message Counter | Valid message counting |
| Parse Errors | Invalid message counting |

## Continuous Integration

This repository uses GitHub Actions for automated RTL compilation and simulation.

The workflow is configured to execute on:

- Push events
- Pull request events

### CI Pipeline

```text
Git Push / Pull Request
          |
          v
     GitHub Actions
          |
          v
     Ubuntu Runner
          |
          v
 Install Icarus Verilog
          |
          v
    Compile RTL
          |
          v
   Run Testbench
          |
          v
   PASS / FAIL
```

Workflow configuration:

```text
.github/workflows/rtl-verification.yml
```

## Design Objectives

The project explores hardware-oriented market data processing concepts relevant to FPGA-based HFT systems:

1. Binary market data message parsing.
2. Fixed-width data representation.
3. Parallel decoding architectures.
4. RTL modularity and synthesizable design practices.
5. Simulation-based functional verification.
6. Automated hardware-description-language verification using CI.

## Future Development

- Improve AXI-Stream handshake and backpressure handling.
- Validate `tkeep` and `tlast`.
- Correct and formally define the message field layout.
- Add malformed and incomplete message handling.
- Add randomized testbench stimulus.
- Add SystemVerilog assertions.
- Perform synthesis and resource utilization analysis.
- Explore FPGA timing analysis and latency optimization.
- Integrate the parser with a downstream order book and trading datapath.

## Disclaimer

This is an educational and engineering project focused on FPGA-oriented HFT market data processing.

The current implementation is a simulation-stage RTL design. FPGA synthesis, timing closure, physical hardware validation, and end-to-end trading latency measurements have not yet been established.

## Author

**Digvijay Gaikwad**

GitHub: https://github.com/gaikwaddigvijay31-a11y
