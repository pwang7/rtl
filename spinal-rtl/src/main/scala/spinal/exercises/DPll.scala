// https://blog.csdn.net/DBLLLLLLLL/article/details/84395583

package exercises

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

class DPll(
    // bufCntWidth: Int,
    // bufIncStep: Int,
    // bufThresh: Int,
    // bufCntMax: Int,
    outSigPeriodWidth: Int,
    outSigInitPeriod: Int
) extends Component {
  require(outSigInitPeriod > 0)
  // require(bufThresh < bufCntMax)

  val io = new Bundle {
    val sigIn = in Bool
    val sigOut = out Bool
  }

  // Phase detector
  val dpd = new Area {
    val sigXor = io.sigIn ^ io.sigOut
    val lead = sigXor & io.sigIn
    val lag = sigXor & io.sigOut
  }
  /*
  // Buffer
  val DB = new Area {
    val leadCnt = Reg(UInt(bufCntWidth bits)) init(0)
    val lagCnt = Reg(UInt(bufCntWidth bits)) init(0)
    val lead = DPD.lead//False
    val lag = DPD.lag//False

    when (DPD.lead) {
      when (leadCnt < bufThresh) {
        leadCnt := leadCnt + bufIncStep
        // lead := False
      }.otherwise {
        leadCnt := leadCnt + bufIncStep - bufThresh
        // lead := True
      }
    }.otherwise {
      when (leadCnt < bufThresh) {
        // lead := False
      }.otherwise {
        when (leadCnt > 0) {
          leadCnt := leadCnt - bufIncStep + bufThresh
        }
        // lead := True
      }
    }

    when (DPD.lag) {
      when (lagCnt < bufThresh) {
        lagCnt := lagCnt + bufIncStep
        // lag := False
      }.otherwise {
        lagCnt := lagCnt + bufIncStep - bufThresh
        // lag := True
      }
    }.otherwise {
      when (lagCnt < bufThresh) {
        // lag := False
      }.otherwise {
        when (lagCnt > 0) {
          lagCnt := lagCnt - bufIncStep + bufThresh
        }
        // lag := True
      }
    }

    when (leadCnt >= bufCntMax) {
      leadCnt := bufCntMax
    }

    when (lagCnt >= bufCntMax) {
      lagCnt := bufCntMax
    }
  }
   */

  // Oscillator
  val dco = new Area {
    val cntReg = Reg(UInt(outSigPeriodWidth bits)) init (outSigInitPeriod)
    val outSigPeriodReg =
      Reg(UInt(outSigPeriodWidth bits)) init (outSigInitPeriod)
    val willOverflowIfInc = cntReg === outSigPeriodReg
    val willIncrement = True
    val willOverflow = willOverflowIfInc && willIncrement
    val bothRise = io.sigIn.rise(initAt = False)

    when(dpd.lead) {
      outSigPeriodReg := outSigPeriodReg + 1
    }.elsewhen(dpd.lag) {
      when(outSigPeriodReg > 3) {
        outSigPeriodReg := outSigPeriodReg - 1
      }
    }

    when(willOverflow || bothRise) {
      cntReg := 0
    }.otherwise {
      cntReg := cntReg + 1
    }

    io.sigOut := (cntReg < (outSigPeriodReg >> 1)) ? True | False
  }
}

object DPll {
  def main(args: Array[String]): Unit = {
    SpinalVerilog(
      new DPll(
        // bufCntWidth = 16,
        // bufIncStep = 1,
        // bufThresh = 5,
        // bufCntMax = 10000,
        outSigPeriodWidth = 32,
        outSigInitPeriod = 14
      )
    )
  }
}

object DPllSim extends App {
  SimConfig.withFstWave
    .compile(
      new DPll(
        // bufCntWidth = 16,
        // bufIncStep = 1,
        // bufThresh = 0,
        // bufCntMax = 10000,
        outSigPeriodWidth = 32,
        outSigInitPeriod = 3
      )
    )
    .doSim { dut =>
      dut.clockDomain.forkStimulus(2)

      val halfFreq = 17

      for (i <- 0 until 5000) {
        dut.clockDomain.waitSampling(halfFreq)
        dut.io.sigIn #= true
        dut.clockDomain.waitSampling(halfFreq)
        dut.io.sigIn #= false
      }
    }
}
