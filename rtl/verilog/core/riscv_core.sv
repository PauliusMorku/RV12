/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    RISC-V                                                       //
//    CPU Core                                                     //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2014-2018 ROA Logic BV                //
//             www.roalogic.com                                    //
//                                                                 //
//     Unless specifically agreed in writing, this software is     //
//   licensed under the RoaLogic Non-Commercial License            //
//   version-1.0 (the "License"), a copy of which is included      //
//   with this file or may be found on the RoaLogic website        //
//   http://www.roalogic.com. You may not use the file except      //
//   in compliance with the License.                               //
//                                                                 //
//     THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY           //
//   EXPRESS OF IMPLIED WARRANTIES OF ANY KIND.                    //
//   See the License for permissions and limitations under the     //
//   License.                                                      //
//                                                                 //
/////////////////////////////////////////////////////////////////////

/*
  Changelog: 2017-12-15: Added MEM stage to improve memory access performance
*/

import riscv_du_pkg::*;
import riscv_state_pkg::*;
import riscv_opcodes_pkg::*;
import biu_constants_pkg::*;

module riscv_core #(
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
  output                           dbg_bp
);


  ////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [XLEN          -1:0] bu_nxt_pc,
                             st_nxt_pc,
                             if_pc,
                             id_pc,
                             ex_pc,
                             mem_pc,
                             wb_pc;

  logic [ILEN          -1:0] if_instr,
                             id_instr,
                             ex_instr,
                             mem_instr,
                             wb_instr;

  logic                      if_bubble,
                             id_bubble,
                             ex_bubble,
                             mem_bubble,
                             wb_bubble;

  logic                      bu_flush,
                             st_flush,
                             du_flush;

  logic                      id_stall,
                             ex_stall,
                             wb_stall,
                             du_stall,
                             du_stall_dly;

  //Branch Prediction
  logic [               1:0] if_bp_predict,
                             id_bp_predict;

//  logic [BP_GLOBAL_BITS-1:0] bu_bp_history;
//  logic                      bu_bp_btaken,
//                             bu_bp_update;


  //Exceptions
  logic [EXCEPTION_SIZE-1:0] if_exception,
                             id_exception,
                             ex_exception,
                             mem_exception,
                             wb_exception;

  //RF access
  logic [XLEN          -1:0] id_srcv2;
  logic [               4:0] rf_src1 [1],
                             rf_src2 [1],
                             rf_dst  [1];
  logic [XLEN          -1:0] rf_srcv1[1],
                             rf_srcv2[1],
                             rf_dstv [1];
  logic [               0:0] rf_we;           


  //ALU signals
  logic [XLEN          -1:0] id_opA,
                             id_opB,
                             ex_r,
                             ex_memadr,
                             mem_r,
                             mem_memadr;

  logic                      id_userf_opA,
                             id_userf_opB,
                             id_bypex_opA,
                             id_bypex_opB,
                             id_bypmem_opA,
                             id_bypmem_opB,
                             id_bypwb_opA,
                             id_bypwb_opB;

  //CPU state
  logic [               1:0] st_xlen;
  logic                      st_tvm,
                             st_tw,
                             st_tsr;
  logic [XLEN          -1:0] st_mcounteren,
                             st_scounteren;
  logic                      st_interrupt;
  logic [              11:0] ex_csr_reg;
  logic [XLEN          -1:0] ex_csr_wval,
                             st_csr_rval;
  logic                      ex_csr_we;

  //Write back
  logic [               4:0] wb_dst;
  logic [XLEN          -1:0] wb_r;
  logic [               0:0] wb_we;
  logic [XLEN          -1:0] wb_badaddr;

  //Debug
  logic                      du_we_rf,
                             du_we_frf,
                             du_we_csr,
                             du_we_pc;
  logic [DU_ADDR_SIZE  -1:0] du_addr;
  logic [XLEN          -1:0] du_dato,
                             du_dati_rf,
                             du_dati_frf,
                             du_dati_csr;
  logic [              31:0] du_ie,
                             du_exceptions;


  logic [2:0]  counter;

  always_ff @(posedge clk, negedge rstn)
  begin
    if (rstn == 1'b0)
    begin
		counter = 0;
	end
    else
    begin
        if (counter == 1)// && id_ready == 1'b1) 
        begin
            counter = 0;
        end
        else //if (counter != 3) 
        begin
            counter = counter + 1;
        end
    end
  end

  ////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * Instruction Fetch
   *
   * Calculate next Program Counter
   * Fetch next instruction
   */
  riscv_if #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ),
    .PARCEL_SIZE    ( PARCEL_SIZE    ),
    .HAS_BPU        ( HAS_BPU        ) )
  if_unit (
    .rstn                 ( rstn                  ), // in  //Reset
    .clk                  ( clk                   ), // in  //Clock
    .id_stall             ( id_stall              ), // in 

    .if_stall_nxt_pc      ( if_stall_nxt_pc       ), // in 
    .if_parcel            ( if_parcel             ), // in
    .if_parcel_pc         ( if_parcel_pc          ), // in
    .if_parcel_valid      ( if_parcel_valid       ), // in
    .if_parcel_misaligned ( if_parcel_misaligned  ), // in 
    .if_parcel_page_fault ( if_parcel_page_fault  ), // in

    .if_instr             ( if_instr              ), // out //Instruction out
    .if_bubble            ( if_bubble             ), // out //Insert bubble in the pipe (NOP instruction)
    .if_exception         ( if_exception          ), // out //Exceptions


    .bp_bp_predict        ( 2'b00                 ), // in  //Branch Prediction bits
    .if_bp_predict        ( if_bp_predict         ), // out //push down the pipe

    .bu_flush             ( bu_flush              ), // in  //flush pipe & load new program counter
    .st_flush             ( st_flush              ), // in 
    .du_flush             ( du_flush              ), // in  //flush pipe after debug exit

    .bu_nxt_pc            ( bu_nxt_pc             ), // in  //Branch Unit Next Program Counter
    .st_nxt_pc            ( st_nxt_pc             ), // in  //State Next Program Counter

    .if_nxt_pc            ( if_nxt_pc             ), // out //next Program Counter
    .if_stall             ( if_stall              ), // out //stall instruction fetch BIU (cache/bus-interface)
    .if_flush             ( if_flush              ), // out //flush instruction fetch BIU (cache/bus-interface)
    .if_pc                ( if_pc                 )  // out //Program Counter
  );

  /*
   * Instruction Decoder
   *
   * Data from RF/ROB is available here
   */
  riscv_id #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ),
    .HAS_USER       ( HAS_USER       ),
    .HAS_SUPER      ( HAS_SUPER      ),
    .HAS_HYPER      ( HAS_HYPER      ),
    .HAS_RVA        ( HAS_RVA        ),
    .HAS_RVM        ( HAS_RVM        ),
    .MULT_LATENCY   ( MULT_LATENCY   ) )
  id_unit (
    .rstn           ( rstn          ), // in  
    .clk            ( clk           ), // in  

    .id_stall       ( id_stall      ), // out 
    .ex_stall       ( ex_stall      ), // in  
    .du_stall       ( du_stall      ), // in  

    .bu_flush       ( bu_flush      ), // in  
    .st_flush       ( st_flush      ), // in  
    .du_flush       ( du_flush      ), // in  

    .bu_nxt_pc      ( bu_nxt_pc     ), // in  
    .st_nxt_pc      ( st_nxt_pc     ), // in  

    //Program counter
    .if_pc          ( if_pc         ), // in  
    .id_pc          ( id_pc         ), // out 
    .if_bp_predict  ( if_bp_predict ), // in  
    .id_bp_predict  ( id_bp_predict ), // out 

    //Instruction
    .if_instr       ( if_instr      ), // in  
    .if_bubble      ( if_bubble     ), // in  
    .id_instr       ( id_instr      ), // out 
    .id_bubble      ( id_bubble     ), // out 
    .ex_instr       ( ex_instr      ), // in  
    .ex_bubble      ( ex_bubble     ), // in  
    .mem_instr      ( mem_instr     ), // in  
    .mem_bubble     ( mem_bubble    ), // in  
    .wb_instr       ( wb_instr      ), // in  
    .wb_bubble      ( wb_bubble     ), // in  

    //Exceptions
    .if_exception   ( if_exception  ), // in  
    .ex_exception   ( ex_exception  ), // in  
    .mem_exception  ( mem_exception ), // in  
    .wb_exception   ( wb_exception  ), // in  
    .id_exception   ( id_exception  ), // out 

    //From State
    .st_prv         ( st_prv        ), // in  
    .st_xlen        ( st_xlen       ), // in  
    .st_tvm         ( st_tvm        ), // in  
    .st_tw          ( st_tw         ), // in  
    .st_tsr         ( st_tsr        ), // in  
    .st_mcounteren  ( st_mcounteren ), // in  
    .st_scounteren  ( st_scounteren ), // in  

    //To RF
    .id_src1        ( rf_src1[0]    ), // out 
    .id_src2        ( rf_src2[0]    ), // out 

    //To execution units
    .id_opA         ( id_opA        ), // out 
    .id_opB         ( id_opB        ), // out 

    .id_userf_opA   ( id_userf_opA  ), // out 
    .id_userf_opB   ( id_userf_opB  ), // out 
    .id_bypex_opA   ( id_bypex_opA  ), // out 
    .id_bypex_opB   ( id_bypex_opB  ), // out 
    .id_bypmem_opA  ( id_bypmem_opA ), // out 
    .id_bypmem_opB  ( id_bypmem_opB ), // out 
    .id_bypwb_opA   ( id_bypwb_opA  ), // out 
    .id_bypwb_opB   ( id_bypwb_opB  ), // out 

    //from MEM/WB
    .mem_r          ( mem_r         ), // in  
    .wb_r           ( wb_r          )  // in  
  );


  /*
   * Execution units
   */
  riscv_ex #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ),
    .HAS_RVC        ( HAS_RVC        ),
    .HAS_RVA        ( HAS_RVA        ),
    .HAS_RVM        ( HAS_RVM        ),
    .MULT_LATENCY   ( MULT_LATENCY   ) )
  ex_units (
    .rstn             ( rstn            ), // in 
    .clk              ( clk             ), // in 

    .wb_stall         ( wb_stall        ), // in 
    .ex_stall         ( ex_stall        ), // out

    //Program counter
    .id_pc            ( id_pc           ), // in 
    .ex_pc            ( ex_pc           ), // out
    .bu_nxt_pc        ( bu_nxt_pc       ), // out
    .bu_flush         ( bu_flush        ), // out
    .bu_cacheflush    ( bu_cacheflush   ), // out
    .id_bp_predict    ( id_bp_predict   ), // in 
    //.bu_bp_predict    ( bu_bp_predict   ), // out
    //.bu_bp_history    ( bu_bp_history   ), // out
    //.bu_bp_btaken     ( bu_bp_btaken    ), // out
    //.bu_bp_update     ( bu_bp_update    ), // out

    //Instruction
    .id_bubble        ( id_bubble       ), // in 
    .id_instr         ( id_instr        ), // in 
    .ex_bubble        ( ex_bubble       ), // out
    .ex_instr         ( ex_instr        ), // out

    .id_exception     ( id_exception    ), // in 
    .mem_exception    ( mem_exception   ), // in 
    .wb_exception     ( wb_exception    ), // in 
    .ex_exception     ( ex_exception    ), // out

    //from ID
    .id_userf_opA     ( id_userf_opA    ), // in 
    .id_userf_opB     ( id_userf_opB    ), // in 
    .id_bypex_opA     ( id_bypex_opA    ), // in 
    .id_bypex_opB     ( id_bypex_opB    ), // in 
    .id_bypmem_opA    ( id_bypmem_opA   ), // in 
    .id_bypmem_opB    ( id_bypmem_opB   ), // in 
    .id_bypwb_opA     ( id_bypwb_opA    ), // in 
    .id_bypwb_opB     ( id_bypwb_opB    ), // in 
    .id_opA           ( id_opA          ), // in 
    .id_opB           ( id_opB          ), // in 

    //from RF
    .rf_srcv1         ( rf_srcv1[0]     ), // in 
    .rf_srcv2         ( rf_srcv2[0]     ), // in 

    //to MEM
    .ex_r             ( ex_r            ), // out

    //Bypasses
    .mem_r            ( mem_r           ), // in 
    .wb_r             ( wb_r            ), // in 

    //To State
    .ex_csr_reg       ( ex_csr_reg      ), // out
    .ex_csr_wval      ( ex_csr_wval     ), // out
    .ex_csr_we        ( ex_csr_we       ), // out

    //From State
    .st_prv           ( st_prv          ), // in 
    .st_xlen          ( st_xlen         ), // in 
    .st_flush         ( st_flush        ), // in 
    .st_csr_rval      ( st_csr_rval     ), // in 

    //To DCACHE/Memory
    .dmem_adr         ( dmem_adr        ), // out
    .dmem_d           ( dmem_d          ), // out
    .dmem_req         ( dmem_req        ), // out
    .dmem_we          ( dmem_we         ), // out
    .dmem_size        ( dmem_size       ), // out
    .dmem_ack         ( dmem_ack        ), // in 
    .dmem_q           ( dmem_q          ), // in 
    .dmem_misaligned  ( dmem_misaligned ), // in 
    .dmem_page_fault  ( dmem_page_fault ), // in 

    //Debug Unit
    .du_stall         ( du_stall        ), // in 
    .du_stall_dly     ( du_stall_dly    ), // in 
    .du_flush         ( du_flush        ), // in 
    .du_we_pc         ( du_we_pc        ), // in 
    .du_dato          ( du_dato         ), // in 
    .du_ie            ( du_ie           )  // in 
  );


  /*
   * Memory access
   */
  riscv_mem #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ) )
  mem_unit   (
    .rstn           ( rstn          ), // in 
    .clk            ( clk           ), // in 

    .wb_stall       ( wb_stall      ), // in 

    //Program counter
    .ex_pc          ( ex_pc         ), // in 
    .mem_pc         ( mem_pc        ), // out 

    //Instruction
    .ex_bubble      ( ex_bubble     ), // in 
    .ex_instr       ( ex_instr      ), // in 
    .mem_bubble     ( mem_bubble    ), // out 
    .mem_instr      ( mem_instr     ), // out 

    .ex_exception   ( ex_exception  ), // in 
    .wb_exception   ( wb_exception  ), // in 
    .mem_exception  ( mem_exception ), // out 
 
    //From EX
    .ex_r           ( ex_r          ), // in 
    .dmem_adr       ( dmem_adr      ), // in 

    //To WB
    .mem_r          ( mem_r         ), // out 
    .mem_memadr     ( mem_memadr    )  // out 
  );


  /*
   * Memory acknowledge + Write Back unit
   */
  riscv_wb #(
    .XLEN           ( XLEN           ),
    .PC_INIT        ( PC_INIT        ) )
  wb_unit   (
    .rst_ni            ( rstn            ), // in 
    .clk_i             ( clk             ), // in 
    .mem_pc_i          ( mem_pc          ), // in 
    .mem_instr_i       ( mem_instr       ), // in 
    .mem_bubble_i      ( mem_bubble      ), // in 
    .mem_r_i           ( mem_r           ), // in 
    .mem_exception_i   ( mem_exception   ), // in 
    .mem_memadr_i      ( mem_memadr      ), // in 
    .wb_pc_o           ( wb_pc           ), // out 
    .wb_stall_o        ( wb_stall        ), // out 
    .wb_instr_o        ( wb_instr        ), // out 
    .wb_bubble_o       ( wb_bubble       ), // out 
    .wb_exception_o    ( wb_exception    ), // out 
    .wb_badaddr_o      ( wb_badaddr      ), // out 
    .dmem_ack_i        ( dmem_ack        ), // in 
    .dmem_err_i        ( dmem_err        ), // in 
    .dmem_q_i          ( dmem_q          ), // in 
    .dmem_misaligned_i ( dmem_misaligned ), // in 
    .dmem_page_fault_i ( dmem_page_fault ), // in 
    .wb_dst_o          ( wb_dst          ), // out 
    .wb_r_o            ( wb_r            ), // out 
    .wb_we_o           ( wb_we           )  // out 
  );

  assign rf_dst [0] = wb_dst;
  assign rf_dstv[0] = wb_r;
  assign rf_we  [0] = wb_we;


  /*
   * Thread state
   */
  riscv_state1_10 #(
    .XLEN                  ( XLEN                  ),
    .PC_INIT               ( PC_INIT               ),
    .HAS_FPU               ( HAS_FPU               ),
    .HAS_MMU               ( HAS_MMU               ),
    .HAS_USER              ( HAS_USER              ),
    .HAS_SUPER             ( HAS_SUPER             ),
    .HAS_HYPER             ( HAS_HYPER             ),

    .MNMIVEC_DEFAULT       ( MNMIVEC_DEFAULT       ),
    .MTVEC_DEFAULT         ( MTVEC_DEFAULT         ),
    .HTVEC_DEFAULT         ( HTVEC_DEFAULT         ),
    .STVEC_DEFAULT         ( STVEC_DEFAULT         ),
    .UTVEC_DEFAULT         ( UTVEC_DEFAULT         ),

    .JEDEC_BANK            ( JEDEC_BANK            ),
    .JEDEC_MANUFACTURER_ID ( JEDEC_MANUFACTURER_ID ),

    .PMP_CNT               ( PMP_CNT               ),
    .HARTID                ( HARTID                ) )
  cpu_state (
    .rstn           ( rstn          ), // in  
    .clk            ( clk           ), // in  

    .id_pc          ( id_pc         ), // in  
    .id_bubble      ( id_bubble     ), // in  
    .id_instr       ( id_instr      ), // in  
    .id_stall       ( id_stall      ), // in  

    .bu_flush       ( bu_flush      ), // in  
    .bu_nxt_pc      ( bu_nxt_pc     ), // in  
    .st_flush       ( st_flush      ), // out  
    .st_nxt_pc      ( st_nxt_pc     ), // out  

    .wb_pc          ( wb_pc         ), // in  
    .wb_bubble      ( wb_bubble     ), // in  
    .wb_instr       ( wb_instr      ), // in  
    .wb_exception   ( wb_exception  ), // in  
    .wb_badaddr     ( wb_badaddr    ), // in  

    .st_interrupt   ( st_interrupt  ), // out  
    .st_prv         ( st_prv        ), // out //Privilege level
    .st_xlen        ( st_xlen       ), // out //Active Architecture
    .st_tvm         ( st_tvm        ), // out //trap on satp access or SFENCE.VMA
    .st_tw          ( st_tw         ), // out //trap on WFI (after time >=0)
    .st_tsr         ( st_tsr        ), // out //trap SRET
    .st_mcounteren  ( st_mcounteren ), // out  
    .st_scounteren  ( st_scounteren ), // out  
    .st_pmpcfg      ( st_pmpcfg     ), // out  
    .st_pmpaddr     ( st_pmpaddr    ), // out  


    //interrupts (3=M-mode, 0=U-mode)
    .ext_int        ( ext_int       ), // in  //external interrupt (per privilege mode; determined by PIC)
    .ext_tint       ( ext_tint      ), // in  //machine timer interrupt
    .ext_sint       ( ext_sint      ), // in  //machine software interrupt (for ipi)
    .ext_nmi        ( ext_nmi       ), // in  //non-maskable interrupt

    //CSR interface
    .ex_csr_reg     ( ex_csr_reg    ), // in  
    .ex_csr_we      ( ex_csr_we     ), // in  
    .ex_csr_wval    ( ex_csr_wval   ), // in  
    .st_csr_rval    ( st_csr_rval   ), // out  

    //Debug interface
    .du_stall       ( du_stall      ), // in  
    .du_flush       ( du_flush      ), // in  
    .du_we_csr      ( du_we_csr     ), // in  
    .du_dato        ( du_dato       ), // in  //output from debug unit
    .du_addr        ( du_addr       ), // in  
    .du_ie          ( du_ie         ), // in  
    .du_exceptions  ( du_exceptions )  // out  
  );


  /*
   *  Integer Register File
   */
  riscv_rf #(
    .XLEN    ( XLEN ),
    .RDPORTS ( 1    ),
    .WRPORTS ( 1    ) )
  int_rf (
    .rstn       ( rstn        ), // in  
    .clk        ( clk         ), // in 

    //Register File read
    .rf_src1    ( rf_src1     ), // in 
    .rf_src2    ( rf_src2     ), // in 
    .rf_srcv1   ( rf_srcv1    ), // out 
    .rf_srcv2   ( rf_srcv2    ), // out 

    //Register File write
    .rf_dst     ( rf_dst      ), // in 
    .rf_dstv    ( rf_dstv     ), // in 
    .rf_we      ( rf_we       ), // in 

    //Debug Interface
    .du_stall   ( du_stall    ), // in 
    .du_we_rf   ( du_we_rf    ), // in 
    .du_dato    ( du_dato     ), // in //output from debug unit
    .du_dati_rf ( du_dati_rf  ), // out 
    .du_addr    ( du_addr     )  // in 
    );


  /*
   * Debug Unit
   */
  riscv_du #(
    .XLEN           ( XLEN           ),
    .BREAKPOINTS    ( BREAKPOINTS    ) )
  du_unit (
    .rstn           ( rstn          ), // in
    .clk            ( clk           ), // in

    //Debug Port interface
    .dbg_stall      ( dbg_stall     ), // in
    .dbg_strb       ( dbg_strb      ), // in
    .dbg_we         ( dbg_we        ), // in
    .dbg_addr       ( dbg_addr      ), // in
    .dbg_dati       ( dbg_dati      ), // in
    .dbg_dato       ( dbg_dato      ), // out
    .dbg_ack        ( dbg_ack       ), // out
    .dbg_bp         ( dbg_bp        ), // out
  
    //CPU signals
    .du_stall       ( du_stall      ), // out
    .du_stall_dly   ( du_stall_dly  ), // out
    .du_flush       ( du_flush      ), // out
    .du_we_rf       ( du_we_rf      ), // out
    .du_we_frf      ( du_we_frf     ), // out
    .du_we_csr      ( du_we_csr     ), // out
    .du_we_pc       ( du_we_pc      ), // out
    .du_addr        ( du_addr       ), // out
    .du_dato        ( du_dato       ), // out
    .du_ie          ( du_ie         ), // out
    .du_dati_rf     ( du_dati_rf    ), // in
    .du_dati_frf    ( du_dati_frf   ), // in
    .st_csr_rval    ( st_csr_rval   ), // in
    .if_pc          ( if_pc         ), // in
    .id_pc          ( id_pc         ), // in
    .ex_pc          ( ex_pc         ), // in
    .bu_nxt_pc      ( bu_nxt_pc     ), // in
    .bu_flush       ( bu_flush      ), // in
    .st_flush       ( st_flush      ), // in
    
    .if_instr       ( if_instr      ), // in
    .mem_instr      ( mem_instr     ), // in
    .if_bubble      ( if_bubble     ), // in
    .mem_bubble     ( mem_bubble    ), // in
    .mem_exception  ( mem_exception ), // in
    .mem_memadr     ( mem_memadr    ), // in
    .dmem_ack       ( dmem_ack      ), // in
    .ex_stall       ( ex_stall      ), // in
    
    //From state
    .du_exceptions  ( du_exceptions )  // in
  );

endmodule

