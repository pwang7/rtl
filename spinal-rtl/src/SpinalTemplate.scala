import spinal.core._
import spinal.lib._

object MyMainObject {
  def main(args: Array[String]) {
    SpinalVerilog(new TheComponentThatIWantToGenerate(constructionArguments))
  }
}

// ClockDomain
object MySpinalConfig extends SpinalConfig(
    defaultConfigForClockDomains = ClockDomainConfig(
                                         resetKind = SYNC,
                                         clockEdge = RISING, 
                                         resetActiveLevel = HIGH)
)
val coreClk = Bool
val coreReset = Bool
val coreClockDomain = ClockDomain(
  clock = coreClk,
  reset = coreReset,
  config = ClockDomainConfig(
    clockEdge = RISING,
    resetKind = ASYNC,
    resetActiveLevel = HIGH
  )
)
val coreArea = new ClockingArea(coreClockDomain) {
  val myCoreClockedRegister = Reg(UInt(4 bit))
  //...
}

// Assignment overlap
class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 42
  a.allowOverride
  a := 66
}

// CDC
class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")

  val regA = clkA(Reg(UInt(8 bits)))
  val regB = clkB(Reg(UInt(8 bits))).addTag(crossClockDomain)

  val tmp = regA + regA
  regB := tmp
}

class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")
  clkB.setSyncronousWith(clkA)

  val regA = clkA(Reg(UInt(8 bits)))
  val regB = clkB(Reg(UInt(8 bits)))


  val tmp = regA + regA
  regB := tmp
}

class syncRead2Write extends Component {
  val io = new Bundle{
    val pushClock, pushRst = in Bool()
    val readPtr = in UInt(8 bits)
  }
  val pushCC = new ClockingArea(ClockDomain(io.pushClock, io.pushRst)) {
    val pushPtrGray = RegNext(toGray(io.readPtr)) init(0)
  }
}

// No combination loop check
class TopLevel extends Component {
  val a = UInt(8 bits).noCombLoopCheck
  a := 0
  a(1) := a(0)
}

// No IO direction check
class TopLevel extends Component {
  val io = new Bundle {
    val a = UInt(8 bits)
  }
  io.a.allowDirectionLessIo
}
// The generated Verilog code
// module TopLevel ();
//  wire       [7:0]    io_a;
// endmodule

// Allow unassigned register
class TopLevel(something: Boolean) extends Component {
  val result = out(UInt(8 bits))
  val a = Reg(UInt(8 bits)).init(42).allowUnsetRegToAvoidLatch

  if(something){   
    a := 37   
  }
  result := a
}

// RAM wirte/readAsync/readSync/readWriteSync
class RamSyncReadWrite extends Component{
  val io = new Bundle{
    val address = in UInt(4 bit)
    val data = in Bits(4 bit)
    val enable = in Bool
    val write = in Bool
    val result = out Bits(4 bit)
  }
  val ram = Mem(Bits(4 bit),16)
  io.result := ram.readWriteSync(io.address, io.data, io.enable, io.write)
}
class RamReadWrite extends Component{
  val io = new Bundle{
    val writeValid = in Bool()
    val writeAddress = in UInt(8 bits)
    val writeData = in Bits(32 bits)
    val readValid = in Bool()
    val readAddress = in UInt(8 bits)
    val readData = out Bits(32 bits)
  }
  val mem = Mem(Bits(32 bits),wordCount = 256)
  mem.write(
    enable  = io.writeValid,
    address = io.writeAddress,
    data    = io.writeData
  )
  //when(io.writeValid) {
  //  mem(io.writeAddress) := io.writeData
  //}
  io.readData := mem.readSync(
    enable  = io.readValid,
    address = io.readAddress
  )
  //when(io.readValid) {
  //  io.readData := mem(io.readAddress)
  //}
}
class Top extends Component{
    val addr = in UInt(5 bits)
    val b = out UInt(8 bits)
    
    val ram = Mem(UInt(8 bits),32)
    
    //b := ram.readAsync(addr) 
    b := ram.readSync(addr) 
}

// Ram blackbox
class Ram_1w_1r(wordWidth: Int, wordCount: Int) extends BlackBox {
  val generic = new Generic {
    val wordCount = Ram_1w_1r.this.wordCount
    val wordWidth = Ram_1w_1r.this.wordWidth
  }
  val io = new Bundle {
    val clk = in Bool
    val wr = new Bundle {
      val en   = in Bool
      val addr = in UInt (log2Up(wordCount) bit)
      val data = in Bits (wordWidth bit)
    }
    val rd = new Bundle {
      val en   = in Bool
      val addr = in UInt (log2Up(wordCount) bit)
      val data = out Bits (wordWidth bit)
    }
  }
  mapClockDomain(clock=io.clk)
}
import spinal.lib.graphic._
object MemorySummingMain{
  def main(args: Array[String]) {
    SpinalConfig(targetDirectory="rtl/")
      // 4 blackboxing policies:
      // - blackboxAll
      // - blackboxAllWhatsYouCan
      // - blackboxRequestedAndUninferable
      // - blackboxOnlyIfRequested
      .addStandardMemBlackboxing(blackboxAll)
      .generateVerilog(new Top)
  }
}
class Top extends Component{
  val io = new Bundle{
    val writeValid = in Bool()
    val writeAddress = in UInt(8 bits)
    val writeData = in(Rgb(RgbConfig(8,8,8)))
    val readValid = in Bool()
    val readAddress = in UInt(8 bits)
    val readData = out(Rgb(RgbConfig(8,8,8)))
  }

  val mem = Mem(Rgb(RgbConfig(8,8,8)),1024)
  // 4 technology options:
  // - auto
  // - ramBlock
  // - distributedLut
  // - registerFile
  mem.setTechnology(tech=registerFile)
  mem.generateAsBlackBox() // explicitly set a memory to be blackboxed

  mem.write(
    enable  = io.writeValid,
    address = io.writeAddress,
    data    = io.writeData
  )

  io.readData := mem.readSync(
    enable  = io.readValid,
    address = io.readAddress
  )
}

// Don't care value
class Top extends Component{
  val io = new Bundle {
    val myBits = in Bits(8 bits)
    val itMatch = out Bool
  }
  io.itMatch := io.myBits === M"00--10--" // - don't care value
  //val myBits  = Bits(8 bits)
  //val itMatch = myBits === M"00--10--" // - don't care value
}

// Bits assignment
class Top extends Component{ 
  // Declaration
  val myBits  = Bits()     // the size is inferred
  val myBits1 = Bits(32 bits)
  val myBits2 = B(25, 8 bits)
  val myBits3 = B"8'xFF"   // Base could be x,h (base 16)
                           //               d   (base 10)
                           //               o   (base 8)
                           //               b   (base 2)
  val myBits4 = B"1001_0011"  // _ can be used for readability

  // Element
  val myBits5 = B(8 bits, default -> True) // "11111111"
  val myBits6 = B(8 bits, (7 downto 5) -> B"101", 4 -> true, 3 -> True, default -> false ) // "10111000"
  val myBits7 = Bits(8 bits)
  myBits7 := (7 -> true, default -> false) // "10000000" (For assignement purposes, you can omit the B)
  myBits  := B(31,8 bits)
}

// Assignement override
class Top extends Component {
  val x,y,z = UInt(8 bits)
  val myVecOf_xyz_ref = Vec(x,y,z)

  for(element <- myVecOf_xyz_ref){
    element := 0   //Assign x,y,z with the value 0
  }

  myVecOf_xyz_ref(2).allowOverride := 1
  myVecOf_xyz_ref(1).allowOverride := 3
  myVecOf_xyz_ref(0).allowOverride := 5
}

// Flow with master/slave
class FIR extends Component{
    val io = new Bundle {
      val fi = slave Flow(SInt(8 bits))
      val fo = master Flow(SInt(8 bits))
      //val fi = in( Flow(SInt(8 bits)) )
      //val fo = out( Flow(SInt(8 bits)) )
    }
    
    //io.fo << io.fi.stage()
    io.fo << io.fi.m2sPipe()
    //io.fi >> io.fo
    //io.fo << io.fi
    //io.fi <> io.fo
    
    def >>(that: FIR):FIR = {
        //this.io.fo >> that.io.fi 
        //that.io.fi << this.io.fo
        this.io.fo.m2sPipe() >> that.io.fi
        that
    }
}
class casCadeFilter(firNumbers: Int) extends Component{
    val io = new Bundle {
      val fi = slave Flow(SInt(8 bits))
      val fo = master Flow(SInt(8 bits))
      //val fi = in( Flow(SInt(8 bits)) )
      //val fo = out( Flow(SInt(8 bits)) )
    }
    
    val Firs = List.fill(firNumbers)(new FIR)
    
    Firs.reduceLeft(_>>_)
    //Firs(0) >> Firs(1) >> Firs(2) >> Firs(3) 
    //Firs(0).>>(Firs(1)).>>(Firs(2)).>>(Firs(3))  //scala Infix expression excute from left to right 
    //Firs(0).io.fi << io.fi
    //io.fo << Firs(firNumbers-1).io.fo
    Firs(0).io.fi << io.fi.m2sPipe()
    io.fo << Firs(firNumbers-1).io.fo.m2sPipe()
}

// Bits.mux/Bits.muxList
class Top extends Component{
  val io = new Bundle{
    val src0,src1 = in Bool()
  }
  val bitwiseSelect = UInt(2 bits)
  val bitwiseResult = bitwiseSelect.mux(
   0 -> (io.src0 & io.src1),
   1 -> (io.src0 | io.src1),
   2 -> (io.src0 ^ io.src1),
   3 -> (io.src0)
  )
}
class Top extends Component{
  val sel  = in UInt(2 bits)
  val data = in Bits(128 bits)
  val dataWord = sel.muxList(for(index <- 0 until 4) yield (index, data(index*32+32-1 downto index*32)))
  // This example can be written shorter.
  val dataWord2 = data.subdivideIn(32 bits)(sel)
}

// Function
class Top extends Component{
  val inc, clear = Bool
  val counter = Reg(UInt(8 bits))

  def setSomethingWhen(something : UInt,cond : Bool,value : UInt): Unit = {
    when(cond) {
      something := value
    }
  }

  setSomethingWhen(something = counter, cond = inc,   value = counter + 1)
  setSomethingWhen(something = counter, cond = clear, value = 0)
}

// Reg definition
class Top extends Component{ 
  val cond = in Bool()
  //UInt register of 4 bits
  val reg1 = Reg(UInt(4 bit))

  //Register that samples reg1 each cycle
  val reg2 = RegNext(reg1 + 1)

  //UInt register of 4 bits initialized with 0 when the reset occurs
  val reg3 = RegInit(U"0000")
  reg3 := reg2
  when(reg2 === 5){
    reg3 := 0xF
  }

  //Register that samples reg3 when cond is True
  val reg4 = RegNextWhen(reg3,cond)

  val reg5 = Reg(UInt(4 bit)) randBoot() // reg [3:0] reg5 = 4'b0000;
}

// Reg bundle
case class ValidRGB() extends Bundle{
  val valid = Bool
  val r,g,b = UInt(8 bits)
}
class Top extends Component{
  val reg = Reg(ValidRGB())
  reg.valid init(False)  // Only the valid of that register bundle will have an reset value.
  println("reg.r.getWidth=" + reg.r.getWidth)
}

// roundUp has almost no performance loss than roundToInf, it is simpler on hardware implement with less area and better timing.
// So we strongly recommend roundup in your work
//
// symetric is very common in hardware design, because there is no need for bit width expansion and almost no performance loss during inversion
//
// fixTo is strongly recommended in your RTL work, you don't need handle
// carry bit align and bit width calculate manually

// Full adder
class AdderCell extends Component {
  //Declaring all in/out in an io Bundle is probably a good practice
  val io = new Bundle {
    val a, b, cin = in Bool
    val sum, cout = out Bool
  }
  //Do some logic
  io.sum := io.a ^ io.b ^ io.cin
  io.cout := (io.a & io.b) | (io.a & io.cin) | (io.b & io.cin)
}
class Adder(width: Int) extends Component {
  // Another example which create an array of ArrayCell
  val cellArray = Array.fill(width)(new AdderCell)
  cellArray.reduceLeft((a, b) => {b.io.cin := a.io.cout; b})
}

// List fold/reduce
Range(1,9).foldLeft(0)((a,b)=>{println(s"$a-->$b");b})
Range(1,9).reduceLeft((a,b)=>{println(s"$a-->$b");b})

// Bus: stream/flow, master/slave
//         master            slave
// stream  valid, payload    ready
// flow    valid, payload    -

// Jump wire: some.where.else.theSignal.pull()
class xxCtrl extends Component{
  val start   = in Bool()
  val end     = out Bool()
  val counter = Reg(UInt(8 bits)) init 0
  when(start){counter.clearAll}
  .otherwise{counter := counter + 1}
  end := counter === 255
}
class xxTop extends Component{
  val start = in Bool()    
  val xx = out UInt()
  
  val ctrl = new xxCtrl    
  ctrl.start := start
  
  xx :=  ctrl.counter.pull() //Jump wire auto through IO
}

// SpinalHDL will never Pruned signals with names

// In bundle, slave is input, master is output,
// so master << slave, not slave << master
// or master <> slave
class Top(payloadWidth: Int, depth: Int) extends Component {
  val io = new Bundle {
    val push = slave(Stream(Bits(payloadWidth bits)))
    val pop  = master(Stream(Bits(payloadWidth bits)))
  }
 io.pop << io.push
}

// Area
class UartCtrl extends Component {
  val timer = new Area {
    val counter = Reg(UInt(8 bit))
    val tick = counter === 0
    counter := counter - 1
    when(tick) {
      counter := 100
    }
  }

  val tickCounter = new Area {
    val value = Reg(UInt(3 bit))
    val reset = False
    when(timer.tick) {          // Refer to the tick from timer area
      value := value + 1
    }
    when(reset) {
      value := 0
    }
  }
}

// ClockingArea
class Top extends Component{
  val myclk,myrst = in Bool()
  val a = in Bits(8 bits)
  val b = out Bits()
  new ClockingArea(ClockDomain(myclk,myrst, config = ClockDomainConfig(
    clockEdge        = RISING,
    resetKind        = ASYNC,
    resetActiveLevel = LOW
  ))){
    val reg0 = RegNext(a) init 0
    b := reg0
  }
}

class SUB extends Component{
    val a = in Bits(8 bits)
    val b = out(RegNext(a) init 0)
}
class Top extends Component{
   val myclk,myrst = in Bool()
   val cd = ClockDomain(myclk,myrst, 
      config = ClockDomainConfig(
      clockEdge        = RISING,
      resetKind        = ASYNC,
      resetActiveLevel = LOW))
    // One way to use ClockDomain
    val u_sub0 = cd(new SUB)
    // The otherway to use ClockDomain
    // new ClockingArea(cd) {
    //   val u_sub0 = new SUB
    // }
}

// ClockDomain
class SUB extends Component{
    val a = in Bits(8 bits)
    val b = out(RegNext(a) init 0)
}
class Top extends Component{
   val myclk,myrst = in Bool()
   val cd = ClockDomain(myclk,myrst, 
      config = ClockDomainConfig(
      clockEdge        = RISING,
      resetKind        = ASYNC,
      resetActiveLevel = LOW))
    val u_sub0 = cd(new SUB)
}

// Internal ClockDomain
class Pll extends Component{
  val io = new Bundle {
    val clkIn = in Bool()
    val clkOut  = out Bool()
    val reset  = out Bool()
  }
  io.clkOut := io.clkIn
  io.reset  := False
}
class InternalClockWithPllExample extends Component {
  val io = new Bundle {
    val clk100M = in Bool()
    val aReset  = in Bool()
    val result  = out UInt (4 bits)
  }
  // myClockDomain.clock will be named myClockName_clk
  // myClockDomain.reset will be named myClockName_reset
  val myClockDomain = ClockDomain.internal("myClockName")

  // Instanciate a PLL (probably a BlackBox)
  val pll = new Pll()
  pll.io.clkIn := io.clk100M

  // Assign myClockDomain signals with something
  myClockDomain.clock := pll.io.clkOut
  myClockDomain.reset := io.aReset || !pll.io.reset

  // Do whatever you want with myClockDomain
  val myArea = new ClockingArea(myClockDomain){
    val myReg = Reg(UInt(4 bits)) init(7)
    myReg := myReg + 1

    io.result := myReg
  }
}

// External ClockDomain
class ExternalClockExample extends Component {
  val io = new Bundle {
    val result = out UInt (4 bits)
  }

  // On top level you have two signals  :
  //     myClockName_clk and myClockName_reset
  val myClockDomain = ClockDomain.external("myClockName")

  val myArea = new ClockingArea(myClockDomain){
    val myReg = Reg(UInt(4 bits)) init(7)
    myReg := myReg + 1

    io.result := myReg
  }
}

// Current ClockDomain
class T0 extends Component {
  println(ClockDomain.current)
  val coreClock,coreReset = in Bool()
  val coreClockDomain = ClockDomain(coreClock, coreReset, frequency=FixedFrequency(99 MHz) )

  println(coreClockDomain.frequency.getValue)
  println(coreClockDomain.hasResetSignal)
  println(coreClockDomain.hasSoftResetSignal)
  println(coreClockDomain.hasClockEnableSignal)
  println(coreClockDomain.readClockWire)
  println(coreClockDomain.readResetWire)
  println(coreClockDomain.readSoftResetWire)
  println(coreClockDomain.readClockEnableWire)
  println(coreClockDomain.isResetActive)
  println(coreClockDomain.isSoftResetActive)
  println(coreClockDomain.isClockEnableActive)
}

// Clock Domain Crossing (CDC) tag
class CrossingExample extends Component {
  val io = new Bundle {
    val clkA = in Bool
    val rstA = in Bool

    val clkB = in Bool
    val rstB = in Bool

    val dataIn  = in Bool
    val dataOut = out Bool
  }

  // sample dataIn with clkA
  val area_clkA = new ClockingArea(ClockDomain(io.clkA,io.rstA)){
    val reg = RegNext(io.dataIn) init(False)
  }

  // 2 register stages to avoid metastability issues
  val area_clkB = new ClockingArea(ClockDomain(io.clkB,io.rstB)){
    val buf0   = RegNext(area_clkA.reg) init(False) addTag(crossClockDomain)
    val buf1   = RegNext(buf0)          init(False)
  }

  io.dataOut := area_clkB.buf1
}

// Alternative implementation where clock domains are given as parameters
class Top extends Component {
  val io = new Bundle {
    val clkA = in Bool()
    val rstA = in Bool()
    val clkB = in Bool()
    val rstB = in Bool()
  }
  val cdA = ClockDomain.internal("ClockDomainA")
  cdA.clock := io.clkA
  cdA.reset := io.rstA
  val cdB = ClockDomain.internal("ClockDomainB")
  cdB.clock := io.clkB
  cdB.reset := io.rstB

  val example = new CrossingExample(cdA, cdB)
}
class CrossingExample(clkA : ClockDomain,clkB : ClockDomain) extends Component {
  val io = new Bundle {
    val dataIn  = in Bool
    val dataOut = out Bool
  }

  // sample dataIn with clkA
  val area_clkA = new ClockingArea(clkA){
    val reg = RegNext(io.dataIn) init(False)
  }

  // 2 register stages to avoid metastability issues
  val area_clkB = new ClockingArea(clkB){
    val buf0   = RegNext(area_clkA.reg) init(False) addTag(crossClockDomain)
    val buf1   = RegNext(buf0)          init(False)
  }

  io.dataOut := area_clkB.buf1
}

// ResetArea
class TopLevel extends Component {
  val specialReset = in Bool()

  // The reset of this area is done with the specialReset signal
  val areaRst_1 = new ResetArea(reset=specialReset, cumulative=false){
    val counter = out(CounterFreeRun(16).value)
  }

  // The reset of this area is a combination between the current reset and the specialReset
  val areaRst_2 = new ResetArea(reset=specialReset, cumulative=true){
    val counter = out(CounterFreeRun(16).value)
  }
}

// ClockEnableArea
class TopLevel extends Component {
  val clockEnable = Bool

  // Add a clock enable for this area
  val area_1 = new ClockEnableArea(clockEnable){
    val counter = out(CounterFreeRun(16).value)
  }
}

// ClockDomain gating, synchronizing, BlackBox
class gate_cell extends BlackBox {
  val io = new Bundle{
    val CLK = in Bool()
    val TSE = in Bool()
    val E   = in Bool()
    val ECK = out Bool()
  }
  noIoPrefix()

  val clk_n   = !io.CLK
  val lock_en = Bool().noCombLoopCheck

  when(clk_n){
    lock_en := io.E
  }.otherwise{
    lock_en := lock_en
  }

  io.ECK := (lock_en && io.CLK)
  if (CommonCellBlackBox.clear) { this.clearBlackBox() }
}
implicit class ClockGateExtend(cd: ClockDomain){
  def gateBy(en: Bool, tse: Bool): ClockDomain = {
    val cg = new gate_cell
    cg.io.CLK := cd.readClockWire
    cg.io.TSE := tse
    cg.io.E   := en
    val cde = ClockDomain(clock = cg.io.ECK,
      reset = cd.readResetWire
    )
    cde.setSynchronousWith(cd)
    cde
  }
}
protected object CommonCellBlackBox {
    private var _clear: Boolean = false
    def clear: Boolean = _clear
    def clear_=(x: Boolean) { _clear = x}
  }
object clearCCBB{
  def apply() = CommonCellBlackBox.clear = true
}
class Top extends Component {
    val io = new Bundle{
      val clken = in Bool()
      val test_mode = in Bool()
      val clkout = out Bool()
    }
 
    val cgd0 = clockDomain.gateBy(io.clken, io.test_mode)
    
    io.clkout := cgd0.readClockWire

    clearCCBB()  //open and try
}

// Stream Join

case class MemoryWrite() extends Bundle{
  val address = UInt(8 bits)
  val data    = Bits(32 bits)
}
case class StreamUnit() extends Component{
  val io = new Bundle{
    val memWrite = slave  Flow(MemoryWrite())
    val cmdA     = slave  Stream(UInt(8 bits))
    val cmdB     = slave  Stream(Bits(32 bits))
    val rsp      = master Stream(Bits(32 bits))
  }

  val mem = Mem(Bits(32 bits),1 << 8)
  mem.write(
    enable = io.memWrite.valid,
    address = io.memWrite.address,
    data = io.memWrite.data
  )

  val memReadStream = mem.streamReadSync(io.cmdA)
  io.rsp << StreamJoin.arg(memReadStream,io.cmdB).translateWith(memReadStream.payload ^ io.cmdB.payload)

//  //Alternative solution for the two precedents lines
//  val memReadStream = io.cmdA.stage()
//  val memReadData   = mem.readSync(
//    enable  = io.cmdA.fire,
//    address = io.cmdA.payload
//  )
//  io.rsp << StreamJoin.arg(memReadStream,io.cmdB).translateWith(memReadData ^ io.cmdB.payload)
}

// Stream FIFO
class StreamFifo[T <: Data](dataType: T, depth: Int) extends Component {
  val io = new Bundle {
    val push = slave Stream (dataType)
    val pop = master Stream (dataType)
  }
  io.pop << io.push
}
class Top extends Component {
  val io = new Bundle {
      val din = slave Stream UInt(8 bits)
      val dout = master Stream UInt(8 bits)
  }
  val sf = new StreamFifo(UInt(8 bits), 16)
  sf.io.pop >> io.dout
  sf.io.push << io.din
  // sf.io.push << io.din.s2mPipe()
  // sf.io.push </< io.din
  // sf.io.push << io.din.m2sPipe()
  // sf.io.push <-< io.din
}

// Stream m2sPipe throwWhen
case class RGB(channelWidth : Int) extends Bundle{
  val red   = UInt(channelWidth bit)
  val green = UInt(channelWidth bit)
  val blue  = UInt(channelWidth bit)

  def isBlack : Bool = red === 0 && green === 0 && blue === 0
}
class Top extends Component{
  val source = slave Stream(RGB(8))
  val sink   = master Stream(RGB(8))
  sink <-< source.throwWhen(source.payload.isBlack)
}

// StreamFifo
import spinal.lib._
class Top extends Component{
  val io = new Bundle {
    val sA,sB = Stream(Bits(8 bits))
    val streamA = slave(sA)
    val streamB = master(sB)
  }

  val myFifo = StreamFifo(
      dataType = Bits(8 bits),
      depth    = 128)
 
  myFifo.io.push << io.streamA
  myFifo.io.pop  >> io.streamB

  // Or equivalently
  // io.streamB << io.streamA.queue(128)
}
showRtl(StreamFifo(UInt(8 bits), 3))

// Stream add m2sPipe and s2mPipe
case class RGB(channelWidth: Int) extends Bundle{
  val red   = UInt(channelWidth bit)
  val green = UInt(channelWidth bit)
  val blue  = UInt(channelWidth bit)
  def isBlack : Bool = red === 0 && green === 0 && blue === 0
}
class MyRGB extends Component{
  val source = slave  Stream(RGB(8))
  val sink   = master Stream(RGB(8))
  sink <-< source.s2mPipe
  //sink </< source.m2sPipe()

  //sink <-< source//.m2sPipe
  //sink </< source//.s2mPipe
}

// Flow
class Myflow1 extends Component{
    val source = slave  Flow(RGB(8))
    val sink   = master Flow(RGB(8))
    sink <-< source
    // sink << source.m2sPipe
}

// Conversion between flow and stream
class T1 extends Component{
    val a = slave Flow(UInt(8 bits) )
    val b = master Flow(UInt())
    val tmp = a.toStream
    b := tmp.toFlow
}
class T1 extends Component{
    val a = slave Stream(UInt(8 bits))
    val b = master Flow(UInt(8 bits) ) 
    b << a.toFlow
}

// StreamFifo and StreamFifoCC
case class FilterConfig(iqWidth: Int, 
                        tapNumbers: Int = 33,
                        hwFreq: HertzNumber = 200 MHz, 
                        sampleFreq: HertzNumber = 1.92 MHz)
case class IQ(width: Int) extends Bundle{
  val I,Q = SInt(width bits)
}
class FilterCC(fc: FilterConfig) extends Component{
  val din   = slave Flow(IQ(fc.iqWidth))
  //val dout  = master Flow(IQ(fc.iqWidth))
  val dout  = master Stream(IQ(fc.iqWidth))
  val flush = in Bool
    
  val clockSMP = ClockDomain.external("smp")
  val clockHW = ClockDomain.external("hw")
    
  val u_fifo_in = StreamFifoCC(
    dataType = IQ(fc.iqWidth),
    depth = 8,
    pushClock = clockSMP,
    popClock = clockDomain
  )
    
  u_fifo_in.io.push << din.toStream 
  dout << u_fifo_in.io.pop//.toFlow
}
class FilterCC2(fc: FilterConfig) extends Component{
  val din = slave Flow(IQ(fc.iqWidth))    
  val dout = master Stream(IQ(fc.iqWidth))

  val clockSMP = ClockDomain.external("smp")
  val clockHW = ClockDomain.external("hw")

  dout << din.toStream.queue(
    size=8,
    pushClock = clockSMP,
    popClock = clockDomain
  )
}
class Filter(fc: FilterConfig) extends Component{
    val din = slave Flow(IQ(fc.iqWidth))    
    val dout = master Stream(IQ(fc.iqWidth))
    dout << din.toStream.queue(16)
}

// Fragment
class Top extends Component{
  val a = slave Flow(Fragment(UInt(8 bits)))
  val b = out UInt()
  val c = out UInt()
  val d = out Bool()
  val e = out Bool()
  b := a.payload.fragment  //
  c := a.fragment          // can be omitted
  d := a.payload.last
  e := a.valid
}

// HardType
case class wrPort[T <: Data](val payloadType: HardType[T]) extends Bundle with IMasterSlave {
  val wr    = Bool()
  val waddr = UInt(8 bits)
  val wdata: T = payloadType()
  override def asMaster(): Unit = out(this)
  //override def clone: wrPort[T] = wrPort(payloadType).asInstanceOf[this.type]
}
class Top extends Component{
    val wr = slave(wrPort(Vec(SInt(8 bits), 4)))
}

// APB3 Apb3Config
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc._
class Top extends Component{
    val apbConfig = Apb3Config(
        addressWidth = 12,
        dataWidth    = 32,
        selWidth     = 2)
    val s = slave(Apb3(apbConfig))
    val m = master(Apb3(apbConfig))
    m << s
}
// APB3 signals: PADDR, PSEL, PENABLE, PREADY, PWRITE, PWDATA, PRDATA, PSLVERROR

// APB3 read/write
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc._
val apbConfig = Apb3Config(
  addressWidth  = 4,
  dataWidth     = 32,
  selWidth      = 1,
  useSlaveError = false
)
class Top(apbConfig: Apb3Config) extends Component{
  val io = new Bundle{
    val apb = slave(Apb3(apbConfig))
  }

  val ram = Mem(Bits(apbConfig.dataWidth bits),
                scala.math.pow(2, apbConfig.addressWidth).toInt)
  io.apb.PREADY := True
  io.apb.PRDATA := 0 // To prevent latch generated
  when(io.apb.PSEL(0) && io.apb.PENABLE){
    when(!io.apb.PWRITE) {
      ram.write(io.apb.PADDR, io.apb.PWDATA)
    }.otherwise{
      io.apb.PRDATA := ram.readSync(io.apb.PADDR)
    }
  }
}

// APB3 Apb3SlaveFactory.readAndWrite
class Top extends Component{
    val apb = slave(Apb3(config=Apb3Config(addressWidth=8, dataWidth=32, selWidth=2)))
    val slv = Apb3SlaveFactory(apb, selId=1)  
    val regs = Vec(Reg(UInt(32 bits)) init 0 ,8)
    (0 until 8).map(i=>slv.readAndWrite(regs(i), address=i*4 ))
}

// APB3 Apb3Decoder, Apb3Router
import spinal.lib.bus.amba3.apb._
Apb3Decoder(inputConfig=Apb3Config(addressWidth=16, dataWidth=32),
                        decodings=List((0x00,20), (0x1000,1 KiB), (0x2000,1 KiB), (0x3000,1 KiB)))
Apb3Router(Apb3Config(addressWidth=16, dataWidth=32, selWidth=3))
class Top extends Component{    
    val din  =  slave(Apb3(Apb3Config(addressWidth=16, dataWidth=32)))
    val do1  = master(Apb3(Apb3Config( 8,32)))
    val do2  = master(Apb3(Apb3Config(12,32)))    
    val do3  = master(Apb3(Apb3Config(12,32)))      
    val do4  = master(Apb3(Apb3Config( 2,32)))
    
val mux = Apb3Decoder(master = din, 
                      slaves = List(do1 ->  (0x0000,  64 ),
                                    do2 ->  (0x1000,1 KiB),                                   
                                    do3 ->  (0x2000,4 KiB),                                   
                                    do4 ->  (0x3000,  32 )))
}

// AHB-lite3
class Top extends Component{    
  val ahbConfig = AhbLite3Config(
    addressWidth = 12,
    dataWidth    = 32
  )
  val ahbX = slave(AhbLite3(ahbConfig))
  val ahbY = slave(AhbLite3(ahbConfig))
  val ahbZ = master(AhbLite3(ahbConfig))
  ahbX.HRDATA := 0
  ahbY.HRDATA := 0
  ahbX.HREADYOUT := False
  ahbY.HREADYOUT := False
  ahbX.HRESP := False
  ahbY.HRESP := False    
  when(ahbY.HSEL){
      ahbZ << ahbY
  }.otherwise{
      ahbZ << ahbX
  }
}
// AHB-lite3 signals: HADDR, HSEL, HREADY, HWRITE, HSIZE, HBURST, HPROT, HTRANS, HMASTLOCK, HWDATA, HRDATA, HREADYOUT, HRESP

// AhbLite3ToApb3Bridge
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.amba3.ahblite._
class Top(ahbConfig:AhbLite3Config, apbConfig:Apb3Config) extends Component{
    val ahb = slave(AhbLite3(ahbConfig))
    val apb = master(Apb3(apbConfig))
    val bridge = AhbLite3ToApb3Bridge(ahbConfig,apbConfig)
    ahb >> bridge.io.ahb
    apb << bridge.io.apb
}

// AXI crossBar
Axi4SharedDecoder(
  axiConfig = Axi4Config(addressWidth=16, dataWidth=32, idWidth=4),
  readDecodings = List((0x0000, 64    ),
                       (0x1000, 1 KiB ),
                       (0x2000, 3 KiB )),
  writeDecodings = List((0x3000, 3 KiB ),
                        (0x4000, 3 KiB )), 
  sharedDecodings = List((0x5000, 2 KiB),
                         (0x6000, 1 KiB) )
)

// Axi4SharedToApb3Bridge *not work*
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.amba4.axi._
class Top(aw: Int, dw: Int, iw: Int) extends Component{
  val axi = slave(Axi4Shared(Axi4Config(aw, dw, iw)))
  val apb = master(Apb3(Apb3Config(aw, dw, iw)))
  val bridge = Axi4SharedToApb3Bridge(aw, dw, iw)
  axi <> bridge.io.axi
  apb <> bridge.io.apb
}

// BRAMDecoder
import spinal.lib.bus.bram._
class Top extends Component{
    val din  = slave(BRAM(BRAMConfig(dataWidth=32, addressWidth=16)))
    val do1  = master(BRAM(BRAMConfig(32, 8)))
    val do2  = master(BRAM(BRAMConfig(32,12)))    
    val do3  = master(BRAM(BRAMConfig(32,12)))      
    val do4  = master(BRAM(BRAMConfig(32,2)))
    
val brammux = BRAMDecoder(din, List(do1 ->  (0x00,  4 KiB ),
                                    do2 ->  (0x1000,3 MiB),                                   
                                    do3 ->  (0x2000,2 MiB),                                   
                                    do4 ->  (0x3000,20 KiB)))  
}
class Top(w: Int) extends Component{    
    val din  = slave(BRAM(BRAMConfig(dataWidth=w, addressWidth=12)))
    val do1  = master(BRAM(BRAMConfig(w,10)))
    val do2  = master(BRAM(BRAMConfig(w,10))) 
    
val brammux = BRAMDecoder(din, List(do1 ->  (0x00000,1 KiB),
                                    do2 ->  (0x10000,3 KiB))) 
}

// BusInterface.newReg/BusInterface.newRegAt
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.regif._
class RegBankExample extends Component{
  val io = new Bundle{
    val apb = slave(Apb3(Apb3Config(addressWidth=16,dataWidth=32)))
  }
  val busSlave = BusInterface(io.apb, (0x0000, 100 Byte), 0)
  val M_REG0  = busSlave.newReg(doc="word 0")
  val M_REG1  = busSlave.newReg(doc="word 1")
  val M_REG2  = busSlave.newReg(doc="word 2")

  val M_REGn  = busSlave.newRegAt(address=0x40, doc="word n")
  val M_REGn1 = busSlave.newReg(doc="word n+1")

  val M_REGm  = busSlave.newRegAt(address=0x100, doc="word m")
  val M_REGm1 = busSlave.newReg(doc="word m+1")
}

// BusInterface.newReg().field
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.regif._
import spinal.lib.bus.regif.AccessType._
class RegBankExample extends Component{
  val io = new Bundle{
    val apb = slave(Apb3(Apb3Config(16,32)))
  }
  val busSlave = BusInterface(io.apb,(0x0000, 100 Byte), 0)
  val M_REG0  = busSlave.newReg(doc="REG1")
  val fd0 = M_REG0.field(2 bits, RW, doc= "fields 0")
  M_REG0.reserved(5 bits)
  val fd1 = M_REG0.field(3 bits, RW, doc= "fields 1")
  val fd2 = M_REG0.field(3 bits, RW, doc= "fields 2")
  //auto reserved 2 bits
  val fd3 = M_REG0.fieldAt(pos=16, 4 bits, RC, doc= "fields 3")
  //auto reserved 12 bits

  busSlave.document("RegIf.html")
}

// Interrupt
class cpInterruptFactoryExample extends Component {
  val io = new Bundle {
    val tx_done, rx_done, frame_end = in Bool()
    val interrupt = out Bool()
    val apb = slave(Apb3(Apb3Config(16, 32)))
  }
  val busif2 = Apb3BusInterface(io.apb, (0x000, 100 Byte))

  val tx = io.tx_done
  val rx = io.rx_done
  val frame = io.frame_end

  io.interrupt := InterruptFactory(busif2,"M_CP",tx,rx,frame)
}

// Initialize value in trait
trait PRNBase {
  val size: Int 
  println("size=" + size)
  val Mask = (1 << size) - 1    //attation 
  val Msb  = (1 << (size - 1))  //attation
}
object GPS extends PRNBase{
    val size = 1023
}
object BD extends PRNBase{
    val size = 2046
}
object CF extends { val size = 3 } with PRNBase
BD.Mask toHexString // return 0
CF.Mask
CF.Msb

// Pretty print frequency
implicit class UtilsExpand(x: HertzNumber) {
  def toString0: String = {
    x.toBigDecimal match {
      case y if y > BigDecimal(1e12) => (y/BigDecimal(1e12)).toDouble + " THz"
      case y if y > BigDecimal(1e9)  => (y/BigDecimal(1e9)).toDouble + " GHz"
      case y if y > BigDecimal(1e6)  => (y/BigDecimal(1e6)).toDouble + " MHz"
      case y if y > BigDecimal(1e3)  => (y/BigDecimal(1e3)).toDouble + " KHz"
      case _ => x.toBigDecimal + "Hz"
    }
  }
}
println((1020.21 MHz).toString0)

// Pretty print byte
implicit class ByteExpand(x: BigInt) {
  def pretty: String = {
    x match {
      case y if y >= (BigInt(1) << 80) => (y/(BigInt(1)<<80)) + " YiB"
      case y if y >= (BigInt(1) << 70) => (y/(BigInt(1)<<70)) + " ZiB"
      case y if y >= (BigInt(1) << 60) => (y/(BigInt(1)<<60)) + " EiB"
      case y if y >= (BigInt(1) << 50) => (y/(BigInt(1)<<50)) + " PiB"
      case y if y >= (BigInt(1) << 40) => (y/(BigInt(1)<<40)) + " TiB"
      case y if y >= (BigInt(1) << 30) => (y/(BigInt(1)<<30)) + " GiB"
      case y if y >= (BigInt(1) << 20) => (y/(BigInt(1)<<20)) + " MiB"
      case y if y >= (BigInt(1) << 10) => (y/(BigInt(1)<<10)) + " KiB"
      case _ => x + "Byte"
    }
  }
}
println((BigInt(1) << 80 Byte).pretty)

// Implicit conversion
case class IntList(list: List[Int])
case class DoubleList(list: List[Double])
implicit def Il(list: List[Int]) = IntList(list)
implicit def Dl(list: List[Double]) = DoubleList(list)
object FixTo{
  def apply(x: Int ): Double              = x + 0.00 
  def apply(x: IntList ): List[Int]    = x.list.map(_+1)
  def apply(x: DoubleList ): List[Double] = x.list.map(_+0.00)
}
val a = FixTo(3)
val b = FixTo(DoubleList(List(1,2,3,4,5)))
val c = FixTo(IntList(List(1,2,3,4,5)))
val d = FixTo(List(1.1,2.2,3.3,4.4,5.5))
val e = FixTo(List(1,2,3,4,5))

// Implicit parameters
object MyTransform{
  def apply(x: Int ): Double              = x + 0.00 
  def apply(x: List[Int] )(implicit ignore: Int): List[Double]  = x.map(_+0.00)
  def apply(x: List[String] )(implicit ignore: String): List[Double] = x.map(_.toDouble)
}
object MyApp extends App {
  implicit val x = 0
  implicit val y = ""

  MyTransform(1)
  MyTransform(1::2::Nil)
  MyTransform("a"::"b"::Nil)
}

// Initialize trait first
trait PRNBase {
  val size: Int 

  val Mask = (1 << size) - 1
  val Msb  = (1 << (size - 1))
}
object CF extends { val size = 3 } with PRNBase
CF.Mask
CF.Msb

// Override trait field
trait PRNBase {
  val size: Int 

  def Mask = (1 << size) - 1
  def Msb  = (1 << (size - 1))
}
object BD extends PRNBase{
    override val size = 3
}
BD.size
BD.Mask
BD.Msb

// LatencyAnalysis(dut.io.input, dut.io.output)
class T1 extends Component{
  val a,b  = in UInt(2 bits)
  val c = RegNext(a)
  val d = RegNext(c*b)
  val e = RegNext(d)
  val f = e + b

  println(s"latency ${LatencyAnalysis(a,c)}")
  println(s"latency ${LatencyAnalysis(a,d)}")
  println(s"latency ${LatencyAnalysis(a,e)}")
  println(s"latency ${LatencyAnalysis(a,f)}")    
}

// Spinal timming, list slicing
val rand = new scala.util.Random(0)
val source = List.fill(16384)(rand.nextDouble())
val step = 8
SpinalProgress("start")
val x = source.sliding(step, step).map(_.head).toList
SpinalProgress("done")

// Carry adder
class CarryAdder(size : Int) extends Component{
  val io = new Bundle{
    val a = in UInt(size bits)
    val b = in UInt(size bits)
    val result = out UInt(size bits)      //result = a + b
  }

  var c = False                   //Carry, like a VHDL variable

  for (i <- 0 until size) {
    //Create some intermediate value in the loop scope.
    val a = io.a(i)
    val b = io.b(i)

    //The carry adder's asynchronous logic
    io.result(i) := a ^ b ^ c
    c \= (a & b) | (a & c) | (b & c);    //variable assignment
  }
}

// Color summing
case class Color(channelWidth: Int) extends Bundle {
  val r = UInt(channelWidth bits)
  val g = UInt(channelWidth bits)
  val b = UInt(channelWidth bits)

  def +(that: Color): Color = {
    val result = Color(channelWidth)
    result.r := this.r + that.r
    result.g := this.g + that.g
    result.b := this.b + that.b
    return result
  }

  def clear(): Color ={
    this.r := 0
    this.g := 0
    this.b := 0
    this
  }
}
class ColorSumming(sourceCount: Int, channelWidth: Int) extends Component {
  val io = new Bundle {
    val sources = in Vec(Color(channelWidth), sourceCount)
    val result = out(Color(channelWidth))
  }
/*
  var sum = Color(channelWidth)
  sum.clear()
  for (i <- 0 to sourceCount - 1) {
    sum \= sum + io.sources(i)
  }
  io.result := sum
*/
  io.result := io.sources.reduce(_+_)
}

// Counter
import spinal.lib.Counter
class Counter(width : Int) extends Component{
  val io = new Bundle{
    val clear = in Bool
    val value = out UInt(width bits)
  }
/*
  val register = Reg(UInt(width bits)) init(0)
  register := register + 1
  when(io.clear){
    register := 0
  }
  io.value := register
*/
  val c = Counter(start=0, end=scala.math.pow(2, width).toInt-1)
  when(io.clear) {
      c.clear()
  }
  io.value := c.value
  // io.value := c.valueNext
}

// Timeout and Counter
val timeout = Timeout(1000)
when(timeout){ //implicit conversion to Bool
 timeout.clear() //Clear the flag and the internal counter
}
//Create a counter of 10 states (0 to 9)
val counter = Counter(10)
counter.clear() //When called it reset the counter. It's not a flag
counter.increment() //When called it increment the counter. It's not a flag
counter.value //current value
counter.valueNext //Next value
counter.willOverflow //Flag that indicate if the counter overflow this cycle
when(counter === 5){ …}

// PLL BlackBox
class PLL extends BlackBox{
  val io = new Bundle{
    val clkIn    = in Bool
    val clkOut   = out Bool
    val isLocked = out Bool
  }
  noIoPrefix()

  // Verilog module parameters
  addGeneric("wordCount", 2)
  addGeneric("wordWidth", 4)

  // Add all RTL dependencies
  // addRTLPath("./rtl/RegisterBank.v")                         // Add a verilog file
  // addRTLPath(s"./rtl/myDesign.vhd")                          // Add a vhdl file
  // addRTLPath(s"${sys.env("MY_PROJECT")}/myTopLevel.vhd")     // Use an environement variable MY_PROJECT (System.getenv("MY_PROJECT"))
}
class TopLevel extends Component{
  val io = new Bundle {
    val aReset    = in Bool
    val clk100Mhz = in Bool
    val result    = out UInt(4 bits)
  }

  // Create an Area to manage all clocks and reset things
  val clkCtrl = new Area {
    //Instanciate and drive the PLL
    val pll = new PLL
    pll.io.clkIn := io.clk100Mhz

    //Create a new clock domain named 'core'
    val coreClockDomain = ClockDomain.internal(
      name = "core",
      frequency = FixedFrequency(200 MHz)  // This frequency specification can be used
    )                                      // by coreClockDomain users to do some calculations

    //Drive clock and reset signals of the coreClockDomain previously created
    coreClockDomain.clock := pll.io.clkOut
    coreClockDomain.reset := ResetCtrl.asyncAssertSyncDeassert(
      input = io.aReset || ! pll.io.isLocked,
      clockDomain = coreClockDomain
    )
  }

  //Create a ClockingArea which will be under the effect of the clkCtrl.coreClockDomain
  val core = new ClockingArea(clkCtrl.coreClockDomain){
    //Do your stuff which use coreClockDomain here
    val counter = Reg(UInt(4 bits)) init(0)
    counter := counter + 1
    io.result := counter
  }
}

// CounterFreeRun, function definition
class RgbToGray extends Component{
  val io = new Bundle{
    val clear = in Bool
    val r,g,b = in UInt(8 bits)

    val wr = out Bool
    val address = out UInt(16 bits)
    val data = out UInt(8 bits)
  }

  def coef(value : UInt, by : Float) : UInt = (value * U((255*by).toInt, 8 bits) >> 8)
  val gray = RegNext(
    coef(io.r, 0.3f) +
    coef(io.g, 0.4f) +
    coef(io.b, 0.3f)
  )

  val address = CounterFreeRun(stateCount = 1 << 16)
  io.address := address
  io.wr := True
  io.data := gray

  when(io.clear){
    gray := 0
    address.clear()
    io.wr := False
  }
}

// Mem initialization, Sinus rom
class TopLevel(resolutionWidth: Int, sampleCount: Int) extends Component {
  val io = new Bundle {
    val sin = out SInt(resolutionWidth bits)
    val sinFiltred = out SInt(resolutionWidth bits)
  }

  def sinTable = for(sampleIndex <- 0 until sampleCount) yield {
    val sinValue = Math.sin(2 * Math.PI * sampleIndex / sampleCount)
    S((sinValue * ((1<<resolutionWidth)/2-1)).toInt, resolutionWidth bits)
  }

  val rom =  Mem(SInt(resolutionWidth bits), initialContent = sinTable)
  val phase = Reg(UInt(log2Up(sampleCount) bits)) init(0)
  phase := phase + 1

  io.sin := rom.readSync(phase)
  io.sinFiltred := RegNext(io.sinFiltred  - (io.sinFiltred  >> 5) + (io.sin >> 5)) init(0)
}

// Fractal calculator
case class PixelSolverGenerics(fixAmplitude : Int,
                               fixResolution : Int,
                               iterationLimit : Int){
  val iterationWidth = log2Up(iterationLimit+1)
  def iterationType = UInt(iterationWidth bits)
  def fixType = SFix(
    peak = fixAmplitude exp,
    resolution = fixResolution exp
  )
}
case class PixelTask(g : PixelSolverGenerics) extends Bundle{
  val x,y = g.fixType
}
case class PixelResult(g : PixelSolverGenerics) extends Bundle{
  val iteration = g.iterationType
}
case class PixelSolver(g : PixelSolverGenerics) extends Component{
  val io = new Bundle{
    val cmd = slave  Stream(PixelTask(g))
    val rsp = master Stream(PixelResult(g))
  }

  import g._

  //Define states
  val x,y       = Reg(fixType) init(0)
  val iteration = Reg(iterationType) init(0)

  //Do some shared calculation
  val xx = x*x
  val yy = y*y
  val xy = x*y

  //Apply default assignment
  io.cmd.ready := False
  io.rsp.valid := False
  io.rsp.iteration := iteration

  when(io.cmd.valid) {
    //Is the mandelbrot iteration done ?
    when(xx + yy >= 4.0 || iteration === iterationLimit) {
      io.rsp.valid := True
      when(io.rsp.ready){
        io.cmd.ready := True
        x := 0
        y := 0
        iteration := 0
      }
    } otherwise {
      x := (xx - yy + io.cmd.x).truncated
      y := (((xy) << 1) + io.cmd.y).truncated
      iteration := iteration + 1
    }
  }
}

// simPublic
object SimAccessSubSignal {
  import spinal.core.sim._
  class TopLevel extends Component {
    val counter = Reg(UInt(8 bits)) init(0)
    counter := counter + 1
  }

  def main(args: Array[String]) {
    SimConfig.compile {
      val dut = new TopLevel
      dut.counter.simPublic()
      dut
    }.doSim{dut =>
      dut.clockDomain.forkStimulus(10)

      for(i <- 0 to 3) {
        dut.clockDomain.waitSampling()
        println(dut.counter.toInt)
      }
    }
  }
}

// Component.addPrePopTask()
class JtagInstruction(tap: JtagTapAccess,val instructionId: Bits) extends Area {
  def doCapture(): Unit = {}
  def doShift(): Unit = {}
  def doUpdate(): Unit = {}
  def doReset(): Unit = {}

  val instructionHit = tap.getInstruction === instructionId

  Component.current.addPrePopTask(() => {
    when(instructionHit) {
      when(tap.getState === JtagState.DR_CAPTURE) {
        doCapture()
      }
      when(tap.getState === JtagState.DR_SHIFT) {
        doShift()
      }
      when(tap.getState === JtagState.DR_UPDATE) {
        doUpdate()
      }
    }
    when(tap.getState === JtagState.RESET) {
      doReset()
    }
  })
}

// Shift register: (tap.getTdi ## shifter) >> 1
class JtagInstructionRead[T <: Data](data: T) (tap: JtagTapAccess,instructionId: Bits)extends JtagInstruction(tap,instructionId) {
  val shifter = Reg(Bits(data.getBitsWidth bit))

  override def doCapture(): Unit = {
    shifter := data.asBits
  }

  override def doShift(): Unit = {
    shifter := (tap.getTdi ## shifter) >> 1
    tap.setTdo(shifter.lsb)
  }
}

// JTAG
import spinal.lib.com.jtag._
class SimpleJtagTap extends Component {
  val io = new Bundle {
    val jtag    = slave(Jtag())
    val switchs = in  Bits(8 bit)
    val keys    = in  Bits(4 bit)
    val leds    = out Bits(8 bit)
  }

  val tap = new JtagTap(io.jtag, 8)
  val idcodeArea  = tap.idcode(B"x87654321") (instructionId=4)
  val switchsArea = tap.read(io.switchs)     (instructionId=5)
  val keysArea    = tap.read(io.keys)        (instructionId=6)
  val ledsArea    = tap.write(io.leds)       (instructionId=7)
}

// widthOf
object Prime{
  //Pure scala function which return true when the number is prime
  def apply(n : Int) =  ! ((2 until n-1) exists (n % _ == 0))

  //Should return True when the number is prime.
  def apply(n : UInt) : Bool = (0 until 1 << widthOf(n)).filter(i => Prime(i)).map(primeValue => n === primeValue).orR
}
// Abstract bus mapping
//Create a new AxiLite4 bus
val bus = AxiLite4(addressWidth = 12, dataWidth = 32)
//Create the factory which is able to create some bridging logic between the bus and some hardware
val factory = new AxiLite4SlaveFactory(bus)
//Create 'a' and 'b' as write only register
val a = factory.createWriteOnly(UInt(32 bits), address = 0)
val b = factory.createWriteOnly(UInt(32 bits), address = 4)
//Do some calculation
val result = a * b
//Make 'result' readable by the bus
factory.read(result(31 downto 0), address = 8)

// Axi4ToApb3Bridge
val apbBridge = Axi4ToApb3Bridge(
  addressWidth = 20,
  dataWidth = 32,
  idWidth = 4
)
val apbDecoder = Apb3Decoder(
  master = apbBridge.io.apb,
  slaves = List(
    gpioACtrl.io.apb -> (0x00000, 4 kB),
    gpioBCtrl.io.apb -> (0x01000, 4 kB),
    uartCtrl.io.apb -> (0x10000, 4 kB),
    timerCtrl.io.apb -> (0x20000, 4 kB),
    vgaCtrl.io.apb -> (0x30000, 4 kB),
    core.io.debugBus -> (0xF0000, 4 kB)
  )
)

// Axi4CrossbarFactory
val axiCrossbar = Axi4CrossbarFactory()
axiCrossbar.addSlaves(
 ram.io.axi -> (0x00000000L, onChipRamSize),
 sdramCtrl.io.axi -> (0x40000000L, sdramLayout.capacity),
 apbBridge.io.axi -> (0xF0000000L, 1 MB)
)
axiCrossbar.addConnections(
 core.io.i -> List(ram.io.axi, sdramCtrl.io.axi),
 core.io.d -> List(ram.io.axi, sdramCtrl.io.axi, apbBridge.io.axi),
 jtagCtrl.io.axi -> List(ram.io.axi, sdramCtrl.io.axi, apbBridge.io.axi),
 vgaCtrl.io.axi -> List( sdramCtrl.io.axi)
)
axiCrossbar.build()

// Delay
val a = UInt(8 bits)
val b = UInt(8 bits)
val aCalcResult = complicatedLogic(a)
val aLatency = LatencyAnalysis(a,aCalcResult)
val bDelayed = Delay(b,cycleCount = aLatency)
val result = aCalcResult + bDelayed

// BusSlaveFactory exmaple
case class Timer(width : Int) extends Component{
  val io = new Bundle {
    // …
    def driveFrom(busCtrl : BusSlaveFactory,baseAddress : BigInt)
        (ticks : Seq[Bool],clears : Seq[Bool]) = new Area {
      clear := False
    
      //Address 0 => read/write limit (+ auto clear)
      busCtrl.driveAndRead(limit,baseAddress + 0)
      clear.setWhen(busCtrl.isWriting(baseAddress + 0))
    
      //Address 4 => read timer value / write => clear timer value
      busCtrl.read(value,baseAddress + 4)
      clear.setWhen(busCtrl.isWriting(baseAddress + 4))
      //Address 8 => clear/tick masks + bus
      // ...
    }
  }
  // …
}
val apb = Apb3(addressWidth = 8, dataWidth = 32)
val external = new Bundle{
  val clear,tick = Bool
}
val prescaler = Prescaler(16)
val timerA = Timer(32)
val timerB,timerC = Timer(16)
val busCtrl = Apb3SlaveFactory(apb)
val prescalerBridge = prescaler.io.driveFrom(busCtrl,0x00)
val timerABridge = timerA.io.driveFrom(busCtrl,0x40)(
  ticks = List(True, prescaler.io.overflow),
  clears = List(timerA.io.full)
)
val timerBBridge = timerB.io.driveFrom(busCtrl,0x50)(
  ticks = List(True, prescaler.io.overflow, external.tick),
  clears = List(timerB.io.full, external.clear)
)
val timerCBridge = timerC.io.driveFrom(busCtrl,0x60)(
  ticks = List(True, prescaler.io.overflow, external.tick),
  clears = List(timerC.io.full, external.clear)
)

// Fragment assignment, String to Bits
io.tx.data.fragment := helloMessage.map(c => B(c.toInt, 8 bits)).read(counter)
io.tx.data.last := counter === helloMessage.length - 1

// BusSlaveFactory
class WavePlayerMapper(bus : BusSlaveFactory, wavePlayer : WavePlayer) extends Area{
  //TODO pase.run, phase.rate, phase.value, filter.bypass, filter.coef mapping
  bus.driveAndRead(wavePlayer.phase.run,  address = 0x00) init(False)
  bus.drive(wavePlayer.phase.rate, address = 0x04)
  bus.read(wavePlayer.phase.value, address = 0x08)

  bus.driveAndRead(wavePlayer.filter.bypass, address = 0x10) init(True)
  bus.drive(wavePlayer.filter.coef, address = 0x14) init(0)
}

// Stream manipulation
case class MemoryWrite() extends Bundle{
  val address = UInt(8 bits)
  val data    = Bits(32 bits)
}
case class StreamUnit() extends Component{
  val io = new Bundle{
    val memWrite = slave  Flow(MemoryWrite())
    val cmdA     = slave  Stream(UInt(8 bits))
    val cmdB     = slave  Stream(Bits(32 bits))
    val rsp      = master Stream(Bits(32 bits))
  }

  val mem = Mem(Bits(32 bits), wordCount = 256)
  mem.write(
    enable  = io.memWrite.valid,
    address = io.memWrite.address,
    data    = io.memWrite.data
  )
  //val readStream = Stream(Bits(32 bits))
  //readStream.translateFrom(io.cmdA)((to, from) => to := mem(from))
  val readStream = mem.streamReadSync(io.cmdA)

  val joinStream = StreamJoin.arg(readStream, io.cmdB)
  io.rsp << joinStream.translateWith(readStream.payload ^ io.cmdB.payload)
}

// StreamWidthAdapter stream width adapter
case class example5() extends Component{
  val io=new Bundle{
    val dataIn=slave(Stream(UInt(128 bits)))
    val dataOut=master(Stream(UInt(32 bits)))
  }
  io.dataOut <> StreamWidthAdapter.make(io.dataIn,UInt(32 bits)).queue(512)
}

// Mem initBigInt
val sampler = new Area{
  //TODO Rom definition with a sinus + it sampling
  val romSamples = for (sampleId <- 0 until sampleCount) yield {
    val sin = Math.sin(2.0 * Math.PI * sampleId / sampleCount)
    val normalizedSin = (0.5*sin + 0.5) * (Math.pow(2.0, sampleWidth) - 1)
    BigInt(normalizedSin.toLong)
  }
  //Will define a rom of 16 words : (0, 1, 4, 9, 16, 25 , ...)
  val rom = Mem(Sample, sampleCount) initBigInt(romSamples)
  val sample = rom.readAsync(phase.value >> (phaseWidth - sampleCountLog2))
}