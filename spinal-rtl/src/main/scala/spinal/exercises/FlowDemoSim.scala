package spinal.exercises

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

object FlowDemoSim extends App {
  class FlowM2S[T <: Data](dataType: HardType[T]) extends Component {
    val io = new Bundle {
      val push = slave Flow (dataType())
      val pop = master Flow (dataType())
    }
    io.pop <-< io.push
  }

  val CNT_WIDTH = 4
  val CNT_MAX = scala.math.pow(2, CNT_WIDTH).toInt - 1

  SimConfig
    .withWave
    //   .withConfig(SpinalConfig(
    //     defaultClockDomainFrequency = FixedFrequency(100 MHz),
    //     defaultConfigForClockDomains = ClockDomainConfig(resetKind = SYNC)))
    .compile(new FlowM2S(UInt(8 bits)))
    .doSim { dut =>
      dut.clockDomain.forkStimulus(2)

      var toggle = false
      for(i <- 0 to CNT_MAX) {
        println(s"i=$i")
        toggle = !toggle
        dut.io.push.valid #= toggle
        dut.io.push.payload #= i
        dut.clockDomain.waitSampling(2)
        println(s"pop.valid=${dut.io.pop.valid}")
        println(s"pop.payload=${dut.io.pop.payload}")
        dut.clockDomain.waitSampling(2)
      }

      simSuccess()
    }
}
