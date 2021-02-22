package spinal.exercises.uart

import spinal.core._
import spinal.lib._
import spinal.lib.fsm._

object UartCtrlTxState extends SpinalEnum(binarySequential) {
  val IDLE, START, DATA, PARITY, STOP = newElement()
}

class UartCtrlTx(g : UartCtrlGenerics) extends Component {
  import g._

  val io = new Bundle {
    val configFrame  = in(UartCtrlFrameConfig(g))
    val samplingTick = in Bool
    val write        = slave Stream (Bits(dataWidthMax bit))
    val txd          = out Bool
  }

  // Provide one clockDivider.tick each rxSamplePerBit pulse of io.samplingTick
  // Used by the stateMachine as a baud rate time reference
  val clockDivider = new Area {
    val counter = Counter(rxSamplePerBit)
    val tick = counter.willOverflow
    when(io.samplingTick) {
      counter.increment()
    }
  }

  // Count up each clockDivider.tick, used by the state machine to count up data bits and stop bits
  val tickCounter = new Area {
    val value = Reg(UInt(Math.max(log2Up(dataWidthMax), 2) bit))
    val clear = False

    when (clear) {
      value := 0
    }.elsewhen(clockDivider.tick) {
      value := value + 1
    }
  }

  val stateMachine = new StateMachine {
    import UartCtrlTxState._

    val parity = Reg(Bool)
    val txd = True

    when(clockDivider.tick) {
      parity := parity ^ txd
    }

    io.write.ready := False

    val IDLE: State = new State with EntryPoint {
      whenIsActive {
        when(io.write.valid && clockDivider.tick){
          goto(START)
        }
      }
    }
    
    val START: State = new State {
      whenIsActive {
        txd := False
        when(clockDivider.tick) {
          parity := io.configFrame.parity === UartParityType.ODD
          tickCounter.clear := True
          goto(DATA)
        }
      }
    }

    val DATA = new State {
      whenIsActive {
        txd := io.write.payload(tickCounter.value)
        when(clockDivider.tick) {
          when(tickCounter.value === io.configFrame.dataLength) {
            io.write.ready := True
            tickCounter.clear := True
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
        txd := parity
        when(clockDivider.tick) {
          tickCounter.clear := True
          goto(STOP)
        }
      }
    }

    val STOP = new State {
      whenIsActive {
        when(clockDivider.tick) {
          when(tickCounter.value === UartStopType.toBitCount(io.configFrame.stop)) {
            when (io.write.valid) {
              goto(START)
            }.otherwise {
              goto(IDLE)
            }
          }
        }
      }
    }
  }
  io.txd := RegNext(stateMachine.txd, True)
}
