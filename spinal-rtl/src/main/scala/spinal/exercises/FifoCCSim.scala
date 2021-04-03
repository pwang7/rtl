package spinal.exercises

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

import scala.collection.mutable
import scala.util.Random

object FifoCCSim {
  def runSimulation[T <: BitVector](dut: FifoCC[T]) {
    SimTimeout(1000 * 1000)
    val queueModel = mutable.Queue[Long]()

    // Fork a thread to manage the clock domains signals
    val clocksThread = fork {
      // Clear the clock domains' signals, to be sure the simulation captures their first edges.
      dut.pushClock.fallingEdge()
      dut.popClock.fallingEdge()
      dut.pushClock.deassertReset()
      dut.popClock.deassertReset()
      sleep(0)

      // Do the resets.
      dut.pushClock.assertReset()
      dut.popClock.assertReset()
      sleep(10)
      dut.pushClock.deassertReset()
      dut.popClock.deassertReset()
      sleep(1)

      // Forever, randomly toggle one of the clocks.
      // This will create asynchronous clocks without fixed frequencies.
      while (true) {
        if (Random.nextBoolean()) {
          dut.pushClock.clockToggle()
        } else {
          dut.popClock.clockToggle()
        }
        sleep(1)
      }
    }

    // Push data randomly, and fill the queueModel with pushed transactions.
    val pushThread = fork {
      while (true) {
        dut.io.wen.randomize()
        dut.io.din.randomize()
        //println(s"full=${dut.io.full.toBoolean}")
        dut.pushClock.waitSampling()
        //println(s"wAddr before push=${dut.pushArea.wAddr.toInt}")

        //println(s"rAddrInPush before push=${dut.pushArea.rAddrInPushArea.toInt}")
        if (dut.io.wen.toBoolean && !dut.io.full.toBoolean) {
          //println(s"write=${dut.io.din.toLong}")
          //dut.pushClock.waitSampling()
          queueModel.enqueue(dut.io.din.toLong)
        }
        dut.io.wen #= false
      }
    }

    var readMatch = 0
    // Pop data randomly, and check that it match with the queueModel.
    val popThread = fork {
      while (true) {
        dut.io.ren.randomize()
        //dut.io.ren #= true
        dut.popClock.waitSampling()
        // println(s"full=${dut.io.full.toBoolean}")
        // println(s"empty=${dut.io.empty.toBoolean}")
        // println(s"wAddr before pop=${dut.pushArea.wAddr.toInt}")
        // println(s"wAddrInPop before pop=${dut.popArea.wAddrInPopArea.toInt}")
        // println(s"rAddr before pop=${dut.popArea.rAddr.toInt}")
        // println(s"rAddrInPush before pop=${dut.pushArea.rAddrInPushArea.toInt}")
        if (dut.io.ren.toBoolean && !dut.io.empty.toBoolean) {
          // println(s"rAddr after pop=${dut.popArea.rAddr.toInt}")
          // println(s"read=${dut.io.dout.toLong}")
          assert(dut.io.dout.toLong == queueModel.dequeue())
          readMatch += 1
        }
      }
    }

    waitUntil(readMatch > 10000)
    simSuccess()
  }

  def main(args: Array[String]): Unit = {
    // Compile the Component for the simulator.
    val compiled = SimConfig.withWave.allOptimisation.compile {
      val dut = new FifoCC(
        dataType = Bits(32 bits),
        depth = 16,
        pushClock = ClockDomain.external("clkPush"),
        popClock = ClockDomain.external("clkPop")
      )
      // dut.pushArea.wAddr.simPublic()
      // dut.pushArea.rAddrInPushArea.simPublic()
      // dut.popArea.rAddr.simPublic()
      // dut.popArea.wAddrInPopArea.simPublic()
      dut
    }

    // Run the simulation.
    compiled.doSim(runSimulation(_))
  }
}
