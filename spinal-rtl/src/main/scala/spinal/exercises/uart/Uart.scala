package spinal.exercises.uart

import spinal.core._
import spinal.lib._

case class UartCtrlGenerics( dataWidthMax: Int = 8,
                             clockDividerWidth: Int = 20, // baudrate = Fclk / rxSamplePerBit / clockDividerWidth
                             preSamplingSize: Int = 1,
                             samplingSize: Int = 5,
                             postSamplingSize: Int = 2) {
  val rxSamplePerBit = preSamplingSize + samplingSize + postSamplingSize
  assert(isPow2(rxSamplePerBit))
  if ((samplingSize % 2) == 0)
    SpinalWarning(s"It's not nice to have a odd samplingSize value (because of the majority vote)")
}

case class Uart() extends Bundle with IMasterSlave {
  val txd = Bool
  val rxd = Bool

  override def asMaster(): Unit = {
    out(txd)
    in(rxd)
  }
}

object UartParityType extends SpinalEnum(binarySequential) {
  val NONE, EVEN, ODD = newElement()
}

object UartStopType extends SpinalEnum(binarySequential) {
  val ONE, TWO = newElement()
  def toBitCount(that: SpinalEnumCraft[this.type]) : UInt = {
    //(that === ONE) ? U"0" | U"1"
    that.spinalEnum match {
      case ONE => U"0"
      case _ => U"1"
    }
  }
}

case class UartCtrlFrameConfig(g: UartCtrlGenerics) extends Bundle {
  val dataLength = UInt(log2Up(g.dataWidthMax) bits) // Bit count = dataLength + 1
  val stop       = UartStopType()
  val parity     = UartParityType()
}

case class UartCtrlConfig(g: UartCtrlGenerics) extends Bundle {
  val frame        = UartCtrlFrameConfig(g)
  val clockDivider = UInt(g.clockDividerWidth bits) //see UartCtrlGenerics.clockDividerWidth for calculation

  def setClockDivider(
    baudrate: Double,
    clkFrequency: Double = ClockDomain.current.frequency.getValue.toDouble
  ) : Unit = {
    clockDivider := (clkFrequency / baudrate / g.rxSamplePerBit).toLong
  }

  def setClockDivider(value: Int) : Unit = {
    clockDivider := value
  }
}
