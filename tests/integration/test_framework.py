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
import time
from pathlib import Path
from typing import Tuple, Optional

# Import turtle-toolkit functions directly (now that it's a proper dependency)
from turtle_toolkit import assemble_program, simulate_program, compare_files


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
        self.timing_data = {}  # Store timing information
        self.test_results = {}  # Store individual test results
        
    def resolve_test_file(self, test_name_or_path: str) -> Optional[str]:
        """Resolve a test name or path to a full file path"""
        test_path = Path(test_name_or_path)
        
        # If it's already an absolute path and exists, use it
        if test_path.is_absolute() and test_path.exists():
            return str(test_path)
        
        # If it's a relative path and exists, make it absolute
        if test_path.exists():
            return str(test_path.resolve())
        
        # If it's just a name (like "load_test"), try to find it in test directories
        if not test_path.suffix:  # No file extension
            test_name = test_name_or_path
            
            # Search in common test directories
            search_dirs = [
                self.project_root / "tests" / "integration" / "test_programs",
                self.project_root / "turtle-toolkit" / "examples",
            ]
            
            for search_dir in search_dirs:
                if search_dir.exists():
                    # Try with .asm extension
                    test_file = search_dir / f"{test_name}.asm"
                    if test_file.exists():
                        return str(test_file)
        
        # If we still haven't found it, try the original path
        return test_name_or_path
        
    def run_command(self, cmd: list, cwd: str = None, capture_output: bool = True) -> Tuple[int, str, str]:
        """Run a shell command and return (return_code, stdout, stderr)"""
        print(f"Running: {' '.join(cmd)}")
        if cwd:
            print(f"  in directory: {cwd}")
        
        start_time = time.time()
        try:
            result = subprocess.run(
                cmd, 
                cwd=cwd, 
                capture_output=capture_output,
                text=True,
                check=False
            )
            elapsed = time.time() - start_time
            cmd_name = cmd[0] if cmd else "unknown"
            print(f"  ⏱️  {cmd_name} took {elapsed:.2f}s")
            return result.returncode, result.stdout, result.stderr
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"  ⏱️  Command failed after {elapsed:.2f}s")
            return -1, "", str(e)
    
    def assemble_program(self, asm_file: str, output_file: str) -> bool:
        """Assemble an assembly program to binary string format"""
        print(f"🔧 Assembling {asm_file} to {output_file}")
        
        # Convert to absolute path 
        asm_path = Path(asm_file)
        if not asm_path.is_absolute():
            asm_path = asm_path.resolve()
        
        # Make sure the file exists
        if not asm_path.exists():
            print(f"Assembly failed: File not found: {asm_path}")
            return False
        
        try:
            start_time = time.time()
            
            # Read the assembly source code
            with open(asm_path, 'r') as f:
                source_code = f.read()
            
            # Use the Assembler class directly to get both binary and formatted text
            from turtle_toolkit.assembler import Assembler
            binary_data, formatted_text = Assembler.assemble_to_binary_string(
                source_code, asm_path.name, "stripped"
            )
            
            # Write the formatted text to output file
            with open(output_file, 'w') as f:
                f.write(formatted_text)
            
            elapsed = time.time() - start_time
            self.timing_data.setdefault('assembly', []).append(elapsed)
            
            print(f"✅ Assembly successful ({elapsed:.2f}s)")
            return True
                
        except Exception as e:
            elapsed = time.time() - start_time
            self.timing_data.setdefault('assembly', []).append(elapsed)
            print(f"Assembly failed with exception: {e} ({elapsed:.2f}s)")
            return False
    
    def run_simulator(self, binstr_file: str, memory_dump: str, registers_dump: str) -> bool:
        """Run the software simulator"""
        print(f"🐢 Running simulator on {binstr_file}")
        
        try:
            start_time = time.time()
            
            # Read the binary string file and convert to bytes
            with open(binstr_file, 'r') as f:
                binstr_content = f.read().strip()
            
            # Convert binary string to bytes (assuming format like "01000100 00000001")
            # Remove comments and whitespace, then convert
            clean_binary_str = ""
            for line in binstr_content.split('\n'):
                # Remove comments (everything after //)
                line = line.split('//')[0].strip()
                # Remove all whitespace
                clean_binary_str += ''.join(line.split())
            
            # Convert binary string to bytes
            if len(clean_binary_str) % 8 != 0:
                print(f"Error: Binary string length ({len(clean_binary_str)}) not divisible by 8")
                return False
            
            binary_data = bytes([int(clean_binary_str[i:i+8], 2) for i in range(0, len(clean_binary_str), 8)])
            
            # Use library function to simulate
            result = simulate_program(
                binary_data,
                max_cycles=10000,
                dump_memory=memory_dump,
                dump_registers=registers_dump
            )
            
            elapsed = time.time() - start_time
            self.timing_data.setdefault('simulation', []).append(elapsed)
            
            if result['halted']:
                print(f"✅ Simulation successful - halted after {result['cycle_count']} cycles ({elapsed:.2f}s)")
                return True
            else:
                print(f"Simulation reached max cycles without halting ({elapsed:.2f}s)")
                return False
                
        except Exception as e:
            elapsed = time.time() - start_time
            self.timing_data.setdefault('simulation', []).append(elapsed)
            print(f"Simulation failed with exception: {e} ({elapsed:.2f}s)")
            return False
    
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
        print(f"⚡ Running RTL simulation with {binstr_file}")
        
        # Ensure RTL is built (only builds once)
        if not self.ensure_rtl_built():
            return False
        
        # Run the simulation with plusargs
        plusargs = f"+initial_instruction_memory_file={binstr_file} +final_data_memory_file={memory_dump} +final_register_file={registers_dump}"
        
        cmd = ["make", "run", f"PLUSARGS={plusargs}"]
        start_time = time.time()
        ret_code, stdout, stderr = self.run_command(cmd, cwd=str(self.rtl_dir))
        elapsed = time.time() - start_time
        self.timing_data.setdefault('rtl_simulation', []).append(elapsed)
        
        if ret_code != 0:
            print(f"RTL simulation failed: {stderr}")
            return False
        
        print(f"✅ RTL simulation successful ({elapsed:.2f}s)")
        return True
    
    def compare_dumps(self, file1: str, file2: str, dump_type: str) -> bool:
        """Compare two memory/register dumps"""
        print(f"🔍 Comparing {dump_type}: {file1} vs {file2}")
        
        try:
            start_time = time.time()
            # Use library function directly
            success = compare_files(file1, file2, ignore_comments=True, verbose=True)
            elapsed = time.time() - start_time
            self.timing_data.setdefault('comparison', []).append(elapsed)
            
            if success:
                print(f"✅ {dump_type} comparison passed! ({elapsed:.2f}s)")
                return True
            else:
                print(f"{dump_type} comparison failed! ({elapsed:.2f}s)")
                return False
                
        except Exception as e:
            elapsed = time.time() - start_time
            self.timing_data.setdefault('comparison', []).append(elapsed)
            print(f"{dump_type} comparison failed with exception: {e} ({elapsed:.2f}s)")
            return False
    
    def test_assembly_program(self, asm_file: str, test_name: str = None) -> bool:
        """Test an assembly program through both simulator and RTL"""
        if test_name is None:
            test_name = Path(asm_file).stem
        
        print(f"\n{'='*60}")
        print(f"🧪 Testing: {asm_file}")
        print(f"Test name: {test_name}")
        print(f"{'='*60}")
        
        test_start_time = time.time()
        
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
                self.test_results[test_name] = {'status': 'FAILED', 'time': time.time() - test_start_time}
                return False
            
            # Step 2: Run simulator
            if not self.run_simulator(str(binstr_file), str(sim_memory_dump), str(sim_registers_dump)):
                print("❌ Test FAILED: Simulator failed")
                self.test_results[test_name] = {'status': 'FAILED', 'time': time.time() - test_start_time}
                return False
            
            # Step 3: Run RTL simulation
            if not self.run_rtl_simulation(str(binstr_file), str(rtl_memory_dump), str(rtl_registers_dump)):
                print("❌ Test FAILED: RTL simulation failed")
                self.test_results[test_name] = {'status': 'FAILED', 'time': time.time() - test_start_time}
                return False
            
            # Step 4: Compare results
            memory_match = self.compare_dumps(str(sim_memory_dump), str(rtl_memory_dump), "Memory")
            registers_match = self.compare_dumps(str(sim_registers_dump), str(rtl_registers_dump), "Registers")
            
            test_elapsed = time.time() - test_start_time
            self.timing_data.setdefault('full_test', []).append(test_elapsed)
            
            if memory_match and registers_match:
                print(f"✅ Test PASSED: RTL and simulator results match! ({test_elapsed:.2f}s total)")
                self.test_results[test_name] = {'status': 'PASSED', 'time': test_elapsed}
                
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
                print(f"❌ Test FAILED: Results don't match ({test_elapsed:.2f}s total)")
                self.test_results[test_name] = {'status': 'FAILED', 'time': test_elapsed}
                
                # Copy files to a persistent location for debugging
                debug_dir = self.debug_dir / test_name
                debug_dir.mkdir(parents=True, exist_ok=True)
                
                for src_file in temp_path.glob("*"):
                    if src_file.is_file():
                        dst_file = debug_dir / src_file.name
                        subprocess.run(["cp", str(src_file), str(dst_file)])
                
                print(f"Debug files saved to: {debug_dir}")
                return False
    
    def print_timing_summary(self):
        """Print a concise summary of timing data collected during tests"""
        if not self.timing_data:
            return
        
        print(f"\n⏱️  PERFORMANCE BREAKDOWN")
        print(f"{'─'*40}")
        
        # Calculate total test time
        total_test_time = 0
        if 'full_test' in self.timing_data:
            total_test_time = sum(self.timing_data['full_test'])
        
        # Show breakdown by individual operations
        operation_order = ['assembly', 'simulation', 'rtl_simulation', 'comparison']
        
        for operation in operation_order:
            if operation in self.timing_data and self.timing_data[operation]:
                times = self.timing_data[operation]
                total_time = sum(times)
                avg_time = total_time / len(times)
                
                # Calculate percentage of total test time
                if total_test_time > 0:
                    percentage = (total_time / total_test_time) * 100
                    print(f"  {operation.replace('_', ' ').title():<15}: {percentage:4.1f}% ({avg_time:.2f}s avg)")
                else:
                    print(f"  {operation.replace('_', ' ').title():<15}: {avg_time:.2f}s avg")
        
        # Calculate and show overhead if significant
        if total_test_time > 0:
            accounted_time = sum([
                sum(self.timing_data.get(op, [])) 
                for op in operation_order 
                if op in self.timing_data
            ])
            overhead = total_test_time - accounted_time
            if overhead > 0.1:
                overhead_percentage = (overhead / total_test_time) * 100
                print(f"  {'Framework':<15}: {overhead_percentage:4.1f}% (overhead)")
        
        print(f"{'─'*40}")
        print(f"  {'Total Time':<15}: {total_test_time:.2f}s")
    
    def print_test_results_summary(self):
        """Print a detailed summary of all test results"""
        if not self.test_results:
            return
        
        passed_tests = [name for name, result in self.test_results.items() if result['status'] == 'PASSED']
        failed_tests = [name for name, result in self.test_results.items() if result['status'] == 'FAILED']
        
        print(f"\n📊 TEST RESULTS SUMMARY")
        print(f"{'='*60}")
        
        # Overall statistics
        total_tests = len(self.test_results)
        passed_count = len(passed_tests)
        failed_count = len(failed_tests)
        success_rate = (passed_count / total_tests * 100) if total_tests > 0 else 0
        
        print(f"Total Tests:    {total_tests:3d}")
        print(f"Passed:         {passed_count:3d}  ({success_rate:5.1f}%)")
        print(f"Failed:         {failed_count:3d}  ({100-success_rate:5.1f}%)")
        
        if total_tests > 0:
            total_time = sum(result['time'] for result in self.test_results.values())
            avg_time = total_time / total_tests
            print(f"Average Time:   {avg_time:5.2f}s per test")
        
        # Show failed tests if any
        if failed_tests:
            print(f"\n❌ FAILED TESTS:")
            for test_name in failed_tests:
                test_time = self.test_results[test_name]['time']
                print(f"  • {test_name:<30} ({test_time:.2f}s)")
        
        # Show passed tests
        if passed_tests:
            print(f"\n✅ PASSED TESTS:")
            for test_name in passed_tests:
                test_time = self.test_results[test_name]['time']
                print(f"  • {test_name:<30} ({test_time:.2f}s)")
                
        print(f"{'='*60}")
    
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
        
        print(f"\n🚀 Running test suite with {len(test_patterns)} tests")
        suite_start_time = time.time()
        
        passed = 0
        failed = 0
        
        for test_file in test_patterns:
            try:
                if self.test_assembly_program(str(test_file)):
                    passed += 1
                else:
                    failed += 1
            except Exception as e:
                test_name = Path(test_file).stem
                print(f"❌ Test FAILED with exception: {e}")
                self.test_results[test_name] = {'status': 'FAILED', 'time': 0.0}
                failed += 1
        
        suite_elapsed = time.time() - suite_start_time
        
        # Print comprehensive summary
        self.print_test_results_summary()
        self.print_timing_summary()
        
        return failed == 0


def main():
    parser = argparse.ArgumentParser(description="Turtle CPU Automated Test Framework")
    parser.add_argument("--test-file", "-f", help="Single assembly file to test")
    parser.add_argument("--test", "-t", dest="test_file", help="Single assembly file to test (alias for --test-file)")
    parser.add_argument("--test-name", "-n", help="Name for the test (defaults to filename)")
    parser.add_argument("--test-suite", "-s", action="store_true", help="Run the full test suite")
    parser.add_argument("--project-root", "-r", help="Project root directory (defaults to script location)")
    parser.add_argument("--save-debug", "-d", action="store_true", help="Save debug files even when tests pass")
    
    args = parser.parse_args()
    
    framework = TurtleCPUTestFramework(args.project_root, args.save_debug)
    
    if args.test_file:
        # Resolve the test file path
        resolved_test_file = framework.resolve_test_file(args.test_file)
        
        # Check if the resolved file exists
        if not Path(resolved_test_file).exists():
            print(f"❌ Test file not found: {resolved_test_file}")
            print(f"   Searched for: {args.test_file}")
            sys.exit(1)
        
        print(f"🧪 Testing: {resolved_test_file}")
        
        # Test a single file
        success = framework.test_assembly_program(resolved_test_file, args.test_name)
        
        # Print summary for single test
        if framework.test_results:
            framework.print_test_results_summary()
            framework.print_timing_summary()
        
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
