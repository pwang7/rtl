import random
from queue import Queue

import cocotb
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge, Timer

@cocotb.coroutine
async def genClockAndReset(dut):
    dut.reset = 1
    dut.clk = 0
    await Timer(1000)
    dut.reset = 0
    await Timer(1000)
    while True:
        dut.clk = 1
        await Timer(500)
        dut.clk = 0
        await Timer(500)


@cocotb.coroutine
async def driverAgent(dut):
    dut.io_push_valid = 0
    dut.io_pop_ready  = 0

    while True:
        await RisingEdge(dut.clk)
        # TODO generate random stimulus on the hardware
        dut.io_push_valid   = random.random() < 0.5
        dut.io_push_payload = random.randint(0,255)
        dut.io_pop_ready    = random.random() < 0.5


@cocotb.coroutine
async def checkerAgent(dut):
    queue = Queue()
    matchCounter = 0
    while matchCounter < 5000:
        await RisingEdge(dut.clk)
        # TODO Capture and store 'push' transactions into the queue
        if dut.io_push_valid == 1 and dut.io_push_ready == 1:
            queue.put(int(dut.io_push_payload))

        # TODO capture and check 'pop' transactions with the head of the queue.
        # If match increment matchCounter else throw error
        if dut.io_pop_valid == 1 and dut.io_pop_ready == 1:
            if queue.empty():
                raise TestFailure("parasite io_pop transaction")
            if dut.io_pop_payload != queue.get():
                raise TestFailure("io_pop_payload missmatch")
            matchCounter += 1


@cocotb.test()
async def test1(dut):
    # Create all threads
    cocotb.fork(genClockAndReset(dut))
    cocotb.fork(driverAgent(dut))
    checker = cocotb.fork(checkerAgent(dut))

    # Wait until the checker finish his job
    await checker.join()
