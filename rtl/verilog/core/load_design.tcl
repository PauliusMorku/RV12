if {[get_mode]!="setup"} {
	set_mode setup
}
delete_design -both

read_verilog -golden  -pragma_ignore {}  -version sv2012 {../pkg/riscv_state1.10_pkg.sv ../pkg/biu_constants_pkg.sv ../pkg/riscv_du_pkg.sv ../pkg/riscv_opcodes_pkg.sv ../pkg/riscv_rv12_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {riscv_if.sv riscv_id.sv riscv_ex.sv ex/riscv_alu.sv ex/riscv_lsu.sv ex/riscv_bu.sv riscv_mem.sv riscv_wb.sv riscv_state1.10.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {riscv_rf.sv riscv_du.sv riscv_core.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {top.sv}

elaborate -golden
compile
set_reset_sequence rstn=0
set_mode mv
set_check_option -verbose
read_itl  {itl/commons.vli itl/constraints.vli itl/property.vli itl/core_functions.vli}
