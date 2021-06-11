package spinal.exercises.mips32

import org.scalatest.FunSuite
import scala.io.Source
import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

//Run this scala test to generate and check that your RTL work correctly
class MIPS32Test extends FunSuite{
  val REG_NUM = 32
  val MEM_SIZE = 256
  val PATH = "./src/test/python/mips32/"

  var compiled: SimCompiled[MIPS32] = null

  test("compile") {
    compiled = SimConfig.withWave.compile {
      val dut = new MIPS32(memSize = MEM_SIZE, regNum = REG_NUM)
      dut.memory.simPublic()
      dut.regBank.simPublic()
      dut.progCnt.simPublic()
      dut.halted.simPublic()
      dut.takenBranch.simPublic()
      dut
    }
  }

  test("testbench1") {
    // compiled.doSimUntilVoid(seed = 42){ dut =>
    //   dut.clockDomain.forkStimulus(10)
    //   PixelSolverChecker(dut.io.cmd, dut.io.rsp, dut.clockDomain)
    // }
    compiled.doSim { dut =>
      dut.clockDomain.forkStimulus(2)

      dut.io.run #= false

      dut.progCnt #= 0;
      dut.halted #= false;
      dut.takenBranch #= false;

      for (k <- (0 until 32)) dut.regBank(k) #= k

      dut.memory(0) #= 0x2801000a // ADDI R1, R0, 10
      dut.memory(1) #= 0x28020014 // ADDI R2, R0, 20
      dut.memory(2) #= 0x28030019 // ADDI R3, R0, 25
      dut.memory(4) #= 0x0ce77800 // OR   R7, R7, R7 -- dummy
      dut.memory(3) #= 0x0ce77800 // OR   R7, R7, R7 -- dummy
      dut.memory(5) #= 0x00222000 // ADD  R4, R1, R2
      dut.memory(6) #= 0x0ce77800 // OR   R7, R7, R7 -- dummy
      dut.memory(7) #= 0x00832800 // ADD  R5, R4, R3
      dut.memory(8) #= 0x7c000000 // HTL

      dut.clockDomain.assertReset()
      dut.clockDomain.waitSampling()
      dut.clockDomain.deassertReset()
      
      dut.io.run #= true
      for (i <- (0 until 50)) dut.clockDomain.waitSampling()
      dut.io.run #= false

      for (k <- (0 until 6)) println(s"R$k = ${dut.regBank(k).toLong}")

      assert(dut.regBank(5).toLong == 55)
    }
  }

  test("testbench2") {
    compiled.doSim { dut =>
      dut.clockDomain.forkStimulus(2)

      dut.memory(120) #= 85
      dut.progCnt #= 0;
      dut.halted #= false;
      dut.takenBranch #= false;

      for (k <- (0 until 32)) dut.regBank(k) #= k

      dut.memory(0) #= 0x28010078; // ADDI R1, R0, 120
      dut.memory(1) #= 0x0c631800; // OR   R3, R3, R3  -- dummy
      dut.memory(2) #= 0x20220000; // LW   R2, 0(R1)
      dut.memory(3) #= 0x0c631800; // OR   R3, R3, R3  -- dummy
      dut.memory(4) #= 0x2842002d; // ADDI R2, R2, 45
      dut.memory(5) #= 0x0c631800; // OR   R3, R3, R3  -- dummy
      dut.memory(6) #= 0x24220001; // SW   R2, 1(R1)
      dut.memory(7) #= 0x7c000000; // HTL

      dut.clockDomain.assertReset()
      dut.clockDomain.waitSampling()
      dut.clockDomain.deassertReset()

      dut.io.run #= true
      for (i <- (0 until 50)) dut.clockDomain.waitSampling()
      dut.io.run #= false

      println(s"MEM[120]= ${dut.memory(120).toLong}")
      println(s"MEM[121]= ${dut.memory(121).toLong}")

      assert(dut.memory(121).toLong == 130)
    }
  }

  test("testbench3") {
    compiled.doSim { dut =>
      dut.clockDomain.forkStimulus(2)

      dut.io.run #= false

      for (k <- (0 until REG_NUM)) dut.regBank(k) #= k
      for (k <- (0 until MEM_SIZE)) dut.memory(k) #= 0

      dut.memory(200) #= 7
      dut.progCnt #= 0;
      dut.halted #= false;
      dut.takenBranch #= false;

      dut.memory(0) #= 0x280a00c8 // ADDI R10, R0, 200
      dut.memory(1) #= 0x28020001 // ADDI R2, R0, 1
      dut.memory(2) #= 0x0e94a000 // OR   R20, R20, R20  -- dummy
      dut.memory(3) #= 0x21430000 // LW   R3, 0(R10)
      dut.memory(4) #= 0x0e94a000 // OR   R20, R20, R20  -- dummy
      dut.memory(5) #= 0x14431000 // Loop: MUL R2, R2, R3
      dut.memory(6) #= 0x2c630001 // SUBI  R3, R3, 1
      dut.memory(7) #= 0x0e94a000 // OR    R20, R20, R20 -- dummy
      dut.memory(8) #= 0x3460fffc // BNEQZ R3, Loop
      dut.memory(9) #= 0x2542fffe // SW    R2, -2(R10)
      dut.memory(10) #= 0x7c000000 // HTL

      dut.clockDomain.assertReset()
      dut.clockDomain.waitSampling()
      dut.clockDomain.deassertReset()
      
      dut.io.run #= true
      for (i <- (0 until 50)) dut.clockDomain.waitSampling()
      dut.io.run #= false

      println(s"MEM[200]= ${dut.memory(200).toLong}")
      println(s"MEM[198]= ${dut.memory(198).toLong}")

      assert(dut.memory(198).toLong == 5040)
    }      
  }

  test("testbench4") {
    val inst = "test4.inst"
    assert(
      ShellRunner(Seq(
        s"cd $PATH",
        s" python3 asm_compiler.py test4.asm > $inst"
      )) == 0,
      "MIPS32 ASM compile failed"
    )

    val instructors = for (line <- Source.fromFile(PATH + inst).getLines()) yield {
      // println(line)
      val parts = line.split("//")
      val inst = Integer.parseInt(parts(0).trim(), 2)
      // println(f"0x$inst%08X")
      inst
    }

    compiled.doSim { dut =>
      dut.clockDomain.forkStimulus(2)

      dut.io.run #= false

      for (k <- (0 until REG_NUM)) dut.regBank(k) #= k
      for (k <- (0 until MEM_SIZE)) dut.memory(k) #= 0

      dut.memory(200) #= 7
      dut.progCnt #= 0;
      dut.halted #= false;
      dut.takenBranch #= false;

      for((inst, idx) <- instructors.zipWithIndex) {
        dut.memory(idx) #= inst
      }

      dut.clockDomain.assertReset()
      dut.clockDomain.waitSampling()
      dut.clockDomain.deassertReset()
      
      dut.io.run #= true
      for (i <- (0 until 50)) dut.clockDomain.waitSampling()
      dut.io.run #= false

      println(s"REG[3]= ${dut.regBank(3).toLong}")
      assert(dut.regBank(3).toLong == 8)
    }
  }

  test("testbench5") {
    val inst = "test5.inst"
    assert(
      ShellRunner(Seq(
        s"cd $PATH",
        s" python3 asm_compiler.py test5.asm > $inst"
      )) == 0,
      "MIPS32 ASM compile failed"
    )

    val instructors = for (line <- Source.fromFile(PATH + inst).getLines()) yield {
      // println(line)
      val parts = line.split("//")
      val inst = Integer.parseInt(parts(0).trim(), 2)
      // println(f"0x$inst%08X")
      inst
    }

    compiled.doSim { dut =>
      dut.clockDomain.forkStimulus(2)

      dut.io.run #= false

      for (k <- (0 until REG_NUM)) dut.regBank(k) #= k
      for (k <- (0 until MEM_SIZE)) dut.memory(k) #= 0

      dut.memory(200) #= 7
      dut.progCnt #= 0;
      dut.halted #= false;
      dut.takenBranch #= false;

      for((inst, idx) <- instructors.zipWithIndex) {
        dut.memory(idx) #= inst
      }

      dut.memory(100) #= 13
      dut.memory(101) #= 23
      dut.memory(102) #= 84
      dut.memory(103) #= 24
      dut.memory(104) #= 57
      dut.memory(105) #= 65
      dut.memory(106) #= 46
      dut.memory(107) #= 41
      dut.memory(108) #= 17
      dut.memory(109) #= 51

      dut.clockDomain.assertReset()
      dut.clockDomain.waitSampling()
      dut.clockDomain.deassertReset()
      
      dut.io.run #= true
      for (i <- (0 until 900)) dut.clockDomain.waitSampling()
      dut.io.run #= false

      for (k <- (100 until 110)) {
        println(s"R$k = ${dut.memory(k).toLong}")
        if (k != 100) {
          assert(
            dut.memory(k).toLong > dut.memory(k - 1).toLong,
            "sort failed"
          )
        }
      }
    }
  }
}