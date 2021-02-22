package spinal.exercises

import org.scalatest.FunSuite

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

import scala.collection.mutable
import scala.util.Random

class FifoCCTest extends FunSuite {
  test("async fifo test") {
    FifoCCSim.main(null)
  }

  test("sync fifo test") {
    // SpinalConfig(targetDirectory = "rtl").dumpWave(0, "../../../../../../waves/UdpAppSelfTester.vcd").generateVerilog(
    //   new SyncAdder(width = 5)
    // )

    val cd = ClockDomain.external("clk")
    val compiled = SimConfig.withWave.compile(
      rtl = new FifoCC(
        dataType = Bits(32 bits),
        depth = 16,
        pushClock = cd,
        popClock = cd
      )
    )

    // Run the simulation
    compiled.doSim(FifoCCSim.runSimulation(_))
  }
}
