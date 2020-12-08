if {[info exists launch_script_triggered] == 0} {

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
set comment "not allowing missaligned instructions, unfair constraints"

################################################################################################
# Generate report from all experiments in the result directory (1 - enable, 0 - disable)
################################################################################################
set generate_report 1

################################################################################################
# Copy experiment files before running checks (1 - enable, 0 - disable)
################################################################################################
set make_copy 1

################################################################################################
# ITL property files, similarly named TCL files will be sourced automatically
################################################################################################
set itl_files {
	RV12/rtl/verilog/core/itl/commons.vli
	RV12/rtl/verilog/core/itl/property.vli
	RV12/rtl/verilog/core/itl/constraints.vli
	RV12/rtl/verilog/core/itl/core_functions.vli
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


set config_file [info script]
source $ONESPIN_SCRIPT_DIR/run_checks_simple.tcl

} else {
	unset launch_script_triggered

	set_mode setup
	delete_design -both
	read_verilog -golden -pragma_ignore {} -version sv2012 $verilog_files_onespin
	elaborate -golden
	compile
	set_reset_sequence rstn=0
	set_mode mv
	set_check_option -verbose
	read_itl $itl_files_onespin

	#check -all [get_properties]
	#check base
	check step
	#check window_check
}