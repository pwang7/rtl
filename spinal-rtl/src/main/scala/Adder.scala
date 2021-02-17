
import spinal.sim._
import spinal.core._

class Adder(width: Int = 8) extends Component {
  val io = new Bundle {
    val clk, rst_n = in Bool
    val A, B = in UInt(width bits)
    val X = out UInt(width bits)
  }
  noIoPrefix()

  io.X := io.A + io.B
}

object Adder{
  def main(args: Array[String]): Unit = {
    require(args.length > 0, "Must input RTL target directory")

    SpinalConfig(
      targetDirectory = args(0),
      oneFilePerComponent = true,
      verbose = true
    ).generateVerilog(
      gen = new Adder(width = 5)
    )
  }
}