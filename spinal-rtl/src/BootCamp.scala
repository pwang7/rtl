// val path = System.getProperty("user.dir") + "/source/load-spinal.sc"
// interp.load.module(ammonite.ops.Path(java.nio.file.FileSystems.getDefault().getPath(path)))

// 1.1
class Adder(width: Int) extends Component{
  val a = in(UInt(width bits))
  val b = in(UInt(width bits))
  val c = out(UInt()) 
  c := a + b
}
showRtl(new Adder(8))

import spinal.lib.soc.pinsec._
SpinalVerilog(new Pinsec(500 MHz))

import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.amba4.axi._
import spinal.lib.com.jtag.Jtag
import spinal.lib.com.uart.{Uart, UartCtrlGenerics, UartCtrlMemoryMappedConfig, Apb3UartCtrl}
import spinal.lib.cpu.riscv.impl.Utils.BR
import spinal.lib.cpu.riscv.impl.build.RiscvAxi4
import spinal.lib.cpu.riscv.impl.extension.{BarrelShifterFullExtension, DivExtension, MulExtension}
import spinal.lib.cpu.riscv.impl._
import spinal.lib.graphic.RgbConfig
import spinal.lib.graphic.vga.{Vga, Axi4VgaCtrlGenerics, Axi4VgaCtrl}
import spinal.lib.io.TriStateArray
import spinal.lib.memory.sdram._
import spinal.lib.system.debugger.{JtagAxi4SharedDebugger, SystemDebuggerConfig}

val myCpuConfig = RiscvCoreConfig(
        pcWidth = 32,
        addrWidth = 32,
        startAddress = 0x00000000,
        regFileReadyKind = sync,
        branchPrediction = dynamic,
        bypassExecute0 = true,
        bypassExecute1 = true,
        bypassWriteBack = true,
        bypassWriteBackBuffer = true,
        collapseBubble = false,
        fastFetchCmdPcCalculation = true,
        dynamicBranchPredictorCacheSizeLog2 = 7
      )

myCpuConfig.add(new MulExtension)
myCpuConfig.add(new DivExtension)
myCpuConfig.add(new BarrelShifterFullExtension)
// myCpuConfig.add(new FloatExtension)
// myCpuConfig.add(new VectorExtension)

val myiCacheConfig = InstructionCacheConfig(
        cacheSize    = 4096,
        bytePerLine  = 32,
        wayCount     = 1,  //Can only be one for the moment
        wrappedMemAccess = true,
        addressWidth = 32,
        cpuDataWidth = 32,
        memDataWidth = 32
      )

import spinal.lib.memory.sdram.sdr.IS42x320D
val mySocConfig = PinsecConfig(
    axiFrequency   = 100 MHz,
    onChipRamSize  = 4 KiB,
    sdramLayout    = IS42x320D.layout,
    sdramTimings   = IS42x320D.timingGrade7,
    cpu            = myCpuConfig,
    iCache         = myiCacheConfig)
showRtl(new Pinsec(mySocConfig))

object MySpinalConfig extends SpinalConfig(
    defaultConfigForClockDomains = ClockDomainConfig(
                                         resetKind = ASYNC,
                                         clockEdge = RISING, 
                                         resetActiveLevel = LOW)
)
MySpinalConfig.generateVerilog(new Pinsec(500 MHz))

val freq = 100 MHz
val time = 10 ms
//val time = 100 $ 100.$() =  return  RBM(100)
val cycle = time * freq

// 1.2
class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 42
  when(something){
    a := 66
  }
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 42
  a.allowOverride
  a := 66
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")

  val regA = clkA(Reg(UInt(8 bits)))
  val caB = new ClockingArea(clkB) {
    val regB = Reg(UInt(8 bits))
    val tmp = BufferCC(regA)
    regB := regB + tmp
  }
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")

  val regA = clkA(Reg(UInt(8 bits)))
  val regB = clkB(Reg(UInt(8 bits))).addTag(crossClockDomain)

  val tmp = regA + regA
  regB := tmp
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")
  clkB.setSyncronousWith(clkA)

  val regA = clkA(Reg(UInt(8 bits)))
  val regB = clkB(Reg(UInt(8 bits)))

  val tmp = regA + regA
  regB := tmp
}
showRtl(new TopLevel)

class syncRead2Write extends Component {
  val io = new Bundle{
    val pushClock, pushRst = in Bool()
    val readPtr = in UInt(8 bits)
  }
  val pushCC = new ClockingArea(ClockDomain(io.pushClock, io.pushRst)) {
    val pushPtrGray = RegNext(toGray(io.readPtr)) init(0)
  }
}
showRtl(new syncRead2Write)

class TopLevel extends Component {
  val a = UInt(8 bits).noCombLoopCheck
  a := 0
  a(1) := a(0)
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val io = new Bundle {
    val a = out UInt(8 bits) // changed from in to out
  }
  val tmp = U"x42"
  io.a := tmp
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val io = new Bundle {
    val a = UInt(8 bits)
  }
  io.a.allowDirectionLessIo
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val cond = in(Bool)
  val a = UInt(8 bits)

  a := 0
  when(cond){
    a := 42
  }
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = UInt(8 bits)
  a := 0x42
  result := a
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val io = new Bundle {
    val a = in UInt(8 bits)
  }
  val a = RegNext(io.a)
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val cond = Bool()

  var tmp : UInt = null
  tmp = U"x42"
  when(cond){
    tmp := UInt(8 bits)
  }
  tmp := U"x42"
}
showRtl(new TopLevel)

case class RGB(width : Int) extends Bundle{
  val r,g,b = UInt(width bits)
}
class TopLevel extends Component {
  val tmp = Stream(RGB(8))
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = Reg(UInt(8 bits))
  a := 42
  result := a
}
showRtl(new TopLevel)

class TopLevel(something: Boolean) extends Component {
  val result = out(UInt(8 bits))
  val a = Reg(UInt(8 bits)).init(42).allowUnsetRegToAvoidLatch

  if(something){   
    a := 37   
  }
  result := a
}
showRtl(new TopLevel(false))

class TopLevel extends Component {
  val sel = UInt(2 bits)
  val result = UInt(4 bits)
  switch(sel){
    is(0){ result := 4 }
    is(1){ result := 6 }
    is(2){ result := 8 }
    default{result := 9}
    //is(3){ result := 9 }
    //is(0){ result := 2 } //Duplicated statement is statement !
  }
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val a = UInt(8 bits)
  val b = UInt(4 bits)
  b := a.resized
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val a = UInt(8 bits)
  val b = UInt(4 bits)
  val result = a | (b.resized)
}
showRtl(new TopLevel)

// 2.1
class WhyNot extends Component{
   val ram = Mem(Bits(4 bit),16)
   out(ram.readWriteSync(in UInt(4 bit),in Bits(4 bit),in Bool,in Bool))
   out(ram.readWriteSync(in UInt(4 bit),in Bits(4 bit),in Bool,in Bool))
}
showRtl(new WhyNot)

class Top extends Component{
  val myBits  = Bits(8 bits)
  val itMatch = myBits === M"00--10--" // - don't care value
}
showRtl(new Top)

class Top extends Component{
  val myBool_1 = Bool          // Create a Bool
  myBool_1    := False         // := is the assignment operator

  val myBool_2 = False         // Equivalent to the code above

  val myBool_3 = Bool(5 < 12)  // Use a Scala Boolean to create a Bool
  val myBool_4 = Bool("Spinal" == "Scala")  // Use a Scala Boolean to create a Bool
}
showRtl(new Top)

class Top extends Component{
  val x = Bool          
  val pulse1 = x.fall()  
  val pulse2 = x.rise()
  val pulse3 = x.edge()
}
showRtl(new Top)

class Top extends Component{
  val x = Bool          
  val y = UInt(8 bits)
  when(x.edge){
      y.setAll
  }.otherwise{
      y.clearAll
  }
}
showRtl(new Top)

class Top extends Component{ 
  val x = Bits(8 bits)
  val y = x(6 downto 2) // assign y = x[6 : 2]
  val z = x(0 until 8) // assign z = x[7 : 0]
}
showRtl(new Top)

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
showRtl(new Top)

class Top extends Component{
  val cond       = in Bool
  val bits_8bits = in Bits(8 bits)
  // Bitwise operator
  val a, b, c = Bits(32 bits)
  c := ~(a & b) //  Inverse(a AND b)
  
  val all_1 = a.andR // Check that all bits are equal to 1
  
  // Logical shift
  val bits_10bits = bits_8bits << 2  // shift left (results in 10 bits)
  val shift_8bits = bits_8bits |<< 2 // shift left (results in 8 bits)
  
  // Logical rotation
  val myBits = bits_8bits.rotateLeft(3) // left bit rotation
  
  // Set/clear
  val d = B"8'x42"
  when(cond){
    d.setAll() // set all bits to True when cond is True
  } 
}
showRtl(new Top)

class Top extends Component{
  val myBits = in Bits(8 bits)
  // cast a Bits to SInt
  val mySInt = myBits.asSInt

  // create a Vector of bool
  val myVec = myBits.asBools

  // Cast a SInt to Bits
  val myBits2 = B(mySInt)
}
showRtl(new Top)

class Top extends Component{
  val myUInt,myUInt1,myUInt2,myUInt3,myUInt4,myUInt5,myUInt6,myUInt7,myUInt8,myUInt9 = UInt(8 bits)
  myUInt  := U(2,8 bits)
  myUInt1 := U(2)
  myUInt2 := U"0000_0101"  // Base per default is binary => 5
  myUInt3 := U"h1A"        // Base could be x (base 16)
                          //               h (base 16)
                          //               d (base 10)
                          //               o (base 8)
                          //               b (base 2)
  myUInt4 := U"8'h1A"
  myUInt5 := 2             // You can use scala Int as literal value

  val myBool0 = myUInt === U(7 -> true,(6 downto 0) -> false)
  val myBool1 = myUInt === U(myUInt.range -> true)

  // For assignement purposes, you can omit the U/S, which also alow the use of the [default -> ???] feature
  myUInt6 := (default -> true)                        //Assign myUInt with "11111111"
  myUInt7 := (myUInt.range -> true)                   //Assign myUInt with "11111111"
  myUInt8 := (7 -> true, default -> false)            //Assign myUInt with "10000000"
  myUInt9 := ((4 downto 1) -> true, default -> false) //Assign myUInt with "00011110"
}
showRtl(new Top)

class Top extends Component{
  val mySInt_1,mySInt_2 = in SInt(8 bits)
  val myUInt_8bits = in UInt(8 bits)
  val myBool0,myBool1 = out Bool()
  // Comparaison between two SInt
  myBool0 := mySInt_1 > mySInt_2
  // Comparaison between a UInt and a literal
  myBool1 := myUInt_8bits >= U(3, 8 bits)
  when(myUInt_8bits === 3){
    // Something
  } 
}
showRtl(new Top)

class Top extends Component {
  // Create a vector of 2 signed integers
  val myVecOfSInt = Vec(SInt(8 bits),2)
  myVecOfSInt(0) := 2
  myVecOfSInt(1) := myVecOfSInt(0) + 3

  // Create a vector of 3 different type elements
  val myVecOfMixedUInt = Vec(UInt(3 bits), UInt(5 bits), UInt(8 bits))

  val x,y,z = UInt(8 bits)
  val myVecOf_xyz_ref = Vec(x,y,z)

  // Iterate on a vector
  for(element <- myVecOf_xyz_ref){
    element := 0   //Assign x,y,z with the value 0
  }

  // Map on vector
  myVecOfMixedUInt.map(_ := 0) // assign all element with value 0

  // Assign 3 to the first element of the vector
  myVecOf_xyz_ref(1).allowOverride := 3
}
showRtl(new Top)class Top extends Component {
  // Create a vector of 2 signed integers
  val myVecOfSInt = Vec(SInt(8 bits),2)
  myVecOfSInt(0) := 2
  myVecOfSInt(1) := myVecOfSInt(0) + 3

  // Create a vector of 3 different type elements
  val myVecOfMixedUInt = Vec(UInt(3 bits), UInt(5 bits), UInt(8 bits))

  val x,y,z = UInt(8 bits)
  val myVecOf_xyz_ref = Vec(x,y,z)

  // Iterate on a vector
  for(element <- myVecOf_xyz_ref){
    element := 0   //Assign x,y,z with the value 0
  }

  // Map on vector
  myVecOfMixedUInt.map(_ := 0) // assign all element with value 0

  // Assign 3 to the first element of the vector
  myVecOf_xyz_ref(1).allowOverride := 3
}
showRtl(new Top)

class FIR extends Component{
    val fi = slave Flow(SInt(8 bits))
    val fo = master Flow(SInt(8 bits)) 
    
    fo << fi.stage()
    
    def -->(that: FIR):FIR = {
        this.fo >> that.fi 
        that
    }
}

class casCadeFilter extends Component{
  val fi = slave Flow(SInt(8 bits))
  val fo = master Flow(SInt(8 bits))

  val Firs = List.fill(4)(new FIR)
  Firs(0) --> Firs(1) --> Firs(2) --> Firs(3) 
  //Firs(0).-->(Firs(1)).-->(Firs(2)).-->(Firs(3))  //scala Infix expression excute from left to right 
  Firs(0).fi << fi
  fo << Firs(3).fo   
}
showRtl(new casCadeFilter)

class casCadeFilter(firNumbers: Int) extends Component{
    val fi = slave Flow(SInt(8 bits))
    val fo = master Flow(SInt(8 bits))
    
    val Firs = List.fill(firNumbers)(new FIR)
    
    Firs.reduceLeft(_-->_)     //you can also connnect like this 
    
    Firs(0).fi << fi
    fo << Firs(firNumbers-1).fo   
}
showRtl(new casCadeFilter(8))

(1 to 10).foldLeft(0)((a,b)=>{println(s"$a-->$b");b})
(1 to 10).foldRight(11)((a,b)=>{println(s"$a-->$b");a})
(1 to 10).reduceLeft((a,b)=>{println(s"$a-->$b");b})
(1 to 10).reduceRight((a,b)=>{println(s"$a-->$b");a})

// 2.2
class Top extends Component{
 val a,b,c = UInt(4 bits)
 a := 0
 b := a
 c := a
}
showRtl(new Top)

class Top extends Component{
  var x = UInt(4 bits)
  val y,z = UInt(4 bits)
  x := 0
  y := x      //y read x with the value 0
  x \= x + 1
  z := x      //z read x with the value 1
}
showRtl(new Top)

class Top extends Component{
val a = UInt(4 bits) //Define a combinatorial signal
val b = Reg(UInt(4 bits)) //Define a registered signal
val c = Reg(UInt(4 bits)) init(0) //Define a registered signal which is set to 0 when a reset occurs
}
showRtl(new Top)

class Top extends Component{
  val x = in UInt(10 bits)
  val y = out UInt(8 bits)
  val z,z1 = out UInt()
  y := x.resized
  z := x.resize(4)
  z1 := x.resize(12)

  val a = in SInt(8 bits)
  val b = out SInt(16 bits)
  b := a.resized
}
showRtl(new Top)

class Top extends Component{
    val y,z = out UInt(8 bits)
    val a,b = out SInt(8 bits)
    y := U(3)
    z := 3  
    a := S(-3)
    b := -3
}
showRtl(new Top)

//When 
class Top extends Component{
  val cond1,cond2= in Bool
  val dout = out UInt(8 bits)
  when(cond1){
      dout := 11
  //execute when      cond1 is true
  }.elsewhen(cond2){
      dout := 23
  //execute when (not cond1) and cond2
  }.otherwise{
      dout := 51
  //execute when (not cond1) and (not cond2)
  }
}
showRtl(new Top)

class Top extends Component{
  val x = in UInt(2 bits)
  val dout = out UInt(8 bits)
  switch(x){
    is(0){
      //execute when x === value1
      dout := 11
    }
    is(1){
      //execute when x === value2
      dout := 23
    }
    default{
      //execute if none of precedent condition meet
      dout := 51
    }
  }
}
showRtl(new Top)

class Top extends Component{
val cond = in Bool
val muxOutput,muxOutput2 = out UInt(8 bits)
  muxOutput  := Mux(cond, U(33,8 bits), U(51, 8 bits))
  muxOutput2 := cond ? U(22,8 bits) | U(49, 8 bits)
}
showRtl(new Top)

class Top extends Component{
  val io = new Bundle{
    val src0,src1 = in Bool()
  }
  val bitwiseSelect = UInt(2 bits)
  val bitwiseResult = bitwiseSelect.mux(
   0 -> (io.src0 & io.src1),
   1 -> (io.src0 | io.src1),
   2 -> (io.src0 ^ io.src1),
   default -> (io.src0)
  )
}
showRtl(new Top)

class Top extends Component{
  val sel  = in UInt(2 bits)
  val data = in Bits(128 bits)
  val dataWord = sel.muxList(for(index <- 0 until 4) yield (index, data(index*32+32-1 downto index*32)))
  // This example can be written shorter.
  val dataWord2 = data.subdivideIn(32 bits)(sel)
}
showRtl(new Top)

class Top extends Component{
val a, b, c = UInt(8 bits) // Define 3 combinatorial signals
  c := a + b   // c will be set to 7
  b := 2       // b will be set to 2
  a := b + 3   // a will be set to 5
}
showRtl(new Top)

class Top extends Component{
val x, y = Bool             //Define two combinatorial signals
val result = UInt(8 bits)   //Define a combinatorial signal

result := 1
when(x){
  result := 2
  when(y){
    result := 3
  }
}
}
showRtl(new Top)

class Top extends Component{
  val inc, clear = Bool            //Define two combinatorial signal/wire
  val counter = Reg(UInt(8 bits))  //Define a 8 bits register

  when(inc){
    counter := counter + 1
  }
  when(clear){
    counter := 0    //If inc and clear are True, then this  assignement wins (Last valid assignement rule)
  }
}
showRtl(new Top)

class Top extends Component{
  val inc, clear = Bool
  val counter = Reg(UInt(8 bits))
  
  def setCounter(value : UInt): Unit = {
    counter := value
  }

  when(inc){
    setCounter(counter + 1)  // Set counter with counter + 1
  }
  when(clear){
    counter := 0
  }
}
showRtl(new Top)

class Top extends Component{
  val inc, clear = Bool
  val counter = Reg(UInt(8 bits))
  
  def setCounter(value : UInt): Unit = {
    counter := value
  }

  when(inc){
    setCounter(counter + 1)  // Set counter with counter + 1
  }
  when(clear){
    counter := 0
  }
}
showRtl(new Top)

class Top extends Component{
  val inc, clear = Bool
  val counter = Reg(UInt(8 bits))

  def setCounterWhen(cond : Bool,value : UInt): Unit = {
    when(cond) {
      counter := value
    }
  }

  setCounterWhen(cond = inc,   value = counter + 1)
  setCounterWhen(cond = clear, value = 0)
}
showRtl(new Top)

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
showRtl(new Top)

// 2.3
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
}
showRtl(new Top)

class Top extends Component{
  //Standard way
  val something = Bool
  val value = Reg(Bool)
  value := something

  //Short way
  val something1 = Bool
  val value1 = RegNext(something)
}
showRtl(new Top)

case class ValidRGB() extends Bundle{
  val valid = Bool
  val r,g,b = UInt(8 bits)
}
class Top extends Component{
  val reg = Reg(ValidRGB())
  reg.valid init(False)  //Only the valid of that register bundle will have an reset value.
}
showRtl(new Top)

class Top extends Component{
  val reg1 = Reg(UInt(4 bit)) randBoot() // reg [3:0] reg1 = 4'b0000;
}
showRtl(new Top)

class Top extends Component{
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
  io.readData := mem.readSync(
    enable  = io.readValid,
    address = io.readAddress
  )
}
showRtl(new Top)

// blackboxAll
// blackboxAllWhatsYouCan
// blackboxRequestedAndUninferable
// blackboxOnlyIfRequested
SpinalConfig(targetDirectory="rtl/")
    .addStandardMemBlackboxing(blackboxAll)
    .generateVerilog(new Top)
scala.io.Source.fromFile("rtl/TopTopLevel.v").mkString

import spinal.lib.graphic._
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
showRtl(new Top)
// Ram_1w_1rs #(
//   .wordCount(1024),
//   .wordWidth(24),
//   .clockCrossing(1'b0),
//   .technology("auto"),
//   .readUnderWrite("dontCare"),
//   .wrAddressWidth(8),
//   .wrDataWidth(24),
//   .wrMaskWidth(1),
//   .wrMaskEnable(1'b0),
//   .rdAddressWidth(8),
//   .rdDataWidth(24) 
// ) mem (
//   .wr_clk     (clk                   ), //i
//   .wr_en      (_zz_2                 ), //i
//   .wr_mask    (_zz_3                 ), //i
//   .wr_addr    (io_writeAddress[7:0]  ), //i
//   .wr_data    (_zz_4[23:0]           ), //i
//   .rd_clk     (clk                   ), //i
//   .rd_en      (_zz_5                 ), //i
//   .rd_addr    (io_readAddress[7:0]   ), //i
//   .rd_data    (mem_rd_data[23:0]     )  //o
// );

// 2.4
class Top extends Component{
    val a, b = UInt(8 bits)
    val c = a + b //return 8 bits without protection, may cause overflow
}
showRtl(new Top)

class Top extends Component{
    val a, b = UInt(8 bits)
    val c = a +^ b //return 9 bits, adder with carry
}
showRtl(new Top)

class Top extends Component{
    val a, b = UInt(8 bits)
    val c = a +| b //return 8 bits with saturation
}
showRtl(new Top)

class Top extends Component{
  val a = in SInt(16 bits) //source data is 16 bits                        
  val b = a.ceil(2)        //ceil 2 bits           return 15 bits
  val c = a.floor(2)       //floor 2 bits          return 14 bits
  val d = a.floorToZero(2) //floor 2 bits to zero  return 14 bits
  val e = a.ceilToInf(2)   //ceil 2 bits to Inf    return 15 bits
  val f = a.roundUp(2)     //round 2 bits to +Inf  return 15 bits
  //val g = a.roundDown(2)   //round 2 bits to -Inf  return 15 bits
  //val h = a.roundToZero(2) //round 2 bits to zero  return 15 bits
  val k = a.roundToInf(2)  //round 2 bits to +-Inf return 15 bits
}
showRtl(new Top)

class Top extends Component{
  val a = in SInt(16 bits) //source data is 16 bits             
  val k = a.roundToInf(2)  //round 2 bits to +-Inf return 15 bits
}
showRtl(new Top)

class Top extends Component{
  val a = in SInt(16 bits) //source data is 16 bits 
  val f = a.roundUp(2)     //round 2 bits to +Inf  return 15 bits
}
showRtl(new Top)

class Top extends Component{
  val a = in SInt(16 bits) //source data is 16 bits 
  val b = a.sat(8)         //saturation highest 8 bits, return 8 bits 
  val c = b.symmetry        //symetric 8 bits b (-128~128) to (-127 ~ 127), return 8 bits
}
showRtl(new Top)

class Top extends Component{
  val A = in SInt(10 bits)  
  val B = A.roundToInf(3).sat(3)
}
showRtl(new Top)

class Top extends Component{
  val A = in SInt(10 bits)  
  val B = A.fixTo(7 downto 3) //default RoundToInf, same as A.roundToInf(3).sat(3)
}
showRtl(new Top)

class Top extends Component{
  val A = in SInt(10 bits)  
  val B = A.fixTo(7 downto 3, RoundType.ROUNDUP, sym=true) 
}
showRtl(new Top)

// 2.5
class T1 extends Component{
  val a = in UInt(8 bits)
  val b = out UInt()
  b := a
}
showRtl(new T1)

class T2 extends Component{
  val a = in UInt(8 bits)
  val b = out UInt(10 bits)
  b := a.resized
}
showRtl(new T2)

class T3 extends Component{
  val a = in SInt(8 bits)
  val b = out SInt( )
  b := a.resize(16)
}
showRtl(new T3)

class T4 extends Component{
  val a = in SInt(8 bits)
  val b = out SInt(4 bits)
  b := a.resized
}
showRtl(new T4)

class T4 extends Component{
  val a = in SInt(8 bits)
  val b = out Bool()
  b := a.andR
}
showRtl(new T4)

class Pass extends Component{
  val a = in UInt() //without width declare
  val b = out UInt() //without width declare
  b := a
}
class Top extends Component{
  val x = in UInt(8 bits)
  val y = out UInt() //without width declare

  val uut = new Pass
  uut.a := x
  y     := uut.b
}
showRtl(new Top)

class T5 extends Component{
  val a0 = in SInt(8 bits)    
  val a1 = in SInt(8 bits)
  val c = out SInt()
  val d = out SInt()
  c := (a0 ## a1).asSInt
  d := a0 @@ a1
}
showRtl(new T5)

class T6 extends Component{
  val a = in SInt(16 bits) 
  val b  = out SInt()
  val c  = out SInt() 
  val o0,o1,o2,o3 = out Bool()

  b  := a(5 downto 2)  
  c  := a(0 to 4)
  o0 := a.msb
  o1 := a.lsb
  o2 := a(0)
  o3 := a(9)

  println("w(c)=" + c.getWidth)
}
showRtl(new T6)

// 2.6
class Sub extends Component{
  val a = in UInt(8 bits)
  val b = out UInt()    
  b := a
}
class Top extends Component{
  val a = in UInt(8 bits)
  val b = out UInt(8 bits) 
    
  val u_sub = new Sub 
  u_sub.a := a
  b := u_sub.b
}
showRtl(new Top) 

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
  //Create 2 AdderCell
  val cell0 = new AdderCell
  val cell1 = new AdderCell
  cell1.io.cin := cell0.io.cout   //Connect cout of cell0 to cin of cell1

  // Another example which create an array of ArrayCell
  val cellArray = Array.fill(width)(new AdderCell)
  cellArray(1).io.cin := cellArray(0).io.cout   //Connect cout of cell(0) to cin of cell(1)
}
showRtl(new Adder(8)) 

Range(1,9).foldLeft(0)((a,b)=>{println(s"$a-->$b");b})

class Top extends Component{
  val a = slave Flow(UInt(8 bits))
  val b = master Flow(UInt(8 bits)) 
  b << a //  b <> a also ok
}
showRtl(new Top) 

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
showRtl(new xxTop)

class TopLevel extends Component { 
  val notRemoved1 = UInt(8 bits)
  val notRemoved2 = UInt(8 bits) 
  Reg(UInt(8 bits)) init 0  //pruned signal without name without loads
}
showRtl(new TopLevel)

class MyAdder(width: BitCount) extends Component {
  val io = new Bundle{
    val a,b    = in UInt(width)
    val result = out UInt(width)
  }
  io.result := io.a + io.b
}
showRtl(new MyAdder(8 bits))

class Top extends Component{
  val a = in UInt(8 bits)
  val b = out UInt(8 bits) 
  val c = out UInt(8 bits) 
    
  def pass(x: UInt, n : Int) = {
      val ret = UInt(n bits)
          ret := x 
      ret 
  }

  def pass2(x: UInt) = {
      class Fix(n: Int) extends Component {
          val a = in UInt()
          val b = out  UInt() 
          b := pass(in(a), n)
      }
      val res = new Fix(x.getWidth)
      res.a := x
      res.b
  }
  b := pass(a,8)
  c := pass2(a)
}
showRtl(new Top) 

class Top extends Component{
  // Input RGB color
  val r, g, b = UInt(8 bits)

  // Define a function to multiply a UInt by a scala Float value.
  def coef(value: UInt, by: Float): UInt = (value * U((255*by).toInt, 8 bits) >> 8)

  // Calculate the gray level
  val gray = coef(r, 0.3f) + coef(g, 0.4f) + coef(b, 0.3f)
}
showRtl(new Top) 

case class MyBus(payloadWidth: Int) extends Bundle with IMasterSlave {
  val valid   = Bool
  val ready   = Bool
  val payload = Bits(payloadWidth bits)

  // define the direction of the data in a master mode
  override def asMaster(): Unit = {
    out(valid, payload)
    in(ready)
  }

  // Connect that to this
  def <<(that: MyBus): Unit = {
    this.valid   := that.valid
    that.ready   := this.ready
    this.payload := that.payload
  }

  // Connect this to the FIFO input, return the fifo output
  def queue(size: Int): MyBus = {
    val fifo = new MyBusFifo(payloadWidth, size)
    fifo.io.push << this
    return fifo.io.pop
  }
}
class MyBusFifo(payloadWidth: Int, depth: Int) extends Component {
  val io = new Bundle {
    val push = slave(MyBus(payloadWidth))
    val pop  = master(MyBus(payloadWidth))
  }
  io.pop <> io.push
}
class Top extends Component {
  val io = new Bundle {
    val idata = slave(MyBus(8))
    val odata  = master(MyBus(8))
  }
  io.odata << io.idata.queue(32)
}
showRtl(new Top)

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

  val stateMachine = new Area {
    // Something
  }
}
showRtl(new UartCtrl)

// Sum output is register not flow
class Sum(diw: Int, size: Int, stage: Int) extends Component{
    this.setDefinitionName(s"sum_stage${stage}_n${size}_w${diw}")
    val dow = diw + log2Up(size)

    val io = new Bundle{
      val nets = slave Flow(Vec(SInt(diw bits), size))
      val sum  = out(SInt(dow bits)).setAsReg()
    }

    when(io.nets.valid){
      io.sum := io.nets.payload
        .map(_.resize(dow bits))
        .reduce(_ + _)
    }
}
//showRtl(new Sum(8, 2, 0))
//showRtl(new Sum(8, 7, 0))
class AdderTree(diw: Int, size: Int, groupMaxSize: Int) extends Component{
  private def sumAdd(nets: Flow[Vec[SInt]], stage: Int): Sum = {
    val uSum = new Sum(nets.payload.head.getWidth, nets.payload.size, stage)
    uSum.io.nets.valid   := nets.valid
    uSum.io.nets.payload := nets.payload.resized
    uSum
  }

  def pipeTree(nets: Flow[Vec[SInt]], groupMaxSize: Int , stage: Int = 0): (List[Sum], Int) = {
    val nextStage = stage + 1

    if (nets.payload.size <= groupMaxSize) {
      (List(sumAdd(nets, nextStage)), nextStage)
    } else {
      val grpNum = scala.math.ceil(nets.payload.size.toDouble / groupMaxSize).toInt
      val groupSize = scala.math.ceil(nets.payload.size.toDouble / grpNum).toInt

      val nextAddStage = (0 until grpNum)//.toList
        .map(i => nets.payload.drop(i * groupSize).take(groupSize))
        .map{ grouped =>
          val groupedNets = Flow(Vec(SInt(grouped.head.getWidth bits), grouped.size))
          groupedNets.valid   := nets.valid
          groupedNets.payload := Vec(grouped)
          sumAdd(groupedNets, nextStage)
        }
      val ret = Flow(Vec(SInt(nextAddStage.head.io.sum.getWidth bits), nextAddStage.size))
      ret.valid   := RegNext(nets.valid, init = False)
      ret.payload := Vec(nextAddStage.map(_.io.sum)).resized
      pipeTree(ret, groupMaxSize, nextStage)
    }
  }

  val io_nets = slave Flow(Vec(SInt(diw bits), size))
  val (sum, stage) = pipeTree(io_nets, groupMaxSize, 0)
  this.setDefinitionName(s"adderTree_n${size}_g${groupMaxSize}_dly${stage}")
  def Latency: Int = stage
  def dow: Int = diw + log2Up(groupMaxSize) * stage
  val io_sum  = master Flow(SInt(sum.head.io.sum.getWidth bits))

  io_sum.payload := sum.head.io.sum
  io_sum.valid   := RegNext(sum.head.io.nets.valid, init = False)
}
object AdderTree {
  def apply(nets: Flow[Vec[SInt]], addCellSize: Int): AdderTree = {
    val uAdderTree = new AdderTree(nets.payload.head.getWidth, nets.payload.size, addCellSize)
    uAdderTree.io_nets := nets
    uAdderTree
  }

  def apply(nets: Vec[SInt], addCellSize: Int): AdderTree = {
    val uAdderTree = new AdderTree(nets.head.getWidth, nets.size, addCellSize)
    uAdderTree.io_nets.payload := nets
    uAdderTree.io_nets.valid   := True
    uAdderTree
  }
}
class Top extends Component{
  val io = new Bundle {
    val nets = slave Flow(Vec(SInt(8 bits), 23))
    val sum = master Flow(SInt())
  }
  val adder = AdderTree(io.nets, addCellSize = 4)//group max size = 4
  io.sum << adder.io_sum
}
showRtl(new Top)

// Sum output is flow
class Sum(diw: Int, size: Int, stage: Int) extends Component{
  this.setDefinitionName(s"sum_stage${stage}_n${size}_w${diw}")
  val dow = diw + log2Up(size)

  val io = new Bundle{
    val nets = slave Flow(Vec(SInt(diw bits), size))
    val sum  = master Flow(SInt(dow bits))
  }
  io.sum.payload := RegNext(
    io.nets.payload
      .map(_.resize(dow bits))
      .reduce(_ + _)
  )
  io.sum.valid := RegNext(io.nets.valid)
}
//showRtl(new Sum(8, 2, 0))
//showRtl(new Sum(8, 7, 0))
class AdderTree(diw: Int, size: Int, groupMaxSize: Int) extends Component{
  private def sumAdd(nets: Flow[Vec[SInt]], stage: Int): Sum = {
    val uSum = new Sum(nets.payload.head.getWidth, nets.payload.size, stage)
    uSum.io.nets.valid   := nets.valid
    uSum.io.nets.payload := nets.payload.resized
    uSum
  }

  def pipeTree(nets: Flow[Vec[SInt]], groupMaxSize: Int , stage: Int = 0): (List[Sum], Int) = {
    val nextStage = stage + 1

    if (nets.payload.size <= groupMaxSize) {
      (List(sumAdd(nets, nextStage)), nextStage)
    } else {
      val grpNum = scala.math.ceil(nets.payload.size.toDouble / groupMaxSize).toInt
      val groupSize = scala.math.ceil(nets.payload.size.toDouble / grpNum).toInt

      val nextAddStage = (0 until grpNum)//.toList
        .map(i => nets.payload.drop(i * groupSize).take(groupSize))
        .map{ grouped =>
          val groupedNets = Flow(Vec(SInt(grouped.head.getWidth bits), grouped.size))
          groupedNets.valid   := nets.valid
          groupedNets.payload := Vec(grouped)
          sumAdd(groupedNets, nextStage)
        }
      val ret = Flow(Vec(SInt(nextAddStage.head.io.sum.payload.getWidth bits), nextAddStage.size))
      //ret.valid   := RegNext(nets.valid, init = False)
      val addStageSumValid = nextAddStage.map(_.io.sum.valid).reduce(_ && _)
      ret.valid := addStageSumValid
      ret.payload := Vec(nextAddStage.map(_.io.sum.payload)).resized
      pipeTree(ret, groupMaxSize, nextStage)
    }
  }

  val io_nets = slave Flow(Vec(SInt(diw bits), size))
  val (sum, stage) = pipeTree(io_nets, groupMaxSize, 0)
  this.setDefinitionName(s"adderTree_n${size}_g${groupMaxSize}_dly${stage}")
  def Latency: Int = stage
  def dow: Int = diw + log2Up(groupMaxSize) * stage
  val io_sum  = master Flow(SInt(sum.head.io.sum.payload.getWidth bits))

  io_sum.payload := sum.head.io.sum.payload
  io_sum.valid   := sum.head.io.sum.valid
}
object AdderTree {
  def apply(nets: Flow[Vec[SInt]], addCellSize: Int): AdderTree = {
    val uAdderTree = new AdderTree(nets.payload.head.getWidth, nets.payload.size, addCellSize)
    uAdderTree.io_nets := nets
    uAdderTree
  }

  def apply(nets: Vec[SInt], addCellSize: Int): AdderTree = {
    val uAdderTree = new AdderTree(nets.head.getWidth, nets.size, addCellSize)
    uAdderTree.io_nets.payload := nets
    uAdderTree.io_nets.valid   := True
    uAdderTree
  }
}
class Top extends Component{
  val io = new Bundle {
    val nets = slave Flow(Vec(SInt(8 bits), 23))
    val sum = master Flow(SInt())
  }
  val adder = AdderTree(io.nets, addCellSize = 4)//group max size = 4
  io.sum << adder.io_sum
}
showRtl(new Top)

class Top(gsize: Int) extends Component{
    val group = (0 until gsize).map(i => U(i + 1))
    val io_out = master Flow(Vec(UInt(), gsize))
    io_out.payload := Vec(group)
    io_out.valid := True
}
showRtl(new Top(5))

// 2.7
class Top extends Component{
  val a = in Bits(8 bits)
  val b = RegNext(a) init 0
}
showRtl(new Top)

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
showRtl(new Top)

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
showRtl(new Top)

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
showRtl(new InternalClockWithPllExample)

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
showRtl(new ExternalClockExample)

class T0 extends Component {
  println(ClockDomain.current)
  val coreClock,coreReset = in Bool()
  val coreClockDomain = ClockDomain(coreClock, coreReset, frequency=FixedFrequency(99 MHz) )
  println(coreClockDomain.hasResetSignal)
  println(coreClockDomain.frequency.getValue)
  println(coreClockDomain.hasSoftResetSignal)
  println(coreClockDomain.isResetActive)  
}
showRtl(new T0)

// Implementation where clock and reset pins are given by components IO
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
showRtl(new CrossingExample)
//Alternative implementation where clock domains are given as parameters
class CrossingExample(clkA : ClockDomain, clkB : ClockDomain) extends Component {
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

class MYSub0(cd: ClockDomain) extends Component {
  val io = new Bundle{
    val ai = in UInt(8 bits)
    val ao = out UInt(8 bits)
  }
  io.ao := RegNext(io.ai) init(0)
}
class MYSub1(cd: ClockDomain) extends Component {
  val io = new Bundle{
    val ai = in UInt(8 bits)
    val ao = out UInt(8 bits)
    val a2 = out UInt(8 bits)
  } 
  io.ao := RegNext(io.ai) init(0)
  val cd2 = ClockDomain.external("adc")
  //alow another clockDomain not confict to default clockdomain 
  val area = new ClockingArea(cd2){
    val tmp = RegNext(io.ai) init(0)
    val tmp2 = tmp + (RegNext(io.ai) init(0))
  } 
  io.a2 := area.tmp2
}     
class Top00 extends Component {
  val io = new Bundle{
    val a = in UInt(8 bits)
    val b0 = out UInt(8 bits)
    val b1 = out UInt(8 bits)
    val b2 = out UInt(8 bits)
  }
  val cd0 = ClockDomain.external("cp")
  val cd1 = ClockDomain.external("ap")

  val u_sub0 = cd0(new MYSub0(cd0)) // set u_sub0's default clockDomain with cd0
  val u_sub1 = cd1(new MYSub1(cd1)) // it allow anoter clockDomain in ther module

  u_sub0.io.ai := io.a
  u_sub1.io.ai := io.a

  io.b0 := u_sub0.io.ao
  io.b1 := u_sub1.io.ao
  io.b2 := u_sub1.io.a2

  val tmp = RegNext(io.a) init(0)
}
showRtl(new Top00)

class TopLevel extends Component {
  val specialReset = in Bool()

  // The reset of this area is done with the specialReset signal
  val areaRst_1 = new ResetArea(specialReset, false){
    val counter = out(CounterFreeRun(16).value)
  }

  // The reset of this area is a combination between the current reset and the specialReset
  val areaRst_2 = new ResetArea(specialReset, true){
    val counter = out(CounterFreeRun(16).value)
  }
}
showRtl(new TopLevel)

class TopLevel extends Component {
  val clockEnable = True

  // Add a clock enable for this area
  val area_1 = new ClockEnableArea(clockEnable){
    val counter = out(CounterFreeRun(16).value)
  }
}
showRtl(new TopLevel)

class gate_cell extends Component{
  val io = new {
    val TSE,CLK,E = in Bool
    val ECK = out Bool        
  }
  noIoPrefix()
  
  val clk_n = !io.CLK
  val lock_en = Bool.noCombLoopCheck
  when (clk_n) {
      lock_en := io.E
  }.otherwise {
      lock_en := lock_en
  }
  io.ECK := lock_en && io.CLK
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
class A extends Component{
  val clk,rstn,E,TSE = in Bool
  val clk_cg = out Bool
  val cd =ClockDomain(clk,rstn)
  clk_cg := clockDomain.gateBy(E, TSE).readClockWire
}
showRtl(new A)

class MySub extends Component {
  val io = new Bundle{
      val a = in UInt(8 bits)
      val b = out UInt(8 bits)
  }
  io.b := RegNext(io.a) init(0)
}
class Top extends Component {
  val io = new Bundle{
      val a0,a1 = in UInt(8 bits)
      val cg_en0,cg_en1 = in Bool
      val b  = out UInt(8 bits)
      val test_mode = in Bool()
  }

  val cgd0 = clockDomain.gateBy(io.cg_en0, io.test_mode)
  val cgd1 = clockDomain.gateBy(io.cg_en1, io.test_mode)

  val u_sub0 = cgd0(new MySub)
  val u_sub1 = cgd1(new MySub)

  u_sub0.io.a := io.a0
  u_sub1.io.a := io.a1 

  io.b := RegNext(u_sub0.io.b + u_sub1.io.b) init 0
}
showRtl(new Top)

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
  if(CommonCellBlackBox.clear){this.clearBlackBox()}
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
}
clearCCBB() //open and try
showRtl(new Top)

// 3.1
class StreamFifo[T <: Data](dataType: T, depth: Int) extends Component {
  val io = new Bundle {
    val push = slave Stream (dataType)
    val pop = master Stream (dataType)
  }
  io.pop </< io.push
  // io.pop <-< io.push
}
showRtl(new StreamFifo(UInt(8 bits), 16))

class StreamArbiter[T <: Data](dataType: T,portCount: Int) extends Component {
  val io = new Bundle {
    val inputs = Vec(slave Stream (dataType), portCount)
    val output = master Stream (dataType)
  }
  io.inputs.map(_.ready := False)

  val oneHotSelecter = OHMasking.roundRobin(
    io.inputs.map(_.valid).asBits,
    B(portCount bits, 0 -> true, default -> false)
  )

  io.output << MuxOH(oneHotSelecter, io.inputs)
}
showRtl(new StreamArbiter(UInt(8 bits), 5))

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
showRtl(new Top)

import spinal.lib._
class StreamFifo[T <: Data](dataType: T, depth: Int) extends Component {
  val io = new Bundle {
    val push = slave Stream (dataType)
    val pop = master Stream (dataType)
  }
  io.pop << io.push.queue(depth)
}
class Top extends Component{
  val streamA,streamB = Stream(Bits(8 bits))
  slave(streamA)
  master(streamB)

  val myFifo = StreamFifo(
    dataType = Bits(8 bits),
    depth    = 128)
 
  myFifo.io.push << streamA
  myFifo.io.pop  >> streamB
}
showRtl(new Top)

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
} 
showRtl(new MyRGB)

class Myflow1 extends Component{
    val source = slave  Flow(RGB(8))
    val sink   = master Flow(RGB(8))
    sink <-< source
}
showRtl(new Myflow1)

class T1 extends Component{
    val a = slave Flow(UInt(8 bits) )
    val b = master Flow(UInt())
    val tmp = a.toStream
    b := tmp.toFlow
}
showRtl(new T1)

class T1 extends Component{
    val a = slave Stream(UInt(8 bits))
    val b = master Flow(UInt(8 bits) ) 
    b << a.toFlow
}
showRtl(new T1)

case class FilterConfig(iqWidth: Int, 
                        tapNumbers: Int = 33,
                        hwFreq: HertzNumber = 200 MHz, 
                        sampleFreq: HertzNumber = 1.92 MHz)
// case class IQ(width: Int) extends Bundle{
//   val I,Q = SInt(width bits)
// }
class Filter(fc: FilterConfig) extends Component{
  // val din   = slave Flow(IQ(fc.iqWidth))
  // val dout  = master Flow(IQ(fc.iqWidth))
  val din   = slave Flow(Bits(32 bits))
  val dout  = master Flow(Bits(32 bits))
  val flush = in Bool
    
  val clockSMP = ClockDomain.external("smp")
  val clockHW = ClockDomain.external("hw")
    
  val u_fifo_in = StreamFifoCC(
    dataType = Bits(32 bits), 
    depth = 8,
    pushClock = clockSMP,
    popClock = clockDomain
  )
  u_fifo_in.io.push << din.toStream 
  dout << u_fifo_in.io.pop.toFlow
}
showRtl(new Filter(FilterConfig(8)))

class IQ extends Bundle{
  val I, Q = SInt(8 bits)
}
class Filter extends Component{
    val din = slave Flow(new IQ)    
    val dout = master Stream(new IQ)
    dout << din.toStream.queue(16)
}
showRtl(new Filter)

case class Color(channelWidth: Int) extends Bundle {
  val r,g,b = UInt(channelWidth bits)
}
class T3 extends Component{
  val io = new Bundle{
   val input  = in (Color(8) )
   val output = out(Color(8))
}
    io.output <> io.input
}
showRtl(new T3)

case class Rgb(channelWidth: Int) extends Bundle{
  val r = UInt(channelWidth bits)
  val g = UInt(channelWidth bits)
  val b = UInt(channelWidth bits)
    
  def init(x: Int): Rgb = {
    r init U(x)
    g init U(x)
    b init U(x)
    this
  }
  def clear = {
    this.r := 0
    this.g := 0
    this.b := 0
    this
  }
  // override def clone :Rgb = Rgb.asInstanceOf[this.type]
}
class T3 extends Component{
   val a = slave Flow(Rgb(8))     
   val flush = in Bool()
   val b = master Flow(Rgb(8))

   val retReg = Reg(cloneOf(a.payload)) init 0
   when(flush){
      retReg.clear
   }.otherwise{
      retReg := a.payload
   }
   b.payload := retReg
   b.valid := True
}
showRtl(new T3)

class Top extends Component{
  // val a = slave  Stream(UInt( 8 bits)) 
  // val b = master Stream(UInt(8 bits))
  //     b := a.queue(4)
  Stream(UInt(8 bits)).queue(4)
}
showRtl(new Top)

class Top extends Component{
  val addr = in UInt(5 bits)
  val b = out UInt(8 bits)
  
  val ram = Mem(UInt(8 bits),32)
  
  b := ram.readAsync(addr)
  //b := ram.readSync(addr) 
}
showRtl(new Top)

class Top extends Component{
  val a = slave Flow(Fragment(UInt(8 bits)))
  val b = out UInt()
  val c = out UInt()
  val d = out Bool()
  b := a.payload.fragment  //
  c := a.fragment          // can be omitted
  d := a.payload.last
}
showRtl(new Top)

case class wrPort[T <: Data](val payloadType: HardType[T]) extends Bundle with IMasterSlave {
  val wr    = Bool()
  val waddr = UInt(8 bits)
  val wdata: T = payloadType()
  override def asMaster(): Unit = out(this)
  override def clone: wrPort[T] = wrPort(payloadType).asInstanceOf[this.type]
}
class Top extends Component{
  val io = new Bundle {
    val input = slave(wrPort(Vec(SInt(8 bits), 4)))
    val output = master(wrPort(Vec(SInt(8 bits), 4)))
  }
  io.output <> io.input
}
showRtl(new Top)

// 3.2
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc._
class Top extends Component{
  val apbConfig = Apb3Config(
    addressWidth = 12,
    dataWidth    = 32,
    selWidth     = 2)
  val a = slave(Apb3(apbConfig))
  val b = master(Apb3(apbConfig))
  b << a
}
showRtl(new Top)

class Top extends Component{
  val apb = slave(Apb3(Apb3Config(8,32,2)))

  val slv = Apb3SlaveFactory(apb,1)  
  val regs = Vec(Reg(UInt(32 bits)) init(0), 8)
  (0 until 8).map(i => slv.readAndWrite(regs(i), address= i * 4 ))
}
showRtl(new Top)

class Top extends Component{
  val apb = slave(Apb3(Apb3Config(8,32,2)))
  val inStream = slave(Stream(UInt(32 bits)))
  val outFlow = master(Flow(UInt(16 bits)))

  val slv = Apb3SlaveFactory(apb,1)  
  val regs = Vec(Reg(UInt(32 bits)) init(0), 8)
  (0 until 8).map(i => slv.drive(regs(i), address = i * 4 ))

  slv.driveFlow(outFlow, address = 64)
  slv.readStreamNonBlocking(inStream, address = 96)
}
showRtl(new Top)

showRtl(new Apb3Decoder(inputConfig = Apb3Config(16,32),
                        decodings = List((0x00000,64),(0x10000,64))))
showRtl(new Apb3Decoder(Apb3Config(16,32),List((0x00,20),
                                               (0x1000,1 KiB),
                                               (0x2000,1 KiB))))
// Router is like selector based on PSEL
showRtl(new Apb3Router(Apb3Config(16,32,3)))

import spinal.lib.bus.amba3.apb._
class Top extends Component{    
  val din  =  slave(Apb3(Apb3Config(16,32)))
  val do1  = master(Apb3(Apb3Config( 8,32)))
  val do2  = master(Apb3(Apb3Config(12,32)))    
  val do3  = master(Apb3(Apb3Config(12,32)))      
  val do4  = master(Apb3(Apb3Config( 2,32)))
  // Apb3Decoder + Apb3Router
  val mux = Apb3Decoder(master = din, 
                        slaves = List(do1 ->  (0x0000,  64 ),
                                      do2 ->  (0x1000,1 KiB),                                   
                                      do3 ->  (0x2000,2 KiB),                                   
                                      do4 ->  (0x3000,  32 )))
}
showRtl(new Top)

import spinal.lib.bus.amba3.ahblite._
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
showRtl(new Top)

import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.amba3.ahblite._
class Top(ahbConfig:AhbLite3Config, apbConfig:Apb3Config) extends Component{
    val ahb = slave(AhbLite3(ahbConfig))
    val apb = master(Apb3(apbConfig))
    val bridge = AhbLite3ToApb3Bridge(ahbConfig,apbConfig)
    ahb >> bridge.io.ahb
    apb << bridge.io.apb
}

showRtl(new Top(AhbLite3Config(16,32),Apb3Config(16,32)))

import spinal.lib.bus.amba4.axi._ 
showRtl(Axi4SharedDecoder(
  axiConfig = Axi4Config(16,32,4),
  readDecodings = List((0x0000, 64    ),
                       (0x1000, 1 KiB ),
                       (0x2000, 3 KiB )),
  writeDecodings = List((0x3000, 3 KiB ),
                        (0x4000, 3 KiB )), 
  sharedDecodings = List((0x5000, 2 KiB),
                         (0x6000, 1 KiB) )
))

import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.amba4.axi._
class Top(aw: Int,dw: Int,iw: Int) extends Component{
  val axi = slave(Axi4Shared(Axi4Config(addressWidth=aw, dataWidth=dw, idWidth=iw)))
  val apb = master(Apb3(Apb3Config(addressWidth=aw, dataWidth=dw,selWidth=1)))//
  val bridge = Axi4SharedToApb3Bridge(addressWidth=aw, dataWidth=dw, idWidth=iw)
  axi >> bridge.io.axi
  apb << bridge.io.apb
}
showRtl(new Top(20,32,16))

import spinal.lib.bus.bram._
//showRtl(new BRAMDecoder(BRAMConfig(32,16),List((0x00,20),(0x1000,1 MiB))))
class Top extends Component{    
    val din  = slave(BRAM(BRAMConfig(dataWidth=32, addressWidth=16)))
    val do1  = master(BRAM(BRAMConfig(32, 8)))
    val do2  = master(BRAM(BRAMConfig(32,12)))    
    val do3  = master(BRAM(BRAMConfig(32,12)))      
    val do4  = master(BRAM(BRAMConfig(32,2)))
    val brammux = BRAMDecoder(master = din,
                              slaves = List(do1 ->  (0x00,  4 KiB ),
                                          do2 ->  (0x1000,3 MiB),                                   
                                          do3 ->  (0x2000,2 MiB),                                   
                                          do4 ->  (0x3000,20 KiB)))  
}
showRtl(new Top)

import spinal.lib.bus.bram._
//showRtl(new BRAMDecoder(BRAMConfig(32,16),List((0x00,20),(0x1000,1 MiB))))
class Top(w: Int) extends Component{    
    val din  = slave(BRAM(BRAMConfig(w,12)))
    val do1  = master(BRAM(BRAMConfig(w,10)))
    val do2  = master(BRAM(BRAMConfig(w,10))) 
    
val brammux = BRAMDecoder(master = din,
                          slaves = List(do1 ->  (0x00000,1 KiB),
                                        do2 ->  (0x10000,3 KiB))) 
}
showRtl(new Top(8))

// 3.3
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.regif._
class RegBankExample extends Component{
  val io = new Bundle{
    val apb = slave(Apb3(Apb3Config(16,32)))
  }
  val busSlave = BusInterface(io.apb,(0x0000, 100 Byte), 0)
  val M_REG0  = busSlave.newReg(doc="REG0")
  val M_REG1  = busSlave.newReg(doc="REG1")
  val M_REG2  = busSlave.newReg(doc="REG2")
  val M_REGn  = busSlave.newRegAt(address=0x40, doc="REGn")
  val M_REGn1 = busSlave.newReg(doc="REGn1")
}
showRtl(new RegBankExample)

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
  val fd1 = M_REG0.field(3 bits, RW, doc= "fields 0")
  val fd2 = M_REG0.field(3 bits, RW, doc= "fields 0")
  //auto reserved 2 bits
  val fd3 = M_REG0.fieldAt(pos=16, 4 bits, RC, doc= "fields 3")
  //auto reserved 12 bits
}
showRtl(new RegBankExample)

import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.regif._
import spinal.lib.bus.regif.AccessType._
class RegBankExample extends Component{
  val io = new Bundle{
    val apb = slave(Apb3(Apb3Config(16,32)))
  }
  val busSlave = BusInterface(io.apb,(0x0000, 100 Byte), 0)
  val M_REG1  = busSlave.newReg(doc="REG1")
  val r1fd0 = M_REG1.field(16 bits, RW, doc="fields 0")
  val r1fd2 = M_REG1.field(16 bits, RW, doc="fields 1")
}
showRtl(new RegBankExample)

import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.regif._
import spinal.lib.bus.regif.AccessType._
class RegBankExample extends Component{
  val io = new Bundle{
    val apb = slave(Apb3(Apb3Config(16,32)))
  }
  val busSlave = BusInterface(io.apb,(0x0000, 100 Byte),0 )
  val M_REG1  = busSlave.newReg(doc="REG1")
  val r1fd0 = M_REG1.field(16 bits, RW, doc="fields 0")
  val r1fd2 = M_REG1.fieldAt(pos = 16, 2 bits, RW, doc="fields 1")
}
showRtl(new RegBankExample)

// You can find this is a very tedious and repetitive work,
// a better way is creat a Factory fucntion by Macros auto complet those work instead manully creat them.
class cpInterruptExample extends Component {
  val io = new Bundle {
    val tx_done, rx_done, frame_end = in Bool()
    val interrupt = out Bool()
    val apb = slave(Apb3(Apb3Config(16, 32)))
  }
  val busif = Apb3BusInterface(io.apb, (0x000, 100 Byte))

  val M_CP_INT_EN    = busif.newReg(doc="cp int enable register")
  val tx_int_en      = M_CP_INT_EN.field(1 bits, RW, doc="tx interrupt enable register")
  val rx_int_en      = M_CP_INT_EN.field(1 bits, RW, doc="rx interrupt enable register")
  val frame_int_en   = M_CP_INT_EN.field(1 bits, RW, doc="frame interrupt enable register")
  val M_CP_INT_MASK  = busif.newReg(doc="cp int mask register")
  val tx_int_mask      = M_CP_INT_MASK.field(1 bits, RW, doc="tx interrupt mask register")
  val rx_int_mask      = M_CP_INT_MASK.field(1 bits, RW, doc="rx interrupt mask register")
  val frame_int_mask   = M_CP_INT_MASK.field(1 bits, RW, doc="frame interrupt mask register")
  val M_CP_INT_STATE   = busif.newReg(doc="cp int state register")
  val tx_int_state      = M_CP_INT_STATE.field(1 bits, RW, doc="tx interrupt state register")
  val rx_int_state      = M_CP_INT_STATE.field(1 bits, RW, doc="rx interrupt state register")
  val frame_int_state   = M_CP_INT_STATE.field(1 bits, RW, doc="frame interrupt state register")

  when(io.rx_done && rx_int_en(0)){tx_int_state(0).set()}
  when(io.tx_done && tx_int_en(0)){tx_int_state(0).set()}
  when(io.frame_end && frame_int_en(0)){tx_int_state(0).set()}

  io.interrupt := (tx_int_mask(0) && tx_int_state(0)  ||
    rx_int_mask(0) && rx_int_state(0) ||
    frame_int_mask(0) && frame_int_state(0))
}
showRtl(new cpInterruptExample)

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
showRtl(new cpInterruptFactoryExample)

// 5.2
class T2  extends Component{
  val a,b = in UInt(8 bits)
  val clc = in Bool()
  val c = out UInt() 
  // when(clc){ c.setAll }.otherwise(c := a * b)  //failed   
  when(!clc){c := a * b }.otherwise(c.setAll)  //It's OK
}
showRtl(new T2)

class T1  extends Component{  
  val sel = in Bool()
  val a = Reg(Bits(1 bits)) init 0 
  when(sel){a.asBool.set()} //generate verilog beyond your expectations
  when(sel){a.asBool.clear()} //generate verilog beyond your expectations
}
showRtl(new T1)

class T2  extends Component{  
  val sel = in Bool()
  val a = Reg(Bits(1 bits)) init 0 
  when(sel){a(0).set()} 
  // when(sel){a.lsb.set()}  //also Ok
}
showRtl(new T2)

import scala.collection.immutable.List
class T2 extends Component{
  val a =  in UInt(2 bits)
  val Lut = List.fill(8)(UInt(8 bits))
  (0 to 7).foreach{ i =>      
    Lut(i) := i        
  }
  switch(a){
    is(0){
        Lut(0) := 3
        Lut(2) := 4
    }
    is(1){
        Lut(3) := 3
        Lut(4) := 4
    }
    is(2){
        Lut(3) := 3
        Lut(4) := 4
    } 
    default{
      (0 to 7).foreach{
        i => Lut(i) := i        
      }
    }
  }
}
showRtl(new T2)

trait PRNBase {
  val size: Int 

  val Mask = (1 << size) - 1    // attation, field 
  val Msb  = (1 << (size - 1))  // attation, field
}
object GPS extends PRNBase{
    val size = 1023
}
object BD extends PRNBase{
    val size = 2046
}
BD.Mask toHexString // return 0

trait PRNBase {
  val size: Int 

  def Mask = (1 << size) - 1   // method
  def Msb  = (1 << (size - 1)) // method
}
object BD extends PRNBase{
    val size = 11
}
BD.Mask toHexString

// double definition, not work
object MyTransform{
  def apply(x: Int ): Double              = x + 0.00 
  def apply(x: List[Int] ): List[Double]  = x.map(_+0.00)
  def apply(x: List[Double] ): List[Double] = x.map(_+0.00)
}

case class IntList(list: List[Int])
case class DoubleList(list: List[Double])
implicit def Il(list: List[Int]) = IntList(list)
implicit def Dl(list: List[Double]) = DoubleList(list)
object FixTo{
  def apply(x: Int ): Double              = x + 0.00 
  def apply(x: IntList ): List[Double]    = x.list.map(_+0.00)
  def apply(x: DoubleList ): List[Double] = x.list.map(_+0.00)
}

class T2  extends Component{ 
   class Dog{
      def genTimer(n: Int) = {
         val timer = Reg(UInt(n bits)) init 0 
         val clearTimer = in Bool()
         when(clearTimer){
            timer init 0
         }.otherwise {
            timer := timer + 1
         }
         (clearTimer,timer)
      }
   }
   val xiaogou = new Dog
   val (weigou,timer) = xiaogou.genTimer(8)
} 
showRtl(new T2)

class Dog {
  def genTimer(n: Int) = {
    val timer = Reg(UInt(n bits)) init 0 
    val clearTimer = in Bool()
    when(clearTimer){
      timer init 0
    }.otherwise {
      timer := timer + 1
    }
    (clearTimer,timer)
  }
}
class T2  extends Component{ 
   val xiaogou =  new Dog
   val (weigou,timer) = xiaogou.genTimer(8)
} 
showRtl(new T2)
class T3  extends Component{  
   val (weigou,timer) = (new Dog).genTimer(8)
} 
showRtl(new T3)

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
println((100.21 MHz).toString0)
println(HertzNumber(800010).toString0)

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

// 5.3
class T1 extends Component{
  val a,b  = in UInt(2 bits)
  val c = RegNext(a)
  val d = RegNext(c*b)
  val e = RegNext(d)
  val f = e + b
    
  println(s"latency(a,c)=${LatencyAnalysis(a,c)}")
  println(s"latency(a,d)=${LatencyAnalysis(a,d)}")
  println(s"latency(a,e)=${LatencyAnalysis(a,e)}")
  println(s"latency(a,f)=${LatencyAnalysis(a,f)}")    
}
showRtl(new T1)

class OneHot(w: Int) extends Component{
  val bits   = in Bits(w bits)
  val int0   = out(OHToUInt(bits))
  val int1   = out(OHMasking.first(bits))
  val int2   = out(OHMasking.last(bits))
  val int3   = out(OHToUInt(OHMasking.first(bits)))
  val int4   = out(OHToUInt(OHMasking.last(bits)))
  val int5   = ~int3
  val int6   = U(w-1) - int3
}
showRtl(new OneHot(8))