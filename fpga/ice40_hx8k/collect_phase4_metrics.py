import os
import json
import re
import sys
import hashlib

def get_sha256(filepath):
    if not os.path.exists(filepath):
        return None
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256.update(chunk)
    return sha256.hexdigest()

def grep_file(filepath, pattern):
    if not os.path.exists(filepath):
        return False
    with open(filepath, 'r') as f:
        for line in f:
            if pattern in line:
                return True
    return False

def parse_yosys_stats(filepath):
    lut = 0
    dff = 0
    carry = 0
    if not os.path.exists(filepath):
        return lut, dff, carry, 0
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    start_idx = 0
    for i, line in enumerate(lines):
        if '=== design hierarchy ===' in line:
            start_idx = i
    # Process only the final hierarchy report
    in_submodules_section = False
    for line in lines[start_idx:]:
        if 'submodules' in line:
            in_submodules_section = True
        if in_submodules_section:
            m = re.match(r'^\s+(\d+)\s+SB_LUT4\s*$', line)
            if m:
                lut += int(m.group(1))
            
            m_carry = re.match(r'^\s+(\d+)\s+SB_CARRY\s*$', line)
            if m_carry:
                carry += int(m_carry.group(1))
                
            m_dff = re.match(r'^\s+(\d+)\s+SB_DFF.*$', line)
            if m_dff:
                dff += int(m_dff.group(1))
            
            

    return lut, dff, carry, lut + dff + carry

def parse_icebox_stat(filepath):
    stats = {
        'post_pnr_lut_count': 0,
        'post_pnr_dff_count': 0,
        'post_pnr_carry_count': 0,
        'post_pnr_bram_count': 0,
        'post_pnr_iob_count': 0,
        'post_pnr_pll_count': 0,
        'post_pnr_glb_count': 0
    }
    if not os.path.exists(filepath):
        return stats
    
    with open(filepath, 'r') as f:
        for line in f:
            if line.startswith('LUTs:'):
                stats['post_pnr_lut_count'] = int(line.split()[1])
            elif line.startswith('DFFs:'):
                stats['post_pnr_dff_count'] = int(line.split()[1])
            elif line.startswith('CARRYs:'):
                stats['post_pnr_carry_count'] = int(line.split()[1])
            elif line.startswith('BRAMs:'):
                stats['post_pnr_bram_count'] = int(line.split()[1])
            elif line.startswith('IOBs:'):
                stats['post_pnr_iob_count'] = int(line.split()[1])
            elif line.startswith('PLLs:'):
                stats['post_pnr_pll_count'] = int(line.split()[1])
            elif line.startswith('GLBs:'):
                stats['post_pnr_glb_count'] = int(line.split()[1])
    return stats

def parse_nextpnr_json(filepath):
    fmax = None
    constraint = None
    if not os.path.exists(filepath):
        return fmax, constraint
    with open(filepath, 'r') as f:
        data = json.load(f)
    if 'fmax' in data and data['fmax']:
        first_clk = list(data['fmax'].keys())[0]
        clk_data = data['fmax'][first_clk]
        fmax = clk_data.get('achieved')
        constraint = clk_data.get('constraint')
    return fmax, constraint

def parse_nextpnr_log(filepath):
    passed = False
    if not os.path.exists(filepath):
        return passed
    routing_complete = False
    finished_normally = False
    with open(filepath, 'r') as f:
        for line in f:
            if 'Routing complete' in line:
                routing_complete = True
            if 'Program finished normally' in line:
                finished_normally = True
    return routing_complete and finished_normally

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
    build_dir = os.path.join(repo_root, 'build', 'phase4')
    reports_dir = os.path.join(build_dir, 'reports')
    
    phase4_rtl_log = os.path.join(reports_dir, 'rtl_phase4.log')
    linear_ref_rtl_log = os.path.join(reports_dir, 'rtl_linear_reference.log')
    
    phase4_rtl_passed = grep_file(phase4_rtl_log, 'tb_mlp_phase4 PASSED: 150/150 vectors matched with two-cycle latency')
    linear_ref_rtl_passed = grep_file(linear_ref_rtl_log, 'tb_mlp_phase4_linear_reference PASSED: 150/150 vectors matched with two-cycle latency')
    
    post_synth_log = os.path.join(reports_dir, 'post_synth_sim.log')
    post_synth_passed = grep_file(post_synth_log, 'POST_SYNTH PASSED: 150/150 vectors')
    
    base_lut, base_dff, base_carry, base_cells = parse_yosys_stats(os.path.join(reports_dir, 'yosys_phase3_baseline.log'))
    lin_lut, lin_dff, lin_carry, lin_cells = parse_yosys_stats(os.path.join(reports_dir, 'yosys_linear_reference.log'))
    bal_lut, bal_dff, bal_carry, bal_cells = parse_yosys_stats(os.path.join(reports_dir, 'yosys_ice40.log'))
    
    icebox_stats = parse_icebox_stat(os.path.join(reports_dir, 'icebox_stat.txt'))
    
    bal_fmax, bal_constraint = parse_nextpnr_json(os.path.join(reports_dir, 'nextpnr_report.json'))
    lin_fmax, lin_constraint = parse_nextpnr_json(os.path.join(reports_dir, 'nextpnr_linear_reference_report.json'))
    
    base_pnr_passed = parse_nextpnr_log(os.path.join(reports_dir, 'nextpnr_phase3_baseline.log'))
    lin_pnr_passed = parse_nextpnr_log(os.path.join(reports_dir, 'nextpnr_linear_reference.log'))
    bal_pnr_passed = parse_nextpnr_log(os.path.join(reports_dir, 'nextpnr.log'))
    
    with open(os.path.join(reports_dir, 'baseline_pnr_exit_code.txt'), 'r') as f:
        base_pnr_exit = int(f.read().strip())
    if base_pnr_exit != 0:
        base_pnr_passed = False
        
    phase3_regression_passed = grep_file(os.path.join(reports_dir, 'phase3-regression.log'), '150/150 hardware vectors matched software reference')
    if not phase3_regression_passed:
        print("Phase 3 regression evidence missing!")
        sys.exit(1)
        
    files_to_hash = {
        'mlp_phase4_ghdl.v': os.path.join(build_dir, 'netlist', 'mlp_phase4_ghdl.v'),
        'mlp_phase4_generic.json': os.path.join(build_dir, 'netlist', 'mlp_phase4_generic.json'),
        'mlp_phase4_generic.v': os.path.join(build_dir, 'netlist', 'mlp_phase4_generic.v'),
        'mlp_phase4_ice40.json': os.path.join(build_dir, 'netlist', 'mlp_phase4_ice40.json'),
        'mlp_phase4_routed.json': os.path.join(build_dir, 'pnr', 'mlp_phase4_routed.json'),
        'mlp_phase4.asc': os.path.join(build_dir, 'pnr', 'mlp_phase4.asc'),
        'mlp_phase4.bin': os.path.join(build_dir, 'bitstream', 'mlp_phase4.bin'),
        'mlp_phase4.svg': os.path.join(build_dir, 'schematic', 'mlp_phase4.svg'),
        'mlp_phase4_demo.vcd': os.path.join(build_dir, 'reports', 'mlp_phase4_demo.vcd'),
        'nextpnr_report.json': os.path.join(reports_dir, 'nextpnr_report.json'),
        'iris_vectors.txt': os.path.join(repo_root, 'hdl_export', 'test_bench', 'data', 'iris_vectors.txt')
    }
    hashes = {}
    for name, path in files_to_hash.items():
        h = get_sha256(path)
        if h is None:
            print(f"Error: Required artifact {name} at {path} is missing!")
            sys.exit(1)
        hashes[name] = h
        
    bitstream_size = os.path.getsize(files_to_hash['mlp_phase4.bin'])
    
    timing_passed = bal_fmax is not None and bal_constraint is not None and bal_fmax >= bal_constraint
    
    schema = {
        "target": {
            "family": "iCE40",
            "device": "HX8K",
            "package": "CT256",
            "target_frequency_mhz": 12.0,
            "pin_mode": "automatic_unconstrained",
            "hardware_flash_safe": False
        },
        "verification": {
            "phase3_regression_passed": phase3_regression_passed,
            "phase4_rtl_vectors": 150,
            "phase4_rtl_passed": phase4_rtl_passed,
            "linear_reference_rtl_vectors": 150,
            "linear_reference_rtl_passed": linear_ref_rtl_passed,
            "post_synth_vectors": 150,
            "post_synth_passed": post_synth_passed
        },
        "phase3_baseline": {
            "latency_cycles": 1,
            "yosys_lut": base_lut,
            "yosys_dff": base_dff,
            "yosys_carry": base_carry,
            "yosys_primitive_cells": base_cells,
            "pnr_passed": base_pnr_passed,
            "fmax_mhz": None,
            "fmax_unavailable_reason": "no interior register-to-register timing path"
        },
        "phase4_linear_reference": {
            "latency_cycles": 2,
            "yosys_lut": lin_lut,
            "yosys_dff": lin_dff,
            "yosys_carry": lin_carry,
            "yosys_primitive_cells": lin_cells,
            "pnr_passed": lin_pnr_passed,
            "fmax_mhz": lin_fmax
        },
        "phase4_balanced": {
            "latency_cycles": 2,
            "yosys_lut": bal_lut,
            "yosys_dff": bal_dff,
            "yosys_carry": bal_carry,
            "yosys_primitive_cells": bal_cells,
            "post_pnr_lut": icebox_stats['post_pnr_lut_count'],
            "post_pnr_dff": icebox_stats['post_pnr_dff_count'],
            "post_pnr_carry": icebox_stats['post_pnr_carry_count'],
            "post_pnr_iob": icebox_stats['post_pnr_iob_count'],
            "pnr_passed": bal_pnr_passed,
            "timing_passed": timing_passed,
            "fmax_mhz": bal_fmax,
            "target_mhz": 12.0
        },
        "artifacts": {
            "bitstream_size_bytes": bitstream_size,
            "hashes": hashes
        },
        "git": {
            "phase3_commit": "b4b64317b8ba1b65d6ceff131b59cc29e1594937",
            "phase4_committed": False,
            "pushed": False
        }
    }
    
    out_json = os.path.join(build_dir, 'phase4_metrics.json')
    with open(out_json, 'w') as f:
        json.dump(schema, f, indent=2)

    print("Phase 4 metrics collected successfully.")

if __name__ == '__main__':
    main()
