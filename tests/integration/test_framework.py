#!/usr/bin/env python3
"""
Automated Testing Framework for Turtle CPU
Compares RTL simulation results with software simulator results
Author: GitHub Copilot
Date: 2025-07-20
"""

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Tuple, Optional


class TurtleCPUTestFramework:
    def __init__(self, project_root: str = None, save_debug: bool = False):
        # If no project root specified, go up two levels from this script
        if project_root:
            self.project_root = Path(project_root)
        else:
            self.project_root = Path(__file__).parent.parent.parent
        
        self.turtle_toolkit_dir = self.project_root / "turtle-toolkit"
        self.rtl_dir = self.project_root / "src" / "turtle_cpu_top"
        self.save_debug = save_debug
        self.debug_dir = self.project_root / "tests" / "integration" / "debug_output"
        self.rtl_built = False  # Track if RTL has been built
        
    def run_command(self, cmd: list, cwd: str = None, capture_output: bool = True) -> Tuple[int, str, str]:
        """Run a shell command and return (return_code, stdout, stderr)"""
        print(f"Running: {' '.join(cmd)}")
        if cwd:
            print(f"  in directory: {cwd}")
        
        try:
            result = subprocess.run(
                cmd, 
                cwd=cwd, 
                capture_output=capture_output,
                text=True,
                check=False
            )
            return result.returncode, result.stdout, result.stderr
        except Exception as e:
            return -1, "", str(e)
    
    def assemble_program(self, asm_file: str, output_file: str) -> bool:
        """Assemble an assembly program to binary string format"""
        print(f"Assembling {asm_file} to {output_file}")
        
        # Convert to absolute path 
        asm_path = Path(asm_file)
        if not asm_path.is_absolute():
            asm_path = asm_path.resolve()
        
        # Make sure the file exists
        if not asm_path.exists():
            print(f"Assembly failed: File not found: {asm_path}")
            return False
        
        # For the turtle-toolkit, we need to provide a path relative to the turtle_toolkit_dir
        # or use absolute path if outside
        try:
            rel_asm_path = asm_path.relative_to(self.turtle_toolkit_dir)
        except ValueError:
            # File is outside turtle_toolkit_dir, use absolute path
            rel_asm_path = asm_path
        
        cmd = [
            "poetry", "run", "turtle-toolkit", "assemble",
            "--format", "binstr",
            str(rel_asm_path),
            "-o", output_file
        ]
        
        ret_code, stdout, stderr = self.run_command(cmd, cwd=str(self.turtle_toolkit_dir))
        
        if ret_code != 0:
            print(f"Assembly failed: {stderr}")
            print(f"Assembly stdout: {stdout}")
            return False
        
        print("Assembly successful")
        return True
    
    def run_simulator(self, binstr_file: str, memory_dump: str, registers_dump: str) -> bool:
        """Run the software simulator"""
        print(f"Running simulator on {binstr_file}")
        
        cmd = [
            "poetry", "run", "turtle-toolkit", "simulate",
            "--format", "binstr",
            binstr_file,
            "--dump-memory", memory_dump,
            "--dump-memory-full",
            "--dump-registers", registers_dump
        ]
        
        ret_code, stdout, stderr = self.run_command(cmd, cwd=str(self.turtle_toolkit_dir))
        
        if ret_code != 0:
            print(f"Simulation failed: {stderr}")
            return False
        
        print("Simulation successful")
        return True
    
    def ensure_rtl_built(self) -> bool:
        """Ensure RTL is built (build only once)"""
        if not self.rtl_built:
            print("Building RTL (one-time setup)...")
            ret_code, stdout, stderr = self.run_command(["make", "rebuild"], cwd=str(self.rtl_dir))
            if ret_code != 0:
                print(f"RTL rebuild failed: {stderr}")
                return False
            print("RTL build successful")
            self.rtl_built = True
        return True
    
    def run_rtl_simulation(self, binstr_file: str, memory_dump: str, registers_dump: str) -> bool:
        """Run the RTL simulation"""
        print(f"Running RTL simulation with {binstr_file}")
        
        # Ensure RTL is built (only builds once)
        if not self.ensure_rtl_built():
            return False
        
        # Run the simulation with plusargs
        plusargs = f"+initial_instruction_memory_file={binstr_file} +final_data_memory_file={memory_dump} +final_register_file={registers_dump}"
        
        cmd = ["make", "run", f"PLUSARGS={plusargs}"]
        ret_code, stdout, stderr = self.run_command(cmd, cwd=str(self.rtl_dir))
        
        if ret_code != 0:
            print(f"RTL simulation failed: {stderr}")
            return False
        
        print("RTL simulation successful")
        return True
    
    def compare_dumps(self, file1: str, file2: str, dump_type: str) -> bool:
        """Compare two memory/register dumps"""
        print(f"Comparing {dump_type}: {file1} vs {file2}")
        
        cmd = [
            "poetry", "run", "turtle-toolkit", "mem-compare",
            file1, file2,
            "--ignore-comments",
            "--verbose"
        ]
        
        ret_code, stdout, stderr = self.run_command(cmd, cwd=str(self.turtle_toolkit_dir))
        
        if ret_code != 0:
            print(f"{dump_type} comparison failed!")
            print(f"Output: {stdout}")
            print(f"Error: {stderr}")
            return False
        
        print(f"{dump_type} comparison passed!")
        return True
    
    def test_assembly_program(self, asm_file: str, test_name: str = None) -> bool:
        """Test an assembly program through both simulator and RTL"""
        if test_name is None:
            test_name = Path(asm_file).stem
        
        print(f"\n{'='*60}")
        print(f"Testing: {asm_file}")
        print(f"Test name: {test_name}")
        print(f"{'='*60}")
        
        # Create temporary directory for test outputs
        with tempfile.TemporaryDirectory(prefix=f"turtle_test_{test_name}_") as temp_dir:
            temp_path = Path(temp_dir)
            
            # File paths
            binstr_file = temp_path / f"{test_name}_instructions.binstr.txt"
            
            sim_memory_dump = temp_path / f"{test_name}_sim_memory.binstr.txt"
            sim_registers_dump = temp_path / f"{test_name}_sim_registers.binstr.txt"
            
            rtl_memory_dump = temp_path / f"{test_name}_rtl_memory.binstr.txt"
            rtl_registers_dump = temp_path / f"{test_name}_rtl_registers.binstr.txt"
            
            # Step 1: Assemble the program
            if not self.assemble_program(asm_file, str(binstr_file)):
                print("❌ Test FAILED: Assembly failed")
                return False
            
            # Step 2: Run simulator
            if not self.run_simulator(str(binstr_file), str(sim_memory_dump), str(sim_registers_dump)):
                print("❌ Test FAILED: Simulator failed")
                return False
            
            # Step 3: Run RTL simulation
            if not self.run_rtl_simulation(str(binstr_file), str(rtl_memory_dump), str(rtl_registers_dump)):
                print("❌ Test FAILED: RTL simulation failed")
                return False
            
            # Step 4: Compare results
            memory_match = self.compare_dumps(str(sim_memory_dump), str(rtl_memory_dump), "Memory")
            registers_match = self.compare_dumps(str(sim_registers_dump), str(rtl_registers_dump), "Registers")
            
            if memory_match and registers_match:
                print("✅ Test PASSED: RTL and simulator results match!")
                
                # Save debug files if requested
                if self.save_debug:
                    debug_dir = self.debug_dir / test_name
                    debug_dir.mkdir(parents=True, exist_ok=True)
                    
                    for src_file in temp_path.glob("*"):
                        if src_file.is_file():
                            dst_file = debug_dir / src_file.name
                            subprocess.run(["cp", str(src_file), str(dst_file)])
                    
                    print(f"Debug files saved to: {debug_dir}")
                
                return True
            else:
                print("❌ Test FAILED: Results don't match")
                
                # Copy files to a persistent location for debugging
                debug_dir = self.debug_dir / test_name
                debug_dir.mkdir(parents=True, exist_ok=True)
                
                for src_file in temp_path.glob("*"):
                    if src_file.is_file():
                        dst_file = debug_dir / src_file.name
                        subprocess.run(["cp", str(src_file), str(dst_file)])
                
                print(f"Debug files saved to: {debug_dir}")
                return False
    
    def run_test_suite(self, test_patterns: list = None) -> bool:
        """Run a suite of tests"""
        if test_patterns is None:
            # Default test patterns - look for .asm files in examples and test_programs
            examples_dir = self.turtle_toolkit_dir / "examples"
            test_programs_dir = self.project_root / "tests" / "integration" / "test_programs"
            
            test_patterns = []
            if examples_dir.exists():
                test_patterns.extend(list(examples_dir.glob("*.asm")))
            if test_programs_dir.exists():
                test_patterns.extend(list(test_programs_dir.glob("*.asm")))
        
        print(f"\nRunning test suite with {len(test_patterns)} tests")
        
        passed = 0
        failed = 0
        
        for test_file in test_patterns:
            try:
                if self.test_assembly_program(str(test_file)):
                    passed += 1
                else:
                    failed += 1
            except Exception as e:
                print(f"❌ Test FAILED with exception: {e}")
                failed += 1
        
        print(f"\n{'='*60}")
        print(f"Test Results: {passed} passed, {failed} failed")
        print(f"{'='*60}")
        
        return failed == 0


def main():
    parser = argparse.ArgumentParser(description="Turtle CPU Automated Test Framework")
    parser.add_argument("--test-file", "-f", help="Single assembly file to test")
    parser.add_argument("--test-name", "-n", help="Name for the test (defaults to filename)")
    parser.add_argument("--test-suite", "-s", action="store_true", help="Run the full test suite")
    parser.add_argument("--project-root", "-r", help="Project root directory (defaults to script location)")
    parser.add_argument("--save-debug", "-d", action="store_true", help="Save debug files even when tests pass")
    
    args = parser.parse_args()
    
    framework = TurtleCPUTestFramework(args.project_root, args.save_debug)
    
    if args.test_file:
        # Test a single file
        success = framework.test_assembly_program(args.test_file, args.test_name)
        sys.exit(0 if success else 1)
    elif args.test_suite:
        # Run the full test suite
        success = framework.run_test_suite()
        sys.exit(0 if success else 1)
    else:
        # Default: run test suite
        success = framework.run_test_suite()
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
