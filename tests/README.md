# Turtle CPU Tests

Automated testing framework that compares RTL simulation results with software simulator results.

## Quick Start

```bash
# From tests directory
make test                                          # Run all tests (32 comprehensive programs)
make test-single TEST_FILE=integration/test_programs/basic_set.asm     # Test single file
make clean                                         # Clean debug output
```

## How It Works

1. **Assembles** `.asm` files to binary using `turtle-toolkit assemble`
2. **Runs software simulator** and dumps final memory/registers
3. **Runs RTL simulation** and dumps final memory/registers  
4. **Compares results** using `turtle-toolkit mem-compare`

## Directory Structure

```
tests/
├── integration/
│   ├── test_framework.py     # Main framework script
│   ├── test_programs/        # Custom test assembly files
│   └── debug_output/         # Debug files from failed tests
├── Makefile                  # Test targets
└── README.md                 # This file
```

## Usage

### Make Targets (from tests directory)
```bash
make test                    # Run full test suite
make test-single TEST_FILE=path/to/file.asm [TEST_NAME=name]
make clean                   # Clean debug output
```

### Direct Script Usage
```bash
cd tests/integration
python3 test_framework.py --test-suite                        # All tests
python3 test_framework.py --test-file test_programs/file.asm  # Single test
python3 test_framework.py --help                              # Show options
```

## Test Results

- ✅ **PASSED**: RTL and simulator produce identical results
- ❌ **FAILED**: Differences detected (debug files saved automatically)

Debug files include assembled instructions, memory dumps, register dumps, and detailed diff output.

## Adding Tests

Just add `.asm` files to `test_programs/` - they'll be discovered automatically.

## Current Test Suite (32 programs)

**Basic Instructions:** `basic_set.asm`
**Arithmetic:** `add_test.asm`, `addi_test.asm`, `sub_test.asm`, `subi_test.asm`
**Logic:** `and_test.asm`, `andi_test.asm`, `or_test.asm`, `ori_test.asm`, `xor_test.asm`, `xori_test.asm`, `inv_test.asm`
**Register Ops:** `put_test.asm`, `get_test.asm`, `all_registers_test.asm`
**Memory Ops:** `store_test.asm`, `load_test.asm`, `store_load_different_addr.asm`
**Control Flow:** `jmpi_test.asm`
**Conditional Branches:** `bz_taken_test.asm`, `bz_not_taken_test.asm`, `bnz_taken_test.asm`, `bnz_not_taken_test.asm`, `bp_taken_test.asm`, `bp_not_taken_test.asm`, `bn_taken_test.asm`, `bn_not_taken_test.asm`, `bcs_taken_test.asm`, `bcs_not_taken_test.asm`, `bcc_taken_test.asm`, `bcc_not_taken_test.asm`
**Legacy:** `test_fixed.asm`

## Requirements

- Working `turtle-toolkit` (Poetry)
- Working RTL simulation (Verilator/Make)  
- Python 3.11+
