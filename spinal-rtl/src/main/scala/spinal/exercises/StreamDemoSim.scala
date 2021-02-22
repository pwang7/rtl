package spinal.exercises

import spinal.sim._
import spinal.core._
import spinal.core.sim._

object StreamDemoSim extends App {
  val CNT_WIDTH = 4
  val CNT_MAX = scala.math.pow(2, CNT_WIDTH).toInt - 1

  def runSimulation(dut: StreamBase[UInt], hasClk: Boolean = true): Unit = {
      if (hasClk) dut.clockDomain.forkStimulus(2)

      var toggle = false
      for(i <- 0 to CNT_MAX) {
        println(s"i=$i")
        toggle = !toggle
        dut.io.push.valid #= toggle
        dut.io.push.payload #= i
        dut.io.pop.ready #= true
        if (hasClk) dut.clockDomain.waitSampling(2)
        println(s"push.ready=${dut.io.push.ready}")
        println(s"pop.valid=${dut.io.pop.valid}")
        println(s"pop.payload=${dut.io.pop.payload}")
        dut.io.pop.ready #= false
        if (hasClk) dut.clockDomain.waitSampling(2)
      }
      simSuccess()
  }

  SimConfig
    .withWave
    //   .withConfig(SpinalConfig(
    //     defaultClockDomainFrequency = FixedFrequency(100 MHz),
    //     defaultConfigForClockDomains = ClockDomainConfig(resetKind = SYNC)))
    .compile(new StreamQueue(UInt(8 bits)))
    .doSim(runSimulation(_))

  SimConfig
    .withWave
    .compile(new StreamM2S(UInt(8 bits)))
    .doSim(runSimulation(_))

  SimConfig
    .withWave
    .compile(new StreamS2M(UInt(8 bits)))
    .doSim(runSimulation(_))

  SimConfig
    .withWave
    .compile(new StreamOnly(UInt(8 bits)))
    .doSim(runSimulation(_, hasClk = false))
}
