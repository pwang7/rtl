package spinal.exercises

import spinal.core._
import spinal.lib._

class FifoCC[T <: Data](
      dataType: HardType[T],
  val depth: Int,
  val pushClock: ClockDomain,
  val popClock: ClockDomain
) extends Component {
  require(isPow2(depth) & depth >= 2, "FIFO depth must be power of 2")

  val io = new Bundle {
    val din = in(dataType())
    val wen = in Bool
    val full = out Bool
    val dout = out(dataType())
    val ren = in Bool
    val empty = out Bool
  }

  val ADDR_WIDTH = log2Up(depth + 1)
  val mem = Mem(dataType, depth)

  val popToPushGray = Bits(ADDR_WIDTH bits) addTag(crossClockDomain)
  val pushToPopGray = Bits(ADDR_WIDTH bits) addTag(crossClockDomain)

  val pushArea = new ClockingArea(pushClock) {
    val wAddr = Reg(UInt(ADDR_WIDTH bits)) init(0)
    val fire = io.wen && !io.full
    mem.write(
      enable  = fire,
      address = wAddr.resized,
      data    = io.din
    )
    wAddr := wAddr + fire.asUInt

    val wAddrGray = toGray(wAddr)
    val rAddrGrayInPushArea = BufferCC(popToPushGray, init = B(0, ADDR_WIDTH bits))
    // val rAddrInPushArea = fromGray(rAddrGrayInPushArea)

    io.full := (wAddrGray(ADDR_WIDTH - 1 downto ADDR_WIDTH - 2) === ~rAddrGrayInPushArea(ADDR_WIDTH - 1 downto ADDR_WIDTH - 2)
               && wAddrGray(ADDR_WIDTH - 3 downto 0) === rAddrGrayInPushArea(ADDR_WIDTH - 3 downto 0))
  }

  val popArea = new ClockingArea(popClock) {
    val rAddr = Reg(UInt(ADDR_WIDTH bits)) init(0)
    val fire = io.ren && !io.empty
    // io.dout := mem.readSync(rAddr.resized, enable = fire, clockCrossing = true)
    io.dout := mem.readAsync(rAddr.resized)
    rAddr := rAddr + fire.asUInt

    val rAddrGray = toGray(rAddr)
    val wAddrGrayInPopArea = BufferCC(pushToPopGray, init = B(0, ADDR_WIDTH bits))
    // val wAddrInPopArea = fromGray(wAddrGrayInPopArea)

    io.empty := rAddrGray === wAddrGrayInPopArea
  }

  popToPushGray := popArea.rAddrGray
  pushToPopGray := pushArea.wAddrGray
}
