import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import random

def adderRefModel(a: int, b: int) -> int:
    """ model of adder """
    return a + b

# A coroutine
async def reset_dut(rst, duration_ns):
    rst <= 1
    await Timer(duration_ns, units='ns')
    rst <= 0
    rst._log.debug("Reset complete")

@cocotb.test()
async def adderBasicTest(dut):
    """Test for 5 + 10"""
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())

    A = 5
    B = 10

    # Execution will block until reset_dut has completed
    await reset_dut(dut.reset, 500)
    await RisingEdge(dut.clk)
    dut._log.debug("After reset")
    assert dut.X.value == 0, "Adder result after reset is non-zero: {}".format(dut.X.value)

    dut.A <= A
    dut.B <= B
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert dut.X.value == adderRefModel(A, B), "Adder result is incorrect: {} != 15".format(dut.X.value)


@cocotb.test()
async def adderRandomisedTest(dut):
    """Test for adding 2 random numbers multiple times"""
    cocotb.fork(Clock(dut.clk, 5, units='ns').start())

    # Run reset_dut concurrently
    reset_thread = cocotb.fork(reset_dut(dut.reset, duration_ns=500))
    await reset_thread.join()
    await RisingEdge(dut.clk)
    assert dut.X.value == 0, "Adder result after reset is non-zero: {}".format(dut.X.value)

    for i in range(10):

        A = random.randint(0, 15)
        B = random.randint(0, 15)

        dut.A <= A
        dut.B <= B

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

        assert dut.X.value == adderRefModel(A, B), "Randomised test failed with: {A} + {B} = {X}".format(
            A=dut.A.value, B=dut.B.value, X=dut.X.value)

