package spinal.exercises

import org.scalatest.FunSuite

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

import testutils.CocotbRunner

class StreamFifoTest extends FunSuite {
  test("test") {
    val compiled = SimConfig.withWave.allOptimisation.compile(
      rtl = new StreamFifo(
        dataType = Bits(8 bits),
        depth = 16
      )
    )

    assert(CocotbRunner("./src/test/python/fifo/"), "Simulation faild")
    println("SUCCESS")
  }
}