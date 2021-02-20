package spinal.exercises

import org.scalatest.FunSuite

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

import testutils.CocotbRunner

class SyncAdder(width: Int = 8) extends Component {
  val io = new Bundle {
    val A, B = in UInt(width bits)
    val X = out UInt(width bits)
  }
  noIoPrefix()

  io.X := RegNext(io.A + io.B) init(0)
}

class SyncAdderTest extends FunSuite {
  test("test") {
    // SpinalConfig(targetDirectory = "rtl").dumpWave(0, "../../../../../../waves/UdpAppSelfTester.vcd").generateVerilog(
    //   new SyncAdder(width = 5)
    // )

    val compiled = SimConfig.withWave.compile(
      rtl = new SyncAdder(width = 5)
    )

    assert(CocotbRunner("./src/test/python/syncadder/"), "Simulation faild")
    println("SUCCESS")
  }
}