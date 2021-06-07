#####################################################################
##   ,------.                    ,--.                ,--.          ##
##   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    ##
##   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    ##
##   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    ##
##   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    ##
##                                             `---'               ##
##   Modelsim/Questasim Makefile                                   ##
##                                                                 ##
#####################################################################
##                                                                 ##
##             Copyright (C) 2014-2017 ROA Logic BV                ##
##             www.roalogic.com                                    ##
##                                                                 ##
##   This source file may be used and distributed without          ##
##   restriction provided that this copyright statement is not     ##
##   removed from the file and that any derivative work contains   ##
##   the original copyright notice and the associated disclaimer.  ##
##                                                                 ##
##      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        ##
##   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     ##
##   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     ##
##   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     ##
##   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  ##
##   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  ##
##   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  ##
##   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      ##
##   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     ##
##   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  ##
##   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          ##
##   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  ##
##                                                                 ##
#####################################################################


ROOT_DIR=../../../..

-include $(ROOT_DIR)/sim/ahb3lite/regression/bin/Makefile.include

TST_SRC_DIR=$(ROOT_DIR)/bench/tests/regression
TOP=$(TB_TOP)
LOG = log/$(TOP).log



SIM_OPTS= -debugdb +notimingchecks +acc
INIT_FILE="$(TST_SRC_DIR)/rv32ui-p-jal.hex"
DCACHE_SIZE=0
ICACHE_SIZE=0
MEM_LATENCY=0
WRITEBUFFER_SIZE=0
XLEN=32
MULT_LATENCY=0
HAS_U=0
HAS_S=0
HAS_H=0
HAS_RVA=0
HAS_RVC=0
HAS_RVM=0

all: sim

##########################################################################
#
# OVL
#
##########################################################################
ifeq ($(OVL_ASSERT),ON)
    INCDIRS+=$(STD_OVL_DIR)
    DEFINES+=OVL_ASSERT_ON
    LIBDIRS+=$(STD_OVL_DIR)
    LIBEXT +=.vlib

    ifeq ($(OVL_INIT_MSG),ON)
        DEFINES:=OVL_INIT_MSG
    endif
endif

#################################################################
# Make Targets
#################################################################

.PHONY: sim simw clean

sim: vlog
	@echo "--- Running sim"
	vsim $(SIM_OPTS) \
		-l $(LOG) $(TOP) \
		-do "run -all" \
		-gDCACHE_SIZE=$(DCACHE_SIZE) \
		-gICACHE_SIZE=$(ICACHE_SIZE) \
		-gMEM_LATENCY=$(MEM_LATENCY) \
		-gWRITEBUFFER_SIZE=$(WRITEBUFFER_SIZE) \
		-gXLEN=$(XLEN) \
		-gMULT_LATENCY=$(MULT_LATENCY) \
		-gHAS_U=$(HAS_U) \
		-gHAS_S=$(HAS_S) \
		-gHAS_H=$(HAS_H) \
		-gHAS_RVA=$(HAS_RVA) \
		-gHAS_RVC=$(HAS_RVC) \
		-gHAS_RVM=$(HAS_RVM) \
		-gTECHNOLOGY=$(TECHNOLOGY) \
		-gINIT_FILE=$(INIT_FILE)

simw: vlog
	@echo "--- Running sim"
	vsim $(SIM_OPTS) \
		-l $(LOG) $(TOP) +access +r \
		-do "log -mem -rec /$(TOP)/*; run -all"	\
		-gDCACHE_SIZE=$(DCACHE_SIZE) \
		-gICACHE_SIZE=$(ICACHE_SIZE) \
		-gMEM_LATENCY=$(MEM_LATENCY) \
		-gWRITEBUFFER_SIZE=$(WRITEBUFFER_SIZE) \
		-gXLEN=$(XLEN) \
		-gMULT_LATENCY=$(MULT_LATENCY) \
		-gHAS_U=$(HAS_U) \
		-gHAS_S=$(HAS_S) \
		-gHAS_H=$(HAS_H) \
		-gHAS_RVA=$(HAS_RVA) \
		-gHAS_RVC=$(HAS_RVC) \
		-gHAS_RVM=$(HAS_RVM) \
		-gTECHNOLOGY=$(TECHNOLOGY) \
		-gINIT_FILE=$(INIT_FILE)
	
clean:
	@rm -rf work log


#################################################################
## VHDL
#################################################################


#################################################################
## Verilog
#################################################################
.PHONY: vlog

vlog: work
	@echo "--- Running vlog"
	@vlog -work work $(abspath $(RTL_VLOG) $(TB_VLOG)) -sv \
	$(foreach d,$(DEFINES),+define+$d) \
	$(foreach d,$(abspath $(INCDIRS)),+incdir+$d) \
	$(foreach l,$(wildcard $(LIBDIRS)),-y $l) \
	+libext$(foreach e,$(LIBEXT),+$e) \
	$(foreach l,$(wildcard $(TECHLIBS)/*.v),-v $l)


#################################################################
## libraries
#################################################################
work:
	vlib $@
	mkdir -p log
