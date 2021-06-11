package spinal.exercises.mips32

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

// object MyEnumStatic extends SpinalEnum {
//   val ADD, SUB, AND, OR = newElement()
//   defaultEncoding = SpinalEnumEncoding("staticEncoding")(
//     ADD -> B"6'b000_000",
//     SUB -> B"6'b000_001",
//     AND -> B"6'b000_010",
//     OR  -> B"6'b000_011"
//   )
// }

class MIPS32(
  memSize: Int = 256,
  regNum: Int = 32
) extends Component {
  require(memSize > 1)
  require(regNum > 1)

  val io = new Bundle {
    val run = in Bool
  }

  val ADD   = B"6'b000_000"
  val SUB   = B"6'b000_001"
  val AND   = B"6'b000_010"
  val OR    = B"6'b000_011"
  val SLT   = B"6'b000_100"
  val MUL   = B"6'b000_101"
  val HLT   = B"6'b011_111"
  val LW    = B"6'b001_000"
  val SW    = B"6'b001_001"
  val ADDI  = B"6'b001_010"
  val SUBI  = B"6'b001_011"
  val SLTI  = B"6'b001_100"
  val BNEQZ = B"6'b001_101"
  val BEQZ  = B"6'b001_110"

  val RR_ALU = B"3'b000"
  val RM_ALU = B"3'b001"
  val LOAD   = B"3'b010"
  val STORE  = B"3'b011"
  val BRANCH = B"3'b100"
  val HALT   = B"3'b101"

  val WIDTH = 32
  val OPCODE = 31 downto 26
  val RS = 25 downto 21 // Source register
  val RT = 20 downto 16 // Target register
  val RD = 15 downto 11 // Destination register
  val IMM = 15 downto 0 // Immediate data
  val JIMM = 25 downto 0 // Immediate data for J

  val MEM_ADDR_WIDTH = log2Up(memSize)

  val halted = Reg(Bool) init(False) addTag(crossClockDomain)
  val takenBranch = Reg(Bool) init(False) addTag(crossClockDomain)

  val memory = Vec(Reg(Bits(WIDTH bits)), memSize) addTag(crossClockDomain)
  val regBank = Vec(Reg(Bits(WIDTH bits)), regNum) addTag(crossClockDomain)
  val progCnt = Reg(UInt(MEM_ADDR_WIDTH bits)) init(0) addTag(crossClockDomain)

  val cd1 = ClockDomain.internal(name = "clk1", config = ClockDomainConfig(clockEdge = RISING))
  val cd2 = ClockDomain.internal(name = "clk2", config = ClockDomainConfig(clockEdge = FALLING))
  cd1.clock := ClockDomain.current.readClockWire
  cd1.reset := ClockDomain.current.readResetWire
  cd2.clock := ClockDomain.current.readClockWire
  cd2.reset := ClockDomain.current.readResetWire
  cd2.setSynchronousWith(cd1)

  val exStageAluOutAsMemIdx = UInt(MEM_ADDR_WIDTH bits)
  val exStageCond = Bool
  val exStageOpCode = Bits(OPCODE.length bits)

  val ifStage = new ClockingArea(cd1) {
    val run = RegNext(io.run) init(False)

    val instructor = Reg(Bits(WIDTH bits)) init(0)
    val nextProgCnt = Reg(UInt(MEM_ADDR_WIDTH bits)) init(0)

    when (!halted && io.run) {
      when ((exStageOpCode === BEQZ && exStageCond)
            || (exStageOpCode === BNEQZ && !exStageCond)) {
        takenBranch := True
        instructor := memory(exStageAluOutAsMemIdx)
        nextProgCnt := exStageAluOutAsMemIdx + 1
        progCnt := exStageAluOutAsMemIdx + 1
      }.otherwise {
        instructor := memory(progCnt)
        nextProgCnt := progCnt + 1
        progCnt := progCnt + 1
      }
    }
  }

  val idStage = new ClockingArea(cd2) {
    val run = RegNext(ifStage.run) init(False)

    val rsAsRegIdx = ifStage.instructor(RS).asUInt
    val rtAsRegIdx = ifStage.instructor(RT).asUInt
    val dataA = RegNext(regBank(rsAsRegIdx).asSInt)
    val dataB = RegNext(regBank(rtAsRegIdx).asSInt)
    val nextProgCnt = RegNext(ifStage.nextProgCnt)
    val instructor = RegNext(ifStage.instructor)
    val dataImm = RegNext(ifStage.instructor(IMM).asSInt.resize(WIDTH))
    val opType = Reg(Bits(3 bits))

    when (!halted && ifStage.run) {
      switch (ifStage.instructor(OPCODE)) {
        is (ADD, SUB, AND, OR, SLT, MUL) {
          opType := RR_ALU
        }
        is (ADDI, SUBI, SLTI) {
          opType := RM_ALU
        }
        is (LW) {
          opType := LOAD
        }
        is (SW) {
          opType := STORE
        }
        is (BEQZ, BNEQZ) {
          opType := BRANCH
        }
        is (HLT) {
          opType := HALT
        }
        default {
          opType := HALT
        }
      }
    } 
  }

  val exStage = new ClockingArea(cd1) {
    val run = RegNext(idStage.run) init(False)

    val instructor = RegNext(idStage.instructor)
    val opType = RegNext(idStage.opType)
    val aluOut = Reg(SInt(WIDTH bits)) init(0)
    // val aluOutAsMemIdx = Reg(UInt(MEM_ADDR_WIDTH bits)) init(0)
    val dataB = RegNext(idStage.dataB)
    val cond = RegNext(idStage.dataA === 0)

    when (!halted && idStage.run) {
      takenBranch := False
      switch (idStage.opType) {
        is (RR_ALU, RM_ALU) {
          switch (idStage.instructor(OPCODE)) {
            is (ADD) {
              aluOut := (idStage.dataA + idStage.dataB).resized
            }
            is (SUB) {
              aluOut := (idStage.dataA - idStage.dataB).resized
            }
            is (AND) {
              aluOut := (idStage.dataA & idStage.dataB).resized
            }
            is (OR) {
              aluOut := (idStage.dataA | idStage.dataB).resized
            }
            is (SLT) {
              aluOut := S(idStage.dataA < idStage.dataB).resized
            }
            is (MUL) {
              aluOut := (idStage.dataA * idStage.dataB).resized
            }
            is (ADDI) {
              aluOut := idStage.dataA + idStage.dataImm
            }
            is (SUBI) {
              aluOut := idStage.dataA - idStage.dataImm
            }
            is (SLTI) {
              aluOut := S(idStage.dataA < idStage.dataImm).resized
            }
            default {
              aluOut := S"32'h0"
            }
          }
        }
        is (LOAD, STORE) {
          aluOut := idStage.dataA + idStage.dataImm
          // val dataB = RegNext(idStage.dataB)
        }
        is (BRANCH) {
          aluOut := idStage.nextProgCnt.asSInt + idStage.dataImm
          // val cond = RegNext(idStage.dataA === 0)
        }
      }
    }
  }

  val memStage = new ClockingArea(cd2) {
    val run = RegNext(exStage.run) init(False)

    val opType = RegNext(exStage.opType)
    val instructor = RegNext(exStage.instructor)
    val aluOut = RegNext(exStage.aluOut)
    val lmd = Reg(Bits(WIDTH bits))

    when (!halted && exStage.run) {
      switch (exStage.opType) {
        is (RR_ALU, RM_ALU) {
          // val aluOut = RegNext(exStage.aluOut)
        }
        is (LOAD) {
          lmd := memory(exStageAluOutAsMemIdx)
        }
        is (STORE) {
          when (!takenBranch) {
            memory(exStageAluOutAsMemIdx) := B(exStage.dataB).resized
          }
        }
      }
    }
  }

  val wbStage = new ClockingArea(cd1) {
    val run = RegNext(memStage.run) init(False)

    val rdAsMemIdx = memStage.instructor(RD).asUInt
    val rtAsMemIdx = memStage.instructor(RT).asUInt
    when (!takenBranch && memStage.run) {
      switch (memStage.opType) {
        is (RR_ALU) {
          regBank(rdAsMemIdx) := memStage.aluOut.asBits
        }
        is (RM_ALU) {
          regBank(rtAsMemIdx) := memStage.aluOut.asBits
        }
        is (LOAD) {
          regBank(rtAsMemIdx) := memStage.lmd
        }
        is (HALT) {
          halted := True
        }
      }
    }
  }

  exStageAluOutAsMemIdx := U(exStage.aluOut).resized
  exStageCond := exStage.cond
  exStageOpCode := exStage.instructor(OPCODE) 
}

object MIPS32 {
  def main(args: Array[String]) {
    SpinalSystemVerilog(new MIPS32)
  }
}
