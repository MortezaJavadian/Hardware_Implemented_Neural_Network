SHELL := /bin/bash

GHDL      ?= ghdl
PYTHON    ?= .venv/bin/python
GHDL_STD   = --std=08

BUILD_DIR  = build/phase3
GHDL_WORK  = $(BUILD_DIR)/ghdl
VECTORS    = hdl_export/test_bench/data/iris_vectors.txt

ROOT_GHDL_ARTIFACTS = \
	tb_relu \
	tb_sigmoid \
	tb_argmax \
	tb_gradient_descent \
	tb_mlp \
	tb_mlp_demo \
	e~tb_relu.o \
	e~tb_sigmoid.o \
	e~tb_argmax.o \
	e~tb_gradient_descent.o \
	e~tb_mlp.o \
	e~tb_mlp_demo.o

SRCS = \
	hdl_export/packages/nn_types_pkg.vhd \
	hdl_export/packages/model_parameters_pkg.vhd \
	hdl_export/components/relu.vhd \
	hdl_export/components/sigmoid.vhd \
	hdl_export/components/weight_register.vhd \
	hdl_export/components/neuron.vhd \
	hdl_export/components/layer.vhd \
	hdl_export/components/argmax.vhd \
	hdl_export/components/gradient_descent.vhd \
	hdl_export/top_level/mlp.vhd

TB_SRCS = \
	hdl_export/test_bench/tb_relu.vhd \
	hdl_export/test_bench/tb_sigmoid.vhd \
	hdl_export/test_bench/tb_argmax.vhd \
	hdl_export/test_bench/tb_gradient_descent.vhd \
	hdl_export/test_bench/test.vhd \
	hdl_export/test_bench/tb_mlp_demo.vhd

.PHONY: \
	help \
	venv \
	check-env \
	model \
	analyze \
	test-components \
	test-mlp \
	test \
	demo \
	phase3 \
	clean \
	clean-root-artifacts \
	verify-root-clean

.NOTPARALLEL:

help:
	@echo "Targets:"
	@echo "  venv                 - Create .venv and install Python dependencies"
	@echo "  check-env             - Verify Python and GHDL"
	@echo "  model                 - Train model and generate Phase 3 artifacts"
	@echo "  analyze               - Analyze all VHDL sources and testbenches"
	@echo "  test-components       - Run component testbenches"
	@echo "  test-mlp              - Run the 150-vector MLP equivalence test"
	@echo "  test                  - Run all VHDL tests"
	@echo "  demo                  - Run demo and generate VCD"
	@echo "  phase3                - Run the complete Phase 3 pipeline"
	@echo "  clean                 - Remove build/phase3"
	@echo "  clean-root-artifacts  - Remove old GHDL files from repository root"
	@echo "  verify-root-clean     - Fail if GHDL artifacts exist in repository root"

venv:
	python3 -m venv .venv
	. .venv/bin/activate && \
		python -m pip install --upgrade pip && \
		python -m pip install -r requirements.txt

check-env:
	@command -v $(GHDL) >/dev/null 2>&1 || { \
		echo "ERROR: GHDL is not available"; \
		exit 1; \
	}
	@test -x "$(PYTHON)" || { \
		echo "ERROR: $(PYTHON) does not exist. Run: make venv"; \
		exit 1; \
	}
	@$(GHDL) --version | head -n 4
	@$(PYTHON) --version

model: check-env
	$(PYTHON) simulation.py

$(GHDL_WORK):
	mkdir -p $(GHDL_WORK)

analyze: check-env $(GHDL_WORK)
	$(GHDL) -a $(GHDL_STD) --workdir=$(GHDL_WORK) $(SRCS)
	$(GHDL) -a $(GHDL_STD) --workdir=$(GHDL_WORK) $(TB_SRCS)

test-components: analyze
	cd $(BUILD_DIR) && \
		$(GHDL) -e $(GHDL_STD) --workdir=ghdl -Pghdl tb_relu
	cd $(BUILD_DIR) && \
		$(GHDL) -r $(GHDL_STD) --workdir=ghdl -Pghdl \
		tb_relu --assert-level=error

	cd $(BUILD_DIR) && \
		$(GHDL) -e $(GHDL_STD) --workdir=ghdl -Pghdl tb_sigmoid
	cd $(BUILD_DIR) && \
		$(GHDL) -r $(GHDL_STD) --workdir=ghdl -Pghdl \
		tb_sigmoid --assert-level=error

	cd $(BUILD_DIR) && \
		$(GHDL) -e $(GHDL_STD) --workdir=ghdl -Pghdl tb_argmax
	cd $(BUILD_DIR) && \
		$(GHDL) -r $(GHDL_STD) --workdir=ghdl -Pghdl \
		tb_argmax --assert-level=error

	cd $(BUILD_DIR) && \
		$(GHDL) -e $(GHDL_STD) --workdir=ghdl -Pghdl \
		tb_gradient_descent
	cd $(BUILD_DIR) && \
		$(GHDL) -r $(GHDL_STD) --workdir=ghdl -Pghdl \
		tb_gradient_descent --assert-level=error

test-mlp: analyze
	cd $(BUILD_DIR) && \
		$(GHDL) -e $(GHDL_STD) --workdir=ghdl -Pghdl tb_mlp
	cd $(BUILD_DIR) && \
		$(GHDL) -r $(GHDL_STD) --workdir=ghdl -Pghdl \
		tb_mlp \
		-gVECTOR_FILE="$(abspath $(VECTORS))" \
		--stop-time=100us \
		--assert-level=error

test:
	$(MAKE) test-components
	$(MAKE) test-mlp

demo: analyze
	cd $(BUILD_DIR) && \
		$(GHDL) -e $(GHDL_STD) --workdir=ghdl -Pghdl tb_mlp_demo
	cd $(BUILD_DIR) && \
		$(GHDL) -r $(GHDL_STD) --workdir=ghdl -Pghdl \
		tb_mlp_demo \
		--vcd=tb_mlp_demo.vcd \
		--stop-time=10us \
		--assert-level=error

clean-root-artifacts:
	rm -f $(ROOT_GHDL_ARTIFACTS)

verify-root-clean:
	@for file in $(ROOT_GHDL_ARTIFACTS); do \
		if [ -e "$$file" ]; then \
			echo "ERROR: GHDL artifact exists in repository root: $$file"; \
			exit 1; \
		fi; \
	done
	@echo "Repository root contains no GHDL build artifacts"

phase3:
	$(MAKE) clean-root-artifacts
	$(MAKE) model
	$(MAKE) test
	$(MAKE) demo
	$(MAKE) verify-root-clean

clean:
	rm -rf $(BUILD_DIR)
