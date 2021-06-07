Regression test files can be found in RV12/bench/tests/regression/. Path to these files does not need to be specified, only test program name is required. Example:
make test=rv32ui-p-addi.hex

Further parameters like MEM_LATENCY, DCACHE_SIZE, ICACHE_SIZE etc. can be modified within makefile itself.
