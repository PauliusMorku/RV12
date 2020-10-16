################################################################################################
# OneSpin script directory
################################################################################################
set ONESPIN_SCRIPT_DIR $::env(ONESPIN_SCRIPT_DIR)

################################################################################################
# Common root directory for all the files involved in the experiment
# NOTE: when using "make_copy 1" option all referenced files must originate from this directory
# (files can't be referenced using "../" operator)
################################################################################################
set COMMON_ROOT_DIR $::env(WORKSPACE_DIR)

################################################################################################
# Comment for the experiment (will appear in the OneSpin log files and the generated report)
################################################################################################
set comment "initial attempt to load RV12"

################################################################################################
# Generate report from all experiments in the result directory (1 - enable, 0 - disable)
################################################################################################
set generate_report 1

################################################################################################
# Arguments for the property check in OneSpin (can be used to configure engines, etc.)
################################################################################################
set check_args "-all"

################################################################################################
# Filter messages (1 - enable, 0 - disable)
################################################################################################
set filter_messages 1

################################################################################################
# Copy experiment files before running checks (1 - enable, 0 - disable)
################################################################################################
set make_copy 0

################################################################################################
# ITL property files, similarly named TCL files will be sourced automatically
################################################################################################
set itl_property_files {
	RV12/rtl/verilog/core/property.vli
	RV12/rtl/verilog/core/core_functions.vli
}

################################################################################################
# VHDL files
################################################################################################
set vhdl_files {
}

################################################################################################
# Verilog files
################################################################################################
set verilog_files {
	RV12/rtl/verilog/pkg/riscv_state1.10_pkg.sv
	RV12/rtl/verilog/pkg/biu_constants_pkg.sv
	RV12/rtl/verilog/pkg/riscv_du_pkg.sv
	RV12/rtl/verilog/pkg/riscv_opcodes_pkg.sv
	RV12/rtl/verilog/pkg/riscv_rv12_pkg.sv
	RV12/rtl/verilog/core/riscv_if.sv
	RV12/rtl/verilog/core/riscv_id.sv
	RV12/rtl/verilog/core/riscv_ex.sv
	RV12/rtl/verilog/core/ex/riscv_alu.sv
	RV12/rtl/verilog/core/ex/riscv_lsu.sv
	RV12/rtl/verilog/core/ex/riscv_bu.sv
	RV12/rtl/verilog/core/riscv_mem.sv
	RV12/rtl/verilog/core/riscv_wb.sv
	RV12/rtl/verilog/core/riscv_state1.10.sv
	RV12/rtl/verilog/core/riscv_rf.sv
	RV12/rtl/verilog/core/riscv_du.sv
	RV12/rtl/verilog/core/riscv_core.sv
	RV12/rtl/verilog/core/top.sv
}

################################################################################################
# Common ITL files
################################################################################################
set itl_common_files {
}

################################################################################################
# Common signals to be cut
################################################################################################
set cut_signals {
}

################################################################################################
# Read common variables and launch - do not modify
################################################################################################
set config_file [info script]
source $ONESPIN_SCRIPT_DIR/launcher.tcl
