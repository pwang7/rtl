import org.scalatest.FunSuite
import spinal.sim._
import spinal.core._
import spinal.core.sim._

class CounterTest extends FunSuite {
  val CNT_WIDTH = 4
  val CNT_MAX = scala.math.pow(2, CNT_WIDTH).toInt - 1

  val dut=SimConfig.withWave.withCoverage.compile(new Counter(CNT_WIDTH))

  test("Free running counter") {
    dut.doSim { dut=>
      dut.clockDomain.forkStimulus(10)

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
    }
  }

  test("Clear counter") {
    dut.doSim { dut=>
      dut.clockDomain.forkStimulus(10)

      dut.clockDomain.assertReset()
      dut.clockDomain.waitSampling()
      dut.clockDomain.deassertReset()

      for(i <- 0 to CNT_MAX / 2) {
        val curCnt = dut.io.value.toInt
        println(s"curCnt=$curCnt, i=$i")
        assert(curCnt == i, s"Counter value wrong after reset, expect cnt=$i, actual cnt=$curCnt")
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
}