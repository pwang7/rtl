package spinal.exercises

import spinal.sim._
import spinal.core._
import spinal.core.sim._
import java.security.KeyStore.TrustedCertificateEntry

object CounterSim extends App{
  val CNT_WIDTH = 4
  val CNT_MAX = scala.math.pow(2, CNT_WIDTH).toInt - 1

  SimConfig
    .withWave
    //   .withConfig(SpinalConfig(
    //     defaultClockDomainFrequency = FixedFrequency(100 MHz),
    //     defaultConfigForClockDomains = ClockDomainConfig(resetKind = SYNC)))
    .compile(new Counter(CNT_WIDTH))
    .doSim{dut=>
      SimTimeout(100000)
      dut.clockDomain.forkStimulus(10)

    //   dut.clockDomain.assertReset()
    //   dut.clockDomain.waitSampling()
    //   dut.clockDomain.deassertReset()
      dut.io.clear #= true
      dut.clockDomain.waitSampling()
      dut.io.clear #= false
      dut.clockDomain.waitSampling()

      for(i <- 0 to CNT_MAX) {
        val curCnt = dut.io.value.toInt
        println(s"curCnt=$curCnt, i=$i")
        assert(curCnt == i, s"Counter value wrong, expect cnt=$i, actual cnt=$curCnt")
        dut.clockDomain.waitSampling()
      }

      for(i <- 0 to CNT_MAX / 2) {
        val curCnt = dut.io.value.toInt
        println(s"curCnt=$curCnt, i=$i")
        assert(curCnt == i, s"Counter value wrong after overflow, expect cnt=$i, actual cnt=$curCnt")
        dut.clockDomain.waitSampling()
      }

      dut.io.clear #= true
      dut.clockDomain.waitSampling()
      dut.io.clear #= false
      dut.clockDomain.waitSampling()

      for(i <- 0 to CNT_MAX) {
        val curCnt = dut.io.value.toInt
        println(s"curCnt=$curCnt, i=$i")
        assert(curCnt == i, s"Counter value wrong after clear, expect cnt=$i, actual cnt=$curCnt")
        dut.clockDomain.waitSampling()
      }
    }
}
