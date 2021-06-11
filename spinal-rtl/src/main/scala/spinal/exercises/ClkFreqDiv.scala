// https://blog.csdn.net/wangyanchao151/article/details/88535661

package exercises

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

case class ClkFreqDiv(divide: Int) extends Component {
  val io = new Bundle {
    val outputClk = out Bool
  }

  if (divide % 2 == 0) {
    val cntPosEdge = CounterFreeRun(stateCount = divide)
    io.outputClk := cntPosEdge < (divide / 2)
  } else {
    val posCD = new ClockingArea(clockDomain) {
      val cntPosEdge = CounterFreeRun(stateCount = divide)
      val clkSig = cntPosEdge < (divide / 2)
    }

    val negCD = new ClockingArea(clockDomain.withRevertedClockEdge) {
      val cntNegEdge = CounterFreeRun(stateCount = divide)
      val clkSig = cntNegEdge < (divide / 2)
    }

    io.outputClk := posCD.clkSig | negCD.clkSig
  }
}

object ClkFreqDivSim extends App {
  SimConfig.withWave
    .compile(new ClkFreqDiv(divide = 3))
    .doSim { dut =>
      dut.clockDomain.forkStimulus(2)
      for (i <- 0 until 100000) {
        dut.clockDomain.waitSampling
      }
    }
}
