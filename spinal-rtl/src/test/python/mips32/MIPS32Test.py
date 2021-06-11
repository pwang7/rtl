import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import random

# A coroutine
async def reset_dut(rst, duration_ns):
    rst <= 1
    await Timer(duration_ns, units='ns')
    rst <= 0
    rst._log.debug("Reset complete")

# @cocotb.test()
# async def adderBasicTest(dut):
#     """Test for 5 + 10"""
#     cocotb.fork(Clock(dut.clk, 10, units='ns').start())

#     A = 5
#     B = 10

#     # Execution will block until reset_dut has completed
#     await reset_dut(dut.reset, 500)
#     await RisingEdge(dut.clk)
#     dut._log.debug("After reset")
#     assert dut.X.value == 0, "Adder result after reset is non-zero: {}".format(dut.X.value)

#     dut.A <= A
#     dut.B <= B
#     await RisingEdge(dut.clk)
#     await RisingEdge(dut.clk)
#     assert dut.X.value == adderRefModel(A, B), "Adder result is incorrect: {} != 15".format(dut.X.value)


@cocotb.test()
async def simpleTest(dut):
    """Simple MIPS32 test"""
    cocotb.fork(Clock(dut.clk, 5, units='ns').start())

    for (k in range(32)) dut.Reg[k] <= k;

    dut.Mem[0] <= 32'h2801000a; // ADDI R1, R0, 10
    dut.Mem[1] <= 32'h28020014; // ADDI R2, R0, 20
    dut.Mem[2] <= 32'h28030019; // ADDI R3, R0, 25
    dut.Mem[4] <= 32'h0ce77800; // OR   R7, R7, R7
    dut.Mem[3] <= 32'h0ce77800; // OR   R7, R7, R7
    dut.Mem[5] <= 32'h00222000; // ADD  R4, R1, R2
    dut.Mem[6] <= 32'h0ce77800; // OR   R7, R7, R7
    dut.Mem[7] <= 32'h00832800; // ADD  R5, R4, R3
    dut.Mem[8] <= 32'hfc000000; // HTL

    dut.HALTED <= 0;
    dut.PC <= 0;
    dut.TAKEN_BRANCH <= 0;

    # Run reset_dut concurrently
    # reset_thread = cocotb.fork(reset_dut(dut.reset, duration_ns=500))
    # await reset_thread.join()
    # await RisingEdge(dut.clk)
    # assert dut.X.value == 0, "Adder result after reset is non-zero: {}".format(dut.X.value)

    for i in range(280):
        await RisingEdge(dut.clk)

    for i in range(6):
        print("R%d = %2d" % (i, dut.Reg[i]))

        # A = random.randint(0, 15)
        # B = random.randint(0, 15)

        # dut.A <= A
        # dut.B <= B

        # await RisingEdge(dut.clk)

        # assert dut.X.value == adderRefModel(A, B), "Randomised test failed with: {A} + {B} = {X}".format(
        #     A=dut.A.value, B=dut.B.value, X=dut.X.value)
