REPO_ROOT := ../..
BUILD_DIR := $(REPO_ROOT)/build/phase4
REPORTS_DIR := $(BUILD_DIR)/reports
NETLIST_DIR := $(BUILD_DIR)/netlist
PNR_DIR := $(BUILD_DIR)/pnr
BITSTREAM_DIR := $(BUILD_DIR)/bitstream
SCHEMATIC_DIR := $(BUILD_DIR)/schematic
BASELINE_DIR := $(BUILD_DIR)/baseline
LIN_REF_DIR := $(BUILD_DIR)/linear_reference
HDL_SRC := $(REPO_ROOT)/hdl_export

TOOLS := ghdl yosys nextpnr-ice40 icepack icebox_stat iverilog vvp netlistsvg python3 jq shasum
check_tools:
	@for tool in $(TOOLS); do \
		command -v $$tool >/dev/null 2>&1 || { echo >&2 "Error: $$tool is required but not installed."; exit 1; }; \
	done

directories: check_tools
	@mkdir -p $(BUILD_DIR) $(REPORTS_DIR) $(NETLIST_DIR) $(PNR_DIR) $(BITSTREAM_DIR) $(SCHEMATIC_DIR) $(BASELINE_DIR) $(LIN_REF_DIR)

$(REPORTS_DIR)/phase3-regression.log: directories
	@echo "Running Phase 3 Regression..."
	@set -o pipefail; $(MAKE) -C $(REPO_ROOT) clean phase3 2>&1 | tee /tmp/phase3-regression.log
	@grep -F "150/150 hardware vectors matched software reference" /tmp/phase3-regression.log > /dev/null || { echo "Phase 3 regression failed"; exit 1; }
	@cp /tmp/phase3-regression.log $(REPORTS_DIR)/phase3-regression.log

phase3_regression: $(REPORTS_DIR)/phase3-regression.log

$(REPORTS_DIR)/rtl_phase4.log: directories
	@echo "Running Phase 4 RTL test..."
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -i --workdir=. --std=08 --work=work $(HDL_SRC)/packages/*.vhd $(HDL_SRC)/components/*.vhd $(HDL_SRC)/top_level/mlp_phase4.vhd $(HDL_SRC)/test_bench/tb_mlp_phase4.vhd
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -m --workdir=. --std=08 --work=work tb_mlp_phase4
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -r --workdir=. --std=08 --work=work tb_mlp_phase4 -gVECTOR_FILE="$(REPO_ROOT)/hdl_export/test_bench/data/iris_vectors.txt" 2>&1 | tee $(REPORTS_DIR)/rtl_phase4.log
	@grep -F "tb_mlp_phase4 PASSED: 150/150 vectors matched with two-cycle latency" $(REPORTS_DIR)/rtl_phase4.log > /dev/null || { echo "Phase 4 RTL test failed"; exit 1; }

rtl_phase4: $(REPORTS_DIR)/rtl_phase4.log

$(REPORTS_DIR)/rtl_linear_reference.log: directories
	@echo "Running Phase 4 Linear Reference RTL test..."
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -i --workdir=. --std=08 --work=work $(HDL_SRC)/packages/*.vhd $(HDL_SRC)/components/*.vhd $(HDL_SRC)/top_level/mlp_phase4_linear_reference.vhd $(HDL_SRC)/test_bench/tb_mlp_phase4_linear_reference.vhd
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -m --workdir=. --std=08 --work=work tb_mlp_phase4_linear_reference
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -r --workdir=. --std=08 --work=work tb_mlp_phase4_linear_reference -gVECTOR_FILE="$(REPO_ROOT)/hdl_export/test_bench/data/iris_vectors.txt" 2>&1 | tee $(REPORTS_DIR)/rtl_linear_reference.log
	@grep -F "tb_mlp_phase4_linear_reference PASSED: 150/150 vectors matched with two-cycle latency" $(REPORTS_DIR)/rtl_linear_reference.log > /dev/null || { echo "Linear Reference RTL test failed"; exit 1; }

rtl_linear_reference: $(REPORTS_DIR)/rtl_linear_reference.log

$(REPORTS_DIR)/rtl_demo.log: directories
	@echo "Running Demo RTL test..."
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -i --workdir=. --std=08 --work=work $(HDL_SRC)/packages/*.vhd $(HDL_SRC)/components/*.vhd $(HDL_SRC)/top_level/mlp_phase4.vhd $(HDL_SRC)/test_bench/tb_mlp_phase4_demo.vhd
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -m --workdir=. --std=08 --work=work tb_mlp_phase4_demo
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -r --workdir=. --std=08 --work=work tb_mlp_phase4_demo --vcd=$(REPORTS_DIR)/mlp_phase4_demo.vcd 2>&1 | tee $(REPORTS_DIR)/rtl_demo.log

rtl_demo: $(REPORTS_DIR)/rtl_demo.log

$(NETLIST_DIR)/mlp_phase4_ghdl.v: $(REPORTS_DIR)/rtl_phase4.log
	@echo "Synthesizing Phase 4 with GHDL..."
	@set -o pipefail; cd $(BUILD_DIR) && ghdl --synth --workdir=. --std=08 --out=verilog --work=work mlp_phase4 > $(NETLIST_DIR)/mlp_phase4_ghdl.v

ghdl_synth: $(NETLIST_DIR)/mlp_phase4_ghdl.v

$(LIN_REF_DIR)/mlp_phase4_linear_reference_ghdl.v: $(REPORTS_DIR)/rtl_linear_reference.log
	@echo "Synthesizing Linear Reference with GHDL..."
	@set -o pipefail; cd $(BUILD_DIR) && ghdl --synth --workdir=. --std=08 --out=verilog --work=work mlp_phase4_linear_reference > $(LIN_REF_DIR)/mlp_phase4_linear_reference_ghdl.v

linear_reference_ghdl_synth: $(LIN_REF_DIR)/mlp_phase4_linear_reference_ghdl.v

$(BASELINE_DIR)/mlp_phase3_ghdl.v: directories
	@echo "Synthesizing Phase 3 Baseline with GHDL..."
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -i --workdir=. --std=08 --work=work $(HDL_SRC)/packages/*.vhd $(HDL_SRC)/components/*.vhd $(HDL_SRC)/top_level/mlp.vhd
	@set -o pipefail; cd $(BUILD_DIR) && ghdl -m --workdir=. --std=08 --work=work mlp
	@set -o pipefail; cd $(BUILD_DIR) && ghdl --synth --workdir=. --std=08 --out=verilog --work=work mlp > $(BASELINE_DIR)/mlp_phase3_ghdl.v

baseline_ghdl_synth: $(BASELINE_DIR)/mlp_phase3_ghdl.v

$(REPORTS_DIR)/post_synth_sim.log: $(NETLIST_DIR)/mlp_phase4_ghdl.v
	@echo "Running Post-Synthesis Simulation..."
	@python3 generate_post_synth_tb.py $(REPO_ROOT)/hdl_export/test_bench/data/iris_vectors.txt $(REPORTS_DIR)/tb_mlp_phase4_post.v
	@set -o pipefail; cd $(BUILD_DIR) && iverilog -o $(REPORTS_DIR)/tb_mlp_phase4_post.out $(REPORTS_DIR)/tb_mlp_phase4_post.v $(NETLIST_DIR)/mlp_phase4_ghdl.v
	@set -o pipefail; cd $(BUILD_DIR) && vvp $(REPORTS_DIR)/tb_mlp_phase4_post.out 2>&1 | tee $(REPORTS_DIR)/post_synth_sim.log
	@grep -F "POST_SYNTH PASSED: 150/150 vectors" $(REPORTS_DIR)/post_synth_sim.log > /dev/null || { echo "Post-Synthesis simulation failed"; exit 1; }

post_synth: $(REPORTS_DIR)/post_synth_sim.log

$(NETLIST_DIR)/mlp_phase4_ice40.json: $(REPORTS_DIR)/post_synth_sim.log
	@echo "Mapping Phase 4 to iCE40..."
	@set -o pipefail; yosys -p "read_verilog $(NETLIST_DIR)/mlp_phase4_ghdl.v; synth_ice40 -top mlp_phase4 -json $(NETLIST_DIR)/mlp_phase4_ice40.json" 2>&1 | tee $(REPORTS_DIR)/yosys_ice40.log

yosys_ice40: $(NETLIST_DIR)/mlp_phase4_ice40.json

$(LIN_REF_DIR)/mlp_phase4_linear_reference_ice40.json: $(LIN_REF_DIR)/mlp_phase4_linear_reference_ghdl.v
	@echo "Mapping Linear Reference to iCE40..."
	@set -o pipefail; yosys -p "read_verilog $(LIN_REF_DIR)/mlp_phase4_linear_reference_ghdl.v; synth_ice40 -top mlp_phase4_linear_reference -json $(LIN_REF_DIR)/mlp_phase4_linear_reference_ice40.json" 2>&1 | tee $(REPORTS_DIR)/yosys_linear_reference.log

linear_reference_yosys: $(LIN_REF_DIR)/mlp_phase4_linear_reference_ice40.json

$(BASELINE_DIR)/mlp_phase3_ice40.json: $(BASELINE_DIR)/mlp_phase3_ghdl.v
	@echo "Mapping Phase 3 Baseline to iCE40..."
	@set -o pipefail; yosys -p "read_verilog $(BASELINE_DIR)/mlp_phase3_ghdl.v; synth_ice40 -top MLP -json $(BASELINE_DIR)/mlp_phase3_ice40.json" 2>&1 | tee $(REPORTS_DIR)/yosys_phase3_baseline.log

baseline_yosys: $(BASELINE_DIR)/mlp_phase3_ice40.json

$(PNR_DIR)/mlp_phase4_routed.json: $(NETLIST_DIR)/mlp_phase4_ice40.json
	@echo "Running nextpnr for Phase 4..."
	@set -o pipefail; nextpnr-ice40 --hx8k --package ct256 --json $(NETLIST_DIR)/mlp_phase4_ice40.json --pcf reference_hx8k.pcf --pcf-allow-unconstrained --asc $(PNR_DIR)/mlp_phase4.asc --freq 12 --report $(REPORTS_DIR)/nextpnr_report.json --write $(PNR_DIR)/mlp_phase4_routed.json 2>&1 | tee $(REPORTS_DIR)/nextpnr.log

pnr: $(PNR_DIR)/mlp_phase4_routed.json

$(LIN_REF_DIR)/mlp_phase4_linear_reference_routed.json: $(LIN_REF_DIR)/mlp_phase4_linear_reference_ice40.json
	@echo "Running nextpnr for Linear Reference..."
	@set -o pipefail; nextpnr-ice40 --hx8k --package ct256 --json $(LIN_REF_DIR)/mlp_phase4_linear_reference_ice40.json --pcf reference_hx8k.pcf --pcf-allow-unconstrained --asc $(LIN_REF_DIR)/mlp_phase4_linear_reference.asc --freq 12 --report $(REPORTS_DIR)/nextpnr_linear_reference_report.json --write $(LIN_REF_DIR)/mlp_phase4_linear_reference_routed.json 2>&1 | tee $(REPORTS_DIR)/nextpnr_linear_reference.log

linear_reference_pnr: $(LIN_REF_DIR)/mlp_phase4_linear_reference_routed.json

$(BASELINE_DIR)/mlp_phase3_routed.json: $(BASELINE_DIR)/mlp_phase3_ice40.json
	@echo "Running nextpnr for Phase 3 Baseline..."
	@set -o pipefail; nextpnr-ice40 --hx8k --package ct256 --json $(BASELINE_DIR)/mlp_phase3_ice40.json --pcf-allow-unconstrained --asc $(BASELINE_DIR)/mlp_phase3.asc --report $(REPORTS_DIR)/nextpnr_phase3_baseline_report.json --write $(BASELINE_DIR)/mlp_phase3_routed.json 2>&1 | tee $(REPORTS_DIR)/nextpnr_phase3_baseline.log; echo $${PIPESTATUS[0]} > $(REPORTS_DIR)/baseline_pnr_exit_code.txt
	@if [ "$$(cat $(REPORTS_DIR)/baseline_pnr_exit_code.txt)" != "0" ]; then echo "Baseline PNR failed"; exit 1; fi

baseline_pnr: $(BASELINE_DIR)/mlp_phase3_routed.json

$(BITSTREAM_DIR)/mlp_phase4.bin: $(PNR_DIR)/mlp_phase4_routed.json
	@echo "Generating Bitstream for Phase 4..."
	@set -o pipefail; icepack $(PNR_DIR)/mlp_phase4.asc $(BITSTREAM_DIR)/mlp_phase4.bin
	@set -o pipefail; icebox_stat $(PNR_DIR)/mlp_phase4.asc > $(REPORTS_DIR)/icebox_stat.txt
	@set -o pipefail; yosys -p "read_verilog $(NETLIST_DIR)/mlp_phase4_ghdl.v; prep -top mlp_phase4; write_json $(NETLIST_DIR)/mlp_phase4_generic.json; write_verilog $(NETLIST_DIR)/mlp_phase4_generic.v" 2>&1 | tee $(REPORTS_DIR)/yosys_generic.log
	@set -o pipefail; netlistsvg $(NETLIST_DIR)/mlp_phase4_generic.json -o $(SCHEMATIC_DIR)/mlp_phase4.svg

bitstream: $(BITSTREAM_DIR)/mlp_phase4.bin

$(BUILD_DIR)/phase4_metrics.json: $(BITSTREAM_DIR)/mlp_phase4.bin $(LIN_REF_DIR)/mlp_phase4_linear_reference_routed.json $(BASELINE_DIR)/mlp_phase3_routed.json $(REPORTS_DIR)/rtl_demo.log $(REPORTS_DIR)/phase3-regression.log
	@python3 collect_phase4_metrics.py
	@jq -e '.verification.phase4_rtl_passed == true' $(BUILD_DIR)/phase4_metrics.json > /dev/null || { echo "Gate failed: phase4_rtl_passed"; exit 1; }
	@jq -e '.verification.linear_reference_rtl_passed == true' $(BUILD_DIR)/phase4_metrics.json > /dev/null || { echo "Gate failed: linear_reference_rtl_passed"; exit 1; }
	@jq -e '.verification.post_synth_passed == true' $(BUILD_DIR)/phase4_metrics.json > /dev/null || { echo "Gate failed: post_synth_passed"; exit 1; }
	@jq -e '.phase4_balanced.pnr_passed == true' $(BUILD_DIR)/phase4_metrics.json > /dev/null || { echo "Gate failed: pnr_passed"; exit 1; }
	@jq -e '.phase4_balanced.timing_passed == true' $(BUILD_DIR)/phase4_metrics.json > /dev/null || { echo "Gate failed: timing_passed"; exit 1; }

metrics: $(BUILD_DIR)/phase4_metrics.json

phase4: metrics
	@echo "Phase 4 Pipeline Completed Successfully."

clean:
	@rm -rf $(BUILD_DIR)
	@rm -f e~* *.o mlp tb_mlp_phase4 tb_mlp_phase4_linear_reference tb_mlp_phase4_demo work-obj*.cf 

.PHONY: check_tools directories phase3_regression rtl_phase4 rtl_linear_reference rtl_demo ghdl_synth linear_reference_ghdl_synth baseline_ghdl_synth post_synth yosys_ice40 linear_reference_yosys baseline_yosys pnr linear_reference_pnr baseline_pnr bitstream metrics phase4 clean
