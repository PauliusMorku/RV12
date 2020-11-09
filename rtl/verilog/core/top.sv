import riscv_state_pkg::*;
import biu_constants_pkg::*;

typedef enum int {UNKNOWN_INSTR, ADD_INSTR, ADDI_INSTR, AND_INSTR, ANDI_INSTR, AUIPC_INSTR, BEQ_INSTR, BGE_INSTR, BGEU_INSTR, BLT_INSTR, BLTU_INSTR, BNE_INSTR, CSRRC_INSTR, CSRRCI_INSTR, CSRRS_INSTR, CSRRSI_INSTR, CSRRW_INSTR, CSRRWI_INSTR, EBREAK_INSTR, ECALL_INSTR, FENCE_INSTR, FENCEI_INSTR, JAL_INSTR, JALR_INSTR, LB_INSTR, LBU_INSTR, LH_INSTR, LHU_INSTR, LUI_INSTR, LW_INSTR, MRET_INSTR, OR_INSTR, ORI_INSTR, SB_INSTR, SFENCEVMA_INSTR, SH_INSTR, SLL_INSTR, SLLI_INSTR, SLT_INSTR, SLTI_INSTR, SLTIU_INSTR, SLTU_INSTR, SRA_INSTR, SRAI_INSTR, SRET_INSTR, SRL_INSTR, SRLI_INSTR, SUB_INSTR, SW_INSTR, URET_INSTR, WFI_INSTR, XOR_INSTR, XORI_INSTR} Instr_t;

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
  input                            IF_trem,
  input                            ID_trem,
  input                            EX_trem,
  input                            ME_trem,
  input                            WB_trem,

  input                            IF_wcnt_inc,
  input                            ID_wcnt_inc,
  input                            EX_wcnt_inc,
  input                            ME_wcnt_inc,
  input                            WB_wcnt_inc,

  input                            tl_IF_tx_wait,
  input                            tl_ID_rx_wait,
  input                            tl_ID_tx_wait,
  input                            tl_EX_rx_wait,
  input                            tl_EX_tx_wait,
  input                            tl_ME_rx_wait,
  input                            tl_ME_tx_wait,
  input                            tl_WB_rx_wait,
  input                            tl_WB_tx_wait,

  input                            t1_IF_tx_wait,
  input                            t1_ID_rx_wait,
  input                            t1_ID_tx_wait,
  input                            t1_EX_rx_wait,
  input                            t1_EX_tx_wait,
  input                            t1_ME_rx_wait,
  input                            t1_ME_tx_wait,
  input                            t1_WB_rx_wait,
  input                            t1_WB_tx_wait,

  input                            t2_IF_tx_wait,
  input                            t2_ID_rx_wait,
  input                            t2_ID_tx_wait,
  input                            t2_EX_rx_wait,
  input                            t2_EX_tx_wait,
  input                            t2_ME_rx_wait,
  input                            t2_ME_tx_wait,
  input                            t2_WB_rx_wait,
  input                            t2_WB_tx_wait,

  input                            t3_IF_tx_wait,
  input                            t3_ID_rx_wait,
  input                            t3_ID_tx_wait,
  input                            t3_EX_rx_wait,
  input                            t3_EX_tx_wait,
  input                            t3_ME_rx_wait,
  input                            t3_ME_tx_wait,
  input                            t3_WB_rx_wait,
  input                            t3_WB_tx_wait,

  // For debugging
  input Instr_t IF_instr_enum,
  input Instr_t ID_instr_enum,
  input Instr_t EX_instr_enum,
  input Instr_t ME_instr_enum,
  input Instr_t WB_instr_enum
);

  logic [5:0] IF_wcnt;
  logic [5:0] ID_wcnt;
  logic [5:0] EX_wcnt;
  logic [5:0] ME_wcnt;
  logic [5:0] WB_wcnt;

  logic [5:0] IF_tcnt;
  logic [5:0] ID_tcnt;
  logic [5:0] EX_tcnt;
  logic [5:0] ME_tcnt;
  logic [5:0] WB_tcnt;

  logic IF_tcnt_gate;
  logic ID_tcnt_gate;
  logic EX_tcnt_gate;
  logic ME_tcnt_gate;
  logic WB_tcnt_gate;

  always_ff @(posedge clk)
  begin
    // Note: **_tcnt_gate values can be overwritten by the lower section
    if (IF_trem)
      IF_tcnt_gate <= 0;
    if (ID_trem)
      ID_tcnt_gate <= 0;
    if (EX_trem)
      EX_tcnt_gate <= 0;
    if (ME_trem)
      ME_tcnt_gate <= 0;
    if (WB_trem)
      WB_tcnt_gate <= 0;

    if (IF_wcnt_inc)
    begin
      IF_wcnt <= $size(IF_wcnt)'($size(IF_wcnt+1)'(IF_wcnt)+1);
      IF_tcnt_gate <= 1;
    end
    if (ID_wcnt_inc)
    begin
      ID_wcnt <= IF_wcnt;
      ID_tcnt_gate <= 1;
    end
    if (EX_wcnt_inc)
    begin
      EX_wcnt <= ID_wcnt;
      EX_tcnt_gate <= 1;
    end
    if (ME_wcnt_inc)
    begin
      ME_wcnt <= EX_wcnt;
      ME_tcnt_gate <= 1;
    end
    if (WB_wcnt_inc)
    begin
      WB_wcnt <= ME_wcnt;
      WB_tcnt_gate <= 1;
    end
  end

assign IF_tcnt = IF_tcnt_gate ? IF_wcnt : 0;
assign ID_tcnt = ID_tcnt_gate ? ID_wcnt : 0;
assign EX_tcnt = EX_tcnt_gate ? EX_wcnt : 0;
assign ME_tcnt = ME_tcnt_gate ? ME_wcnt : 0;
assign WB_tcnt = WB_tcnt_gate ? WB_wcnt : 0;


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

