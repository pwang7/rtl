package exercises

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc._
import spinal.lib.fsm._

class ApbArbiterFSM(numI: Int) extends Component {
  require(numI > 0)
  val apbConfig = Apb3Config(
    addressWidth = 4,
    dataWidth = 32,
    selWidth = 1,
    useSlaveError = false
  )
  val io = new Bundle {
    val apbB = master(Apb3(apbConfig))
    val apbA = Vec(slave(Apb3(apbConfig)), numI)
  }

  val apbRegO = Reg(Apb3(apbConfig))
  io.apbB << apbRegO
  val apbRegI = Vec(Reg(Apb3(apbConfig)), numI)
  for ((apbI, apb) <- apbRegI.zip(io.apbA)) {
    apbI << apb
  }

  val done = apbRegO.PREADY && apbRegO.PSEL === B"1" && apbRegO.PENABLE;

  val apbReqList = Array.fill(numI)(Reg(Bool) init (False))
  for ((req, apbI) <- apbReqList.zip(apbRegI)) {
    when(apbI.PSEL === B"1" && !apbI.PENABLE) {
      req := True
      apbI.PREADY := False
    }
  }

  val fsm = new StateMachine {
    val IDLE = new State with EntryPoint
    val stateList = Array.fill(numI)(new State)

    IDLE
      .whenIsActive {
        for ((req, idx) <- apbReqList.zipWithIndex) {
          when(req) {
            goto(stateList(idx))
          }
        }
      }

    for (((state, apbI), idx) <- stateList.zip(apbRegI).zipWithIndex) {
      state
        .onEntry {
          apbRegO.PSEL := apbI.PSEL
          apbRegO.PENABLE := apbI.PENABLE
          apbRegO.PADDR := apbI.PADDR
          apbRegO.PWDATA := apbI.PWDATA
          apbRegO.PWRITE := apbI.PWRITE
          apbI.PRDATA := apbRegO.PRDATA
        }
        .whenIsActive {
          when(done) {
            for (i <- idx until idx + numI) {
              val nextIdx = i % numI
              val nextReq = apbReqList(nextIdx)
              val nextS = stateList(nextIdx)
              when(nextReq) {
                goto(nextS)
              }
            }
            goto(IDLE)
          }
        }
        .onExit {
          apbReqList(idx) := False
          apbI.PREADY := True
        }
    }
  }
}

object ApbArbiterFSM {
  def main(args: Array[String]): Unit = {
    SpinalVerilog(new ApbArbiterFSM(8))
  }
}
