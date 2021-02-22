package spinal.exercises.uart

import spinal.core._
import spinal.lib._

class UartLoopback(g: UartCtrlGenerics = UartCtrlGenerics()) extends Component{
  val io = new Bundle{
    //val uart = master(Uart())
    val write  = slave(Stream(Bits(g.dataWidthMax bit)))
    val read   = master(Flow(Bits(g.dataWidthMax bit)))
  }

  val uartCtrl = new UartCtrl(g)
  uartCtrl.io.config.setClockDivider(baudrate = 1000000)
  uartCtrl.io.config.frame.dataLength := 7  //8 bits
  uartCtrl.io.config.frame.parity := UartParityType.ODD
  uartCtrl.io.config.frame.stop := UartStopType.TWO

  uartCtrl.io.write << io.write
  uartCtrl.io.read >> io.read
  uartCtrl.io.uart.rxd <> uartCtrl.io.uart.txd
}


object UartLoopback {
  def main(args: Array[String]) {
    SpinalConfig(
      defaultClockDomainFrequency = FixedFrequency(50 MHz)
    ).generateVerilog(new UartLoopback())
  }
}
