package spinal.exercises

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

class GCD(width : Int) extends Component {
  require(width > 1)

  val io = new Bundle {
    val load = in Bool
    val intA = in UInt(width bits)
    val intB = in UInt(width bits)
    val ready = out Bool
    val gcd = out UInt(width bits)
  }

  val tmpA = Reg(UInt(width bits)) init(0) simPublic()
  val tmpB = Reg(UInt(width bits)) init(0) simPublic()
  when (io.load) {
    tmpA := io.intA
    tmpB := io.intB
  }.elsewhen (!io.ready) {
    when (tmpA < tmpB) {
      tmpB := tmpB - tmpA
    }.elsewhen (tmpA > tmpB) {
      tmpA := tmpA - tmpB
    }
  }.otherwise {
    tmpA := 0
    tmpB := 0
  }
  io.gcd := tmpB
  io.ready := tmpA === tmpB
}

object GCDMain {
  def main(args: Array[String]) {
    SpinalSystemVerilog(new GCD(8))
  }
}

object GCDSim extends App {
  SimConfig
    .withWave
    //   .withConfig(SpinalConfig(
    //     defaultClockDomainFrequency = FixedFrequency(100 MHz),
    //     defaultConfigForClockDomains = ClockDomainConfig(resetKind = SYNC)))
    .compile(new GCD(8))
    .doSim { dut =>
      SimTimeout(100)

      dut.clockDomain.forkStimulus(2)

      dut.io.intA #= 26
      dut.io.intB #= 65
      dut.io.load #= true
      dut.clockDomain.waitSampling()
      dut.io.load #= false
      dut.clockDomain.waitSampling()
      waitUntil(dut.io.ready.toBoolean == true)
      println(s"A=${dut.tmpA.toInt}, B=${dut.tmpB.toInt}, gcd=${dut.io.gcd.toInt}, ready=${dut.io.ready.toBoolean}")
      assert(dut.io.gcd.toInt == 13)
      // while (true) {
      //   if (dut.io.ready.toBoolean == true) {
      //     assert(dut.io.gcd.toInt == 13)
      //     simSuccess()
      //   }
      //   dut.clockDomain.waitSampling()
      // }
    }
}
