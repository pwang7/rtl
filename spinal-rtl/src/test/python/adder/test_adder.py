import cocotb
from cocotb.triggers import Timer
from ref_model import adder_model
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import random

# A coroutine
async def reset_dut(reset_n, duration_ns):
    reset_n <= 0
    await Timer(duration_ns, units='ns')
    reset_n <= 1
    reset_n._log.debug("Reset complete")

@cocotb.test()
async def adder_basic_test(dut):
    """Test for 5 + 10"""
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())

    A = 5
    B = 10

    # Execution will block until reset_dut has completed
    await reset_dut(dut.rst_n, 500)
    dut._log.debug("After reset")

    dut.A <= A
    dut.B <= B
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert dut.X.value == adder_model(A, B), "Adder result is incorrect: {} != 15".format(dut.X.value)


@cocotb.test()
async def adder_randomised_test(dut):
    """Test for adding 2 random numbers multiple times"""
    cocotb.fork(Clock(dut.clk, 5, units='ns').start())

    # Run reset_dut concurrently
    reset_thread = cocotb.fork(reset_dut(dut.rst_n, duration_ns=500))

    for i in range(10):

        A = random.randint(0, 15)
        B = random.randint(0, 15)

        dut.A <= A
        dut.B <= B

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

        assert dut.X.value == adder_model(A, B), "Randomised test failed with: {A} + {B} = {X}".format(
            A=dut.A.value, B=dut.B.value, X=dut.X.value)

