import riscv_state_pkg::*;
import biu_constants_pkg::*;

module top #(
  parameter            XLEN                  = 32,
  parameter [XLEN-1:0] PC_INIT               = 'h200,
  parameter            HAS_USER              = 0,
  parameter            HAS_SUPER             = 0,
  parameter            HAS_HYPER             = 0,
  parameter            HAS_BPU               = 0,
  parameter            HAS_FPU               = 0,
  parameter            HAS_MMU               = 0,
  parameter            HAS_RVA               = 0,
  parameter            HAS_RVM               = 0,
  parameter            HAS_RVC               = 0,
  parameter            IS_RV32E              = 0,
  parameter            MULT_LATENCY          = 0,
  parameter            BREAKPOINTS           = 0,
  parameter            PMP_CNT               = 0,
  parameter            BP_GLOBAL_BITS        = 0,
  parameter            BP_LOCAL_BITS         = 0,
  parameter            TECHNOLOGY            = "GENERIC",
  parameter            MNMIVEC_DEFAULT       = PC_INIT -'h004,
  parameter            MTVEC_DEFAULT         = PC_INIT -'h040,
  parameter            HTVEC_DEFAULT         = PC_INIT -'h080,
  parameter            STVEC_DEFAULT         = PC_INIT -'h0C0,
  parameter            UTVEC_DEFAULT         = PC_INIT -'h100,
  parameter            JEDEC_BANK            = 10,
  parameter            JEDEC_MANUFACTURER_ID = 'h6e,
  parameter            HARTID                = 0,
  parameter            PARCEL_SIZE           = 32
)
(
  input                             rstn,   //Reset
  input                             clk,    //Clock


  //Instruction Memory Access bus
  input                             if_stall_nxt_pc,
  output       [XLEN          -1:0] if_nxt_pc,
  output                            if_stall,
                                    if_flush,
  input        [PARCEL_SIZE   -1:0] if_parcel,
  input        [XLEN          -1:0] if_parcel_pc,
  input        [PARCEL_SIZE/16-1:0] if_parcel_valid,
  input                             if_parcel_misaligned,
  input                             if_parcel_page_fault,

  //Data Memory Access bus
  output       [XLEN         -1:0] dmem_adr,
                                   dmem_d,
  input        [XLEN         -1:0] dmem_q,
  output                           dmem_we,
  output biu_size_t                dmem_size,
  output                           dmem_req,
  input                            dmem_ack,
                                   dmem_err,
                                   dmem_misaligned,
                                   dmem_page_fault,

  //cpu state
  output       [              1:0] st_prv,
  output pmpcfg_t [15:0]           st_pmpcfg,
  output [15:0][XLEN         -1:0] st_pmpaddr,

  output                           bu_cacheflush,

  //Interrupts
  input                            ext_nmi,
                                   ext_tint,
                                   ext_sint,
  input        [              3:0] ext_int,


  //Debug Interface
  input                            dbg_stall,
  input                            dbg_strb,
  input                            dbg_we,
  input        [DBG_ADDR_SIZE-1:0] dbg_addr,
  input        [XLEN         -1:0] dbg_dati,
  output       [XLEN         -1:0] dbg_dato,
  output                           dbg_ack,
  output                           dbg_bp,

  // Verification related signals
  input                            IF_tcnt_inc,
  input                            ID_tcnt_inc,
  input                            EX_tcnt_inc,
  input                            ME_tcnt_inc,
  input                            WB_tcnt_inc,
  input                            t1_flush,
  input                            t2_flush,
  input                            t3_flush
);


  logic [5:0] IF_tcnt;
  logic [5:0] ID_tcnt;
  logic [5:0] EX_tcnt;
  logic [5:0] ME_tcnt;
  logic [5:0] WB_tcnt;

  typedef enum int {INSTR_UNKNOWN, INSTR_ADD, INSTR_ADDI, INSTR_AND, INSTR_ANDI, INSTR_AUIPC, INSTR_BEQ, INSTR_BGE, INSTR_BGEU, INSTR_BLT, INSTR_BLTU, INSTR_BNE, INSTR_CSRRC, INSTR_CSRRCI, INSTR_CSRRS, INSTR_CSRRSI, INSTR_CSRRW, INSTR_CSRRWI, INSTR_EBREAK, INSTR_ECALL, INSTR_FENCE, INSTR_FENCEI, INSTR_JAL, INSTR_JALR, INSTR_LB, INSTR_LBU, INSTR_LH, INSTR_LHU, INSTR_LUI, INSTR_LW, INSTR_MRET, INSTR_OR, INSTR_ORI, INSTR_SB, INSTR_SFENCEVMA, INSTR_SH, INSTR_SLL, INSTR_SLLI, INSTR_SLT, INSTR_SLTI, INSTR_SLTIU, INSTR_SLTU, INSTR_SRA, INSTR_SRAI, INSTR_SRET, INSTR_SRL, INSTR_SRLI, INSTR_SUB, INSTR_SW, INSTR_URET, INSTR_WFI, INSTR_XOR, INSTR_XORI} Instr_t;


  always_ff @(posedge clk)
  begin
    if (IF_tcnt_inc)
    begin
      IF_tcnt <= $size(IF_tcnt)'($size(IF_tcnt+1)'(IF_tcnt)+1);
    end
    if (ID_tcnt_inc)
    begin
      ID_tcnt <= IF_tcnt;
    end
    if (EX_tcnt_inc)
    begin
      EX_tcnt <= ID_tcnt;
    end
    if (ME_tcnt_inc)
    begin
      ME_tcnt <= EX_tcnt;
    end
    if (WB_tcnt_inc)
    begin
      WB_tcnt <= ME_tcnt;
    end
  end


  riscv_core #(
    .XLEN                  ( XLEN                  ),
    .PC_INIT               ( PC_INIT               ),
    .HAS_USER              ( HAS_SUPER             ),
    .HAS_SUPER             ( HAS_SUPER             ),
    .HAS_HYPER             ( HAS_HYPER             ),
    .HAS_BPU               ( HAS_BPU               ),
    .HAS_FPU               ( HAS_FPU               ),
    .HAS_MMU               ( HAS_MMU               ),
    .HAS_RVA               ( HAS_RVA               ),
    .HAS_RVM               ( HAS_RVM               ),
    .HAS_RVC               ( HAS_RVC               ),
    .IS_RV32E              ( IS_RV32E              ),
    .MULT_LATENCY          ( MULT_LATENCY          ),
    .BREAKPOINTS           ( BREAKPOINTS           ),
    .PMP_CNT               ( PMP_CNT               ),
    .BP_GLOBAL_BITS        ( BP_GLOBAL_BITS        ),
    .BP_LOCAL_BITS         ( BP_LOCAL_BITS         ),
    .TECHNOLOGY            ( TECHNOLOGY            ),
    .MNMIVEC_DEFAULT       ( MNMIVEC_DEFAULT       ),
    .MTVEC_DEFAULT         ( MTVEC_DEFAULT         ),
    .HTVEC_DEFAULT         ( HTVEC_DEFAULT         ),
    .STVEC_DEFAULT         ( STVEC_DEFAULT         ),
    .UTVEC_DEFAULT         ( UTVEC_DEFAULT         ),
    .JEDEC_BANK            ( JEDEC_BANK            ),
    .JEDEC_MANUFACTURER_ID ( JEDEC_MANUFACTURER_ID ),
    .HARTID                ( HARTID                ),
    .PARCEL_SIZE           ( PARCEL_SIZE           ))
  c (
    .*
  );

endmodule

