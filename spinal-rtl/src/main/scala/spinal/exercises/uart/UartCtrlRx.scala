package spinal.exercises.uart

import spinal.core._
import spinal.lib._
import spinal.lib.fsm._

object UartCtrlRxState extends SpinalEnum(binarySequential) {
  val IDLE, START, DATA, PARITY, STOP = newElement()
}

class UartCtrlRx(g : UartCtrlGenerics) extends Component {
  import g._
  val io = new Bundle {
    val configFrame  = in(UartCtrlFrameConfig(g))
    val samplingTick = in Bool
    val read         = master Flow (Bits(dataWidthMax bit))
    val rxd          = in Bool
  }

  // Implement the rxd sampling with a majority vote over samplingSize bits
  // Provide a new sampler.value each time sampler.tick is high
  val sampler = new Area {
    val syncroniser = BufferCC(io.rxd)
    val samples     = History(that=syncroniser,when=io.samplingTick,length=samplingSize)
    val value       = RegNext(MajorityVote(samples))
    val tick        = RegNext(io.samplingTick)
  }

  // Provide a bitTimer.tick each rxSamplePerBit
  // reset() can be called to recenter the counter over a start bit.
  val bitTimer = new Area {
    val counter = Reg(UInt(log2Up(rxSamplePerBit) bit))
    val recenter = False
    val tick = False
    when (recenter){
      counter := preSamplingSize + (samplingSize - 1) / 2 - 1
    }.elsewhen (sampler.tick) {
      counter := counter - 1
      when(counter === 0) {
        tick := True
      }
    }
  }

  // Provide bitCounter.value that count up each bitTimer.tick, Used by the state machine to count data bits and stop bits
  // reset() can be called to reset it to zero
  val bitCounter = new Area {
    val value = Reg(UInt(Math.max(log2Up(dataWidthMax), 2) bit))
    val clear = False

    when (clear){
      value := 0
    }.elsewhen (bitTimer.tick) {
      value := value + 1
    }
  }

  // Statemachine that use all precedent area
  val stateMachine = new StateMachine {
    val buffer = Reg(io.read.payload)
    io.read.valid := False

    //Parity calculation
    val parity  = Reg(Bool)
    when(bitTimer.tick) {
      parity := parity ^ sampler.value
    }

    val IDLE: State = new State with EntryPoint {
      whenIsActive {
        // when(sampler.tick && !sampler.value) {
        when(sampler.value === False) {
          bitTimer.recenter := True
          goto(START)
        }
      }
    }
    val START = new State {
      whenIsActive {
        // when(bitTimer.tick) {
        when(bitTimer.tick) {
          bitCounter.clear := True
          parity := io.configFrame.parity === UartParityType.ODD
          when(sampler.value === True) {
            goto(IDLE)
          }.otherwise {
            goto(DATA)
          }
        }
      }
    }

    val DATA = new State {
      whenIsActive {
        when(bitTimer.tick) {
          buffer(bitCounter.value) := sampler.value
          when(bitCounter.value === io.configFrame.dataLength) {
            bitCounter.clear := True
            when(io.configFrame.parity === UartParityType.NONE) {
              goto(STOP)
            } otherwise {
              goto(PARITY)
            }
          }
        }
      }
    }

    val PARITY = new State {
      whenIsActive {
        when(bitTimer.tick) {
          bitCounter.clear := True
          when(parity =/= sampler.value) {
            goto(IDLE)
          }.otherwise {
            goto(STOP)
          }
        }
      }
    }
    val STOP = new State {
      whenIsActive {
        when(bitTimer.tick) {
          when(!sampler.value) {
            goto(IDLE)
          }.elsewhen(bitCounter.value === UartStopType.toBitCount(io.configFrame.stop)) {
            io.read.valid := True
            goto(IDLE)
          }
        }
      }
    }
  }
  io.read.payload := stateMachine.buffer
}
