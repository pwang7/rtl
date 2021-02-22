package spinal.exercises.uart

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

import scala.collection.mutable

object UartSim {
  def streamMasterRandomizer[T <: Data](stream : Stream[T], clockDomain: ClockDomain): Unit = fork {
    while (true) {
      stream.payload.randomize()
      stream.valid #= true
      println("write one")
      waitUntil(stream.ready.toBoolean == true)
      println("write done")
      clockDomain.waitSampling()
    }
  }

  def onStreamFire[T <: Data](stream : Stream[T], clockDomain: ClockDomain)(body : => Unit): Unit = fork {
    while(true) {
      clockDomain.waitSampling()
      waitUntil(stream.valid.toBoolean && stream.ready.toBoolean)
      body
    }
  }

  def onFlowValid[T <: Data](flow : Flow[T], clockDomain: ClockDomain)(body : => Unit): Unit = fork {
    while(true) {
      clockDomain.waitSampling()
      println("read one")
      waitUntil(flow.valid.toBoolean)
      println("read done")
      body
    }
  }

  def main(args: Array[String]): Unit = {
    val freq = FixedFrequency(800 MHz)
    SimConfig.withWave
      .withConfig(SpinalConfig(
        defaultClockDomainFrequency = freq,
        defaultConfigForClockDomains = ClockDomainConfig(resetKind = SYNC)))
      .compile(new UartLoopback)
      .doSim { dut =>
        SimTimeout(5000 * 1000)
        dut.clockDomain.forkStimulus(2)

        var scoreCnt = 0
        val sendQueue = mutable.Queue[Int]()
        val r = streamMasterRandomizer(dut.io.write, dut.clockDomain)

        val f = onStreamFire(dut.io.write, dut.clockDomain) {
            println(s"queue size=${sendQueue.size}")
            sendQueue.enqueue(dut.io.write.payload.toInt)
        }
        
        val v = onFlowValid(dut.io.read, dut.clockDomain) {
            assert(dut.io.read.payload.toInt == sendQueue.dequeue())
            scoreCnt += 1
        }

        //Wait until all scoreboards counters are OK
        waitUntil(scoreCnt > 300)
      }
  }
}
