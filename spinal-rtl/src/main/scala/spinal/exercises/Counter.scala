package spinal.exercises

import spinal.core._

class Counter(width : Int) extends Component{
  val io = new Bundle{
    val clear = in Bool
    val value = out UInt(width bits)
  }

  val register = Reg(UInt(width bits)) init(0)
  register.addAttribute("keep")
  when(io.clear){
    register := 0
    println("counter cleared")
  }.otherwise{
    register := register + 1
  }

  io.value := register
}

object CounterInst {
  def main(args: Array[String]) {
    SpinalSystemVerilog(new Counter(8))
  }
}
