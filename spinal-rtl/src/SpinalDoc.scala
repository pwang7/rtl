/// VHDL comparison

// Process
val mySignal = Bool
val myRegister = Reg(UInt(4 bits))
val myRegisterWithReset = Reg(UInt(4 bits)) init(0)
mySignal := False
when(cond) {
  mySignal := True
  myRegister := myRegister + 1
  myRegisterWithReset := myRegisterWithReset + 1
}

// Clock domains
val coreClockDomain = ClockDomain(
  clock = io.coreClk,
  reset = io.coreReset,
  config = ClockDomainConfig(
    clockEdge = RISING,
    resetKind = ASYNC,
    resetActiveLevel = HIGH
  )
)
val coreArea = new ClockingArea(coreClockDomain) {
  val myCoreClockedRegister = Reg(UInt(4 bit))
  // ...
  // coreClockDomain will also be applied to all sub components instantiated in the Area
  // ...
}

// Area
val timeout = new Area {
  val counter = Reg(UInt(8 bits)) init(0)
  val overflow = False
  when(counter =/= 100) {
    counter := counter + 1
  } otherwise {
    overflow := True
  }
}
val core = new Area {
  when(timeout.overflow) {
    timeout.counter := 0
  }
}

// Function
def simpleAluPipeline(op: Bits, a: UInt, b: UInt): UInt = {
  val result = UInt(8 bits)

  switch(op) {
    is(0){ result := a + b }
    is(1){ result := a - b }
    is(2){ result := a * b }
  }

  return RegNext(result)
}

// Stream queue
class Stream[T <: Data](dataType:  T) extends Bundle with IMasterSlave with DataCarrier[T] {
  val valid = Bool
  val ready = Bool
  val payload = cloneOf(dataType)

  def queue(size: Int): Stream[T] = {
    val fifo = new StreamFifo(dataType, size)
    fifo.io.push <> this
    fifo.io.pop
  }
}

// Function assigns a signal defined outside of itself:
val counter = Reg(UInt(8 bits)) init(0)
counter := counter + 1
def clear() : Unit = {
  counter := 0
}
when(counter > 42) {
  clear()
}

// Bus
val apb = slave(Apb3(addressWidth, dataWidth))

// Configuration objects
val coreConfig = CoreConfig(
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
// The CPU has a system of plugins which allows adding new features into the core.
// Those extensions are not directly implemented in the core, but are kind of an additive logic patch defined in a separate area.
coreConfig.add(new MulExtension)
coreConfig.add(new DivExtension)
coreConfig.add(new BarrelShifterFullExtension)
val iCacheConfig = InstructionCacheConfig(
  cacheSize = 4096,
  bytePerLine = 32,
  wayCount = 1,  // Can only be one for the moment
  wrappedMemAccess = true,
  addressWidth = 32,
  cpuDataWidth = 32,
  memDataWidth = 32
)
new RiscvCoreAxi4(
  coreConfig = coreConfig,
  iCacheConfig = iCacheConfig,
  dCacheConfig = null,
  debug = debug,
  interruptCount = interruptCount
)

// Signal declaration
val a = Bool
a := x & y
val a = x & y

// Component instantiation
val divider = new UnsignedDivider()
// And then if you want to access IO signals of that divider:
divider.io.cmd.valid := True
divider.io.cmd.numerator := 42

// Casting
// boolean/std_logic:
val value = UInt(8 bits)
val valueBiggerThanTwo = Bool
valueBiggerThanTwo := value > 2  // value > 2 return a Bool
// unsigned/integer:
val array = Vec(UInt(4 bits),8)
val sel = UInt(3 bits)
val arraySel = array(sel) // Vec is indexed directly by using UInt

// Resizing
// The traditional way
my8BitsSignal := my4BitsSignal.resize(8)
// The smart way
my8BitsSignal := my4BitsSignal.resized

// Parameterization
// Here is an example of parameterized data structures:
val colorStream = Stream(Color(5, 6, 5)))
val colorFifo   = StreamFifo(Color(5, 6, 5), depth = 128)
colorFifo.io.push <> colorStream
// Here is an example of a parameterized component:
class Arbiter[T <: Data](payloadType: T, portCount: Int) extends Component {
  val io = new Bundle {
    val sources = Vec(slave(Stream(payloadType)), portCount)
    val sink = master(Stream(payloadType))
  }
  // ...
}

/// VHDL equivalences

// Entity and architecture
case class MyComponent(offset: Int) extends Component {
  val io = new Bundle{
    val a, b, c = in UInt(8 bits)
    val result  = out UInt(8 bits)
  }
  io.result := a + b + c + offset
}
case class TopLevel extends Component {
  ...
  val mySubComponent = MyComponent(offset = 5)
  ...
  mySubComponent.io.a := 1
  mySubComponent.io.b := 2
  mySubComponent.io.c := 3
  ??? := mySubComponent.io.result
  ...
}

// Data types
case class RGB(channelWidth: Int) extends Bundle {
  val r, g, b = UInt(channelWidth bits)
}

// Signal
case class MyComponent(offset: Int) extends Component {
  val io = new Bundle {
    val a, b, c = UInt(8 bits)
    val result  = UInt(8 bits)
  }
  val ab = UInt(8 bits)
  ab := a + b

  val abc = ab + c            // You can define a signal directly with its value
  io.result := abc + offset
}

// Assignments
// In SpinalHDL, the := assignment operator is equivalent to the VHDL signal assignment (<=):
val myUInt = UInt(8 bits)
myUInt := 6
// Conditional assignments are done like in VHDL by using if/case statements:
val clear   = Bool
val counter = Reg(UInt(8 bits))
when(clear) {
  counter := 0
}.elsewhen(counter === 76) {
  counter := 79
}.otherwise {
  counter(7) := ! counter(7)
}
switch(counter) {
  is(42) {
    counter := 65
  }
  default {
    counter := counter + 1
  }
}

// Literals
val myBool = Bool
myBool := False
myBool := True
myBool := Bool(4 > 7)
val myUInt = UInt(8 bits)
myUInt := "0001_1100"
myUInt := "xEE"
myUInt := 42
myUInt := U(54,8 bits)
myUInt := ((3 downto 0) -> myBool, default -> true)
when(myUInt === U(myUInt.range -> true)) {
  myUInt(3) := False
}

// Registers
// init(0) means that the register should be initialized to zero when a reset occurs
val counter = Reg(UInt(8 bits))  init(0)
counter := counter + 1   // Count up each cycle
val cond = Bool
val myCombinatorial = Bool
val myRegister = UInt(8 bits)
myCombinatorial := False
when(cond) {
  myCombinatorial := True
  myRegister = myRegister + 1
}

/// Bool

// Declaration
val myBool_1 = Bool          // Create a Bool
myBool_1 := False            // := is the assignment operator
val myBool_2 = False         // Equivalent to the code above
val myBool_3 = Bool(5 > 12)  // Use a Scala Boolean to create a Bool

// Logic
val a, b, c = Bool
val res = (!a & b) ^ c   // ((NOT a) AND b) XOR c
val d = False
when(cond) {
  d.set()    // equivalent to d := True
}
val e = False
e.setWhen(cond) // equivalent to when(cond) { d := True }

// Edge detection
when(myBool_1.rise(False)) {
    // do something when a rising edge is detected
}
val edgeBundle = myBool_2.edges(False)
when(edgeBundle.rise) {
    // do something when a rising edge is detected
}
when(edgeBundle.fall) {
    // do something when a falling edge is detected
}
when(edgeBundle.toggle) {
    // do something at each edge
}

// Comparison
when(myBool) { // Equivalent to when(myBool === True)
    // do something when myBool is True
}
when(!myBool) { // Equivalent to when(myBool === False)
    // do something when myBool is False
}

// Type cast
// Add the carry to an SInt value
val carry = Bool
val res = mySInt + carry.asSInt(4 bits)

// Concatenation
val a, b, c = Bool
// Concatenation of three Bool into a Bits
val myBits = a ## b ## c

/// Bits
val myBits  = Bits(8 bits)
val itMatch = myBits === M"00--10--" // - don't care value

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
val myBits6 = B(8 bits, (7 downto 5) -> B"101", 4 -> true, 3 -> True, default -> false) // "10111000"
val myBits7 = Bits(8 bits)
myBits7 := (7 -> true, default -> false) // "10000000" (For assignment purposes, you can omit the B)

// Logic
// Bitwise operator
val a, b, c = Bits(32 bits)
c := ~(a & b) // Inverse(a AND b)
val all_1 = a.andR // Check that all bits are equal to 1
// Logical shift
val bits_10bits = bits_8bits << 2  // shift left (results in 10 bits)
val shift_8bits = bits_8bits |<< 2 // shift left (results in 8 bits)
// Logical rotation
val myBits = bits_8bits.rotateLeft(3) // left bit rotation
// Set/clear
val a = B"8'x42"
when(cond) {
  a.setAll() // set all bits to True when cond is True
}

// Comparison
when(myBits === 3) {
}
when(myBits_32 =/= B"32'x44332211") {
}

// Type cast
// cast a Bits to SInt
val mySInt = myBits.asSInt
// create a Vector of bool
val myVec = myBits.asBools
// Cast a SInt to Bits
val myBits = B(mySInt)

// Bit extraction
// get the element at the index 4
val myBool = myBits(4)
// assign
myBits(1) := True
// Range
val myBits_8bits = myBits_16bits(7 downto 0)
val myBits_7bits = myBits_16bits(0 to 6)
val myBits_6bits = myBits_16Bits(0 until 6)
myBits_8bits(3 downto 0) := myBits_4bits

// Misc
println(myBits_32bits.getWidth) // 32
myBool := myBits.lsb  // Equivalent to myBits(0)
// Concatenation
myBits_24bits := bits_8bits_1 ## bits_8bits_2 ## bits_8bits_3
// Subdivide
val sel = UInt(2 bits)
val myBitsWord = myBits_128bits.subdivideIn(32 bits)(sel)
    // sel = 0 => myBitsWord = myBits_128bits(127 downto 96)
    // sel = 1 => myBitsWord = myBits_128bits( 95 downto 64)
    // sel = 2 => myBitsWord = myBits_128bits( 63 downto 32)
    // sel = 3 => myBitsWord = myBits_128bits( 31 downto  0)
// If you want to access in reverse order you can do:
val myVector   = myBits_128bits.subdivideIn(32 bits).reverse
val myBitsWord = myVector(sel)
// Resize
myBits_32bits := B"32'x112233344"
myBits_8bits  := myBits_32bits.resized       // automatic resize (myBits_8bits = 0x44)
myBits_8bits  := myBits_32bits.resize(8)     // resize to 8 bits (myBits_8bits = 0x44)
myBits_8bits  := myBits_32bits.resizeLeft(8) // resize to 8 bits (myBits_8bits = 0x11)

/// UInt/SInt

// Declaration
val myUInt = UInt(8 bits)
myUInt := U(2,8 bits)
myUInt := U(2)
myUInt := U"0000_0101"  // Base per default is binary => 5
myUInt := U"h1A"        // Base could be x (base 16)
                        //               h (base 16)
                        //               d (base 10)
                        //               o (base 8)
                        //               b (base 2)
myUInt := U"8'h1A"
myUInt := 2             // You can use a Scala Int as a literal value
val myBool := myUInt === U(7 -> true,(6 downto 0) -> false)
val myBool := myUInt === U(myUInt.range -> true)
// For assignment purposes, you can omit the U/S, which also allows the use of the [default -> ???] feature
myUInt := (default -> true)                        // Assign myUInt with "11111111"
myUInt := (myUInt.range -> true)                   // Assign myUInt with "11111111"
myUInt := (7 -> true, default -> false)            // Assign myUInt with "10000000"
myUInt := ((4 downto 1) -> true, default -> false) // Assign myUInt with "00011110"

// Operators
// Bitwise operator
val a, b, c = SInt(32 bits)
c := ~(a & b) // Inverse(a AND b)
val all_1 = a.andR // Check that all bits are equal to 1
// Logical shift
val uint_10bits = uint_8bits << 2  // shift left (resulting in 10 bits)
val shift_8bits = uint_8bits |<< 2 // shift left (resulting in 8 bits)
// Logical rotation
val myBits = uint_8bits.rotateLeft(3) // left bit rotation
// Set/clear
val a = B"8'x42"
when(cond) {
  a.setAll() // set all bits to True when cond is True
}

// Arithmetic
// Addition
val res = mySInt_1 + mySInt_2

// Comparison
// Comparison between two SInts
myBool := mySInt_1 > mySInt_2
// Comparison between a UInt and a literal
myBool := myUInt_8bits >= U(3, 8 bits)
when(myUInt_8bits === 3) {
  ..
}

// Type cast
// Cast an SInt to Bits
val myBits = mySInt.asBits
// Create a Vector of Bool
val myVec = myUInt.asBools
// Cast a Bits to SInt
val mySInt = S(myBits)

// Bit extraction
// get the bit at index 4
val myBool = myUInt(4)
// assign bit 1 to True
mySInt(1) := True
// Range
val myUInt_8bits = myUInt_16bits(7 downto 0)
val myUInt_7bits = myUInt_16bits(0 to 6)
val myUInt_6bits = myUInt_16Bits(0 until 6)
mySInt_8bits(3 downto 0) := mySInt_4bits

// Misc
myBool := mySInt.lsb  // equivalent to mySInt(0)
// Concatenation
val mySInt = mySInt_1 @@ mySInt_1 @@ myBool
val myBits = mySInt_1 ## mySInt_1 ## myBool
// Subdivide
val sel = UInt(2 bits)
val mySIntWord = mySInt_128bits.subdivideIn(32 bits)(sel)
    // sel = 0 => mySIntWord = mySInt_128bits(127 downto 96)
    // sel = 1 => mySIntWord = mySInt_128bits( 95 downto 64)
    // sel = 2 => mySIntWord = mySInt_128bits( 63 downto 32)
    // sel = 3 => mySIntWord = mySInt_128bits( 31 downto  0)
// If you want to access in reverse order you can do:
val myVector   = mySInt_128bits.subdivideIn(32 bits).reverse
val mySIntWord = myVector(sel)
// Resize
myUInt_32bits := U"32'x112233344"
myUInt_8bits  := myUInt_32bits.resized       // automatic resize (myUInt_8bits = 0x44)
myUInt_8bits  := myUInt_32bits.resize(8)     // resize to 8 bits (myUInt_8bits = 0x44)
// Two's complement
mySInt := myUInt.twoComplement(myBool)
// Absolute value
mySInt_abs := mySInt.abs

// FixPoint operations
// Lower bit operations
val A  = SInt(16 bit)
val B  = A.roundToInf(6 bits) // default 'align = false' with carry, got 11 bit
val B  = A.roundToInf(6 bits, align = true) // sat 1 carry bit, got 10 bit
val B  = A.floor(6 bits)             // return 10 bit
val B  = A.floorToZero(6 bits)       // return 10 bit
val B  = A.ceil(6 bits)              // ceil with carry so return 11 bit
val B  = A.ceil(6 bits, align = true) // ceil with carry then sat 1 bit return 10 bit
val B  = A.ceilToInf(6 bits)
val B  = A.roundUp(6 bits)
val B  = A.roundDown(6 bits)
val B  = A.roundToInf(6 bits)
val B  = A.roundToZero(6 bits)
val B  = A.round(6 bits)             // SpinalHDL uses roundToInf as the default rounding mode
val B0 = A.roundToInf(6 bits, align = true)         //  ---+
val B1 = A.roundToInf(6 bits, align = false).sat(1) //  ---+
// High bit operations
val A  = SInt(8 bit)
val B  = A.sat(3 bits)      // return 5 bits with saturated highest 3 bits
val B  = A.sat(3)           // equal to sat(3 bits)
val B  = A.trim(3 bits)     // return 5 bits with the highest 3 bits discarded
val B  = A.trim(3 bits)     // return 5 bits with the highest 3 bits discarded
val C  = A.symmetry         // return 8 bits and symmetry as (-128~127 to -127~127)
val C  = A.sat(3).symmetry  // return 5 bits and symmetry as (-16~15 to -15~15)
// fixTo function
val A  = SInt(16 bit)
val B  = A.fixTo(10 downto 3) // default RoundType.ROUNDTOINF, sym = false
val B  = A.fixTo( 8 downto 0, RoundType.ROUNDUP)
val B  = A.fixTo( 9 downto 3, RoundType.CEIL,       sym = false)
val B  = A.fixTo(16 downto 1, RoundType.ROUNDTOINF, sym = true )
val B  = A.fixTo(10 downto 3, RoundType.FLOOR) // floor 3 bit, sat 5 bit @ highest
val B  = A.fixTo(20 downto 3, RoundType.FLOOR) // floor 3 bit, expand 2 bit @ highest

/// SpinalEnum

// Declaration
object Enumeration extends SpinalEnum {
  val element0, element1, ..., elementN = newElement()
}
// encodingOfYourChoice: native/binarySequential/binaryOneHot
object Enumeration extends SpinalEnum(defaultEncoding=encodingOfYourChoice) {
  val element0, element1, ..., elementN = newElement()
}

// Static encoding
object MyEnumStatic extends SpinalEnum {
  val e0, e1, e2, e3 = newElement()
  defaultEncoding = SpinalEnumEncoding("staticEncoding")(
    e0 -> 0,
    e1 -> 2,
    e2 -> 3,
    e3 -> 7)
}
/*
 * Dynamic encoding with the function :  _ * 2 + 1
 *   e.g. : e0 => 0 * 2 + 1 = 1
 *          e1 => 1 * 2 + 1 = 3
 *          e2 => 2 * 2 + 1 = 5
 *          e3 => 3 * 2 + 1 = 7
 */
val encoding = SpinalEnumEncoding("dynamicEncoding", _ * 2 + 1)
object MyEnumDynamic extends SpinalEnum(encoding) {
  val e0, e1, e2, e3 = newElement()
}

// Example
object UartCtrlTxState extends SpinalEnum {
  val sIdle, sStart, sData, sParity, sStop = newElement()
}
val stateNext = UartCtrlTxState()
stateNext := UartCtrlTxState.sIdle
// You can also import the enumeration to have visibility of its elements
import UartCtrlTxState._
stateNext := sIdle

// Comparison
import UartCtrlTxState._
val stateNext = UartCtrlTxState()
stateNext := sIdle
when(stateNext === sStart) {
  ...
}
switch(stateNext) {
  is(sIdle) {
    ...
  }
  is(sStart) {
    ...
  }
  ...
}

// Type cast
import UartCtrlTxState._
val stateNext = UartCtrlTxState()
myBits := sIdle.asBits

/// Bundle

// Declaration
case class myBundle extends Bundle {
  val bundleItem0 = AnyType
  val bundleItem1 = AnyType
  val bundleItemN = AnyType
}
case class Color(channelWidth: Int) extends Bundle {
  val r, g, b = UInt(channelWidth bits)
}

// Comparison
val color1 = Color(8)
color1.r := 0
color1.g := 0
color1.b := 0
val color2 = Color(8)
color2.r := 0
color2.g := 0
color2.b := 0
myBool := color1 === color2

// Type cast
val color1 = Color(8)
val myBits := color1.asBits

// in/out
val io = new Bundle {
  val input  = in (Color(8))
  val output = out(Color(8))
}

// master/slave
case class HandShake(payloadWidth: Int) extends Bundle with IMasterSlave {
  val valid   = Bool
  val ready   = Bool
  val payload = Bits(payloadWidth bits)

  // You have to implement this asMaster function.
  // This function should set the direction of each signals from an master point of view
  override def asMaster(): Unit = {
    out(valid, payload)
    in(ready)
  }
}
val io = new Bundle {
  val input  = slave(HandShake(8))
  val output = master(HandShake(8))
}

/// Vec

// Declaration
// Create a vector of 2 signed integers
val myVecOfSInt = Vec(SInt(8 bits), 2)
myVecOfSInt(0) := 2
myVecOfSInt(1) := myVecOfSInt(0) + 3
// Create a vector of 3 different type elements
val myVecOfMixedUInt = Vec(UInt(3 bits), UInt(5 bits), UInt(8 bits))
val x, y, z = UInt(8 bits)
val myVecOf_xyz_ref = Vec(x, y, z)
// Iterate on a vector
for(element <- myVecOf_xyz_ref) {
  element := 0   // Assign x, y, z with the value 0
}
// Map on vector
myVecOfMixedUInt.map(_ := 0) // Assign all elements with value 0
// Assign 3 to the first element of the vector
myVecOf_xyz_ref(1) := 3

// Comparison
// Create a vector of 2 signed integers
val vec2 = Vec(SInt(8 bits), 2)
val vec1 = Vec(SInt(8 bits), 2)
myBool := vec2 === vec1  // Compare all elements

// Type cast
// Create a vector of 2 signed integers
val vec1 = Vec(SInt(8 bits), 2)
myBits_16bits := vec1.asBits

// Misc
// Create a vector of 2 signed integers
val vec1 = Vec(SInt(8 bits), 2)
println(vec1.getBitsWidth) // 16

/// UFix/SFix

// Format
// Unsigned Fixed-Point
val UQ_8_2 = UFix(peak = 8 exp, resolution = -2 exp) // bit width = 8 - (-2) = 10 bits
val UQ_8_2 = UFix(8 exp, -2 exp)
val UQ_8_2 = UFix(peak = 8 exp, width = 10 bits)
val UQ_8_2 = UFix(8 exp, 10 bits)
// Signed Fixed-Point
val Q_8_2 = SFix(peak = 8 exp, resolution = -2 exp) // bit width = 8 - (-2) + 1 = 11 bits
val Q_8_2 = SFix(8 exp, -2 exp)
val Q_8_2 = SFix(peak = 8 exp, width = 11 bits)
val Q_8_2 = SFix(8 exp, 11 bits)

// Valid Assignments
val i16_m2 = SFix(16 exp, -2 exp)
val i16_0  = SFix(16 exp,  0 exp)
val i8_m2  = SFix( 8 exp, -2 exp)
val o16_m2 = SFix(16 exp, -2 exp)
val o16_m0 = SFix(16 exp,  0 exp)
val o14_m2 = SFix(14 exp, -2 exp)
o16_m2 := i16_m2            // OK
o16_m0 := i16_m2            // Not OK, Bit loss
o14_m2 := i16_m2            // Not OK, Bit loss
o16_m0 := i16_m2.truncated  // OK, as it is resized
o14_m2 := i16_m2.truncated  // OK, as it is resized

// From a Scala constant
val i4_m2 = SFix(4 exp, -2 exp)
i4_m2 := 1.25    // Will load 5 in i4_m2.raw
i4_m2 := 4       // Will load 16 in i4_m2.raw

// Raw value
val UQ_8_2 = UFix(8 exp, 10 bits)
UQ_8_2.raw := 4        // Assign the value corresponding to 1.0
UQ_8_2.raw := U(17)    // Assign the value corresponding to 4.25

/// Component and hierarchy

// Introduction
class AdderCell extends Component {
  // Declaring external ports in a Bundle called `io` is recommended
  val io = new Bundle {
    val a, b, cin = in Bool
    val sum, cout = out Bool
  }
  // Do some logic
  io.sum := io.a ^ io.b ^ io.cin
  io.cout := (io.a & io.b) | (io.a & io.cin) | (io.b & io.cin)
}
class Adder(width: Int) extends Component {
  ...
  // Create 2 AdderCell instances
  val cell0 = new AdderCell
  val cell1 = new AdderCell
  cell1.io.cin := cell0.io.cout   // Connect cout of cell0 to cin of cell1

  // Another example which creates an array of ArrayCell instances
  val cellArray = Array.fill(width)(new AdderCell)
  cellArray(1).io.cin := cellArray(0).io.cout   // Connect cout of cell(0) to cin of cell(1)
  ...
}

// Pruned signals, printPrunedIo and printPruned
class TopLevel extends Component {
  val io = new Bundle {
    val a,b = in UInt(8 bits)
    val result = out UInt(8 bits)
  }

  io.result := io.a + io.b

  val unusedSignal = UInt(8 bits)
  val unusedSignal2 = UInt(8 bits)

  unusedSignal2 := unusedSignal
}
object Main {
  def main(args: Array[String]) {
    SpinalVhdl(new TopLevel).printPruned()
    //This will report :
    //  [Warning] Unused wire detected : toplevel/unusedSignal : UInt[8 bits]
    //  [Warning] Unused wire detected : toplevel/unusedSignal2 : UInt[8 bits]
  }
}

// To keep a pruned signal in the generated RTL for debugging reasons, you can use the keep function of that signal:
class TopLevel extends Component {
  val io = new Bundle {
    val a, b = in UInt(8 bits)
    val result = out UInt(8 bits)
  }

  io.result := io.a + io.b

  val unusedSignal = UInt(8 bits)
  val unusedSignal2 = UInt(8 bits).keep()

  unusedSignal  := 0
  unusedSignal2 := unusedSignal
}
object Main {
  def main(args: Array[String]) {
    SpinalVhdl(new TopLevel).printPruned()
    // This will report nothing
  }
}

// Generic
class MyAdder(width: BitCount) extends Component {
  val io = new Bundle {
    val a, b   = in UInt(width)
    val result = out UInt(width)
  }
  io.result := io.a + io.b
}
object Main {
  def main(args: Array[String]) {
    SpinalVhdl(new MyAdder(32 bits))
  }
}
// If you have several parameters, it is a good practice to give a specific configuration class as follows:
case class MySocConfig(axiFrequency  : HertzNumber,
                       onChipRamSize : BigInt,
                       cpu           : RiscCoreConfig,
                       iCache        : InstructionCacheConfig)

class MySoc(config: MySocConfig) extends Component {
  ...
}

/// Area

class UartCtrl extends Component {
  ...
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
    ...
  }
}

/// Function

// RGB to gray
// Input RGB color
val r, g, b = UInt(8 bits)
// Define a function to multiply a UInt by a Scala Float value.
def coef(value: UInt, by: Float): UInt = (value * U((255 * by).toInt, 8 bits) >> 8)
// Calculate the gray level
val gray = coef(r, 0.3f) + coef(g, 0.4f) + coef(b, 0.3f)

// Valid Ready Payload bus
case class MyBus(payloadWidth: Int) extends Bundle with IMasterSlave {
  val valid   = Bool
  val ready   = Bool
  val payload = Bits(payloadWidth bits)

  // Define the direction of the data in a master mode
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

  val mem = Mem(Bits(payloadWidth bits), depth)
  // ...
}

/// Clock domains

// Instantiation
ClockDomain(
  clock: Bool
  [,reset: Bool]
  [,softReset: Bool]
  [,clockEnable: Bool]
  [,frequency: IClockDomainFrequency]
  [,config: ClockDomainConfig]
)
// An applied example to define a specific clock domain within the design is as follows:
val coreClock = Bool
val coreReset = Bool
// Define a new clock domain
val coreClockDomain = ClockDomain(coreClock, coreReset)
// Use this domain in an area of the design
val coreArea = new ClockingArea(coreClockDomain) {
  val coreClockedRegister = Reg(UInt(4 bit))
}

// Configuration
class CustomClockExample extends Component {
  val io = new Bundle {
    val clk    = in Bool
    val resetn = in Bool
    val result = out UInt (4 bits)
  }
  // Configure the clock domain
  val myClockDomain = ClockDomain(
    clock  = io.clk,
    reset  = io.resetn,
    config = ClockDomainConfig(
      clockEdge        = RISING,
      resetKind        = ASYNC,
      resetActiveLevel = LOW
    )
  )
  // Define an Area which use myClockDomain
  val myArea = new ClockingArea(myClockDomain) {
    val myReg = Reg(UInt(4 bits)) init(7)

    myReg := myReg + 1

    io.result := myReg
  }
}
// ClockDomainConfig
val defaultCC = ClockDomainConfig(
  clockEdge        = RISING,
  resetKind        = ASYNC,
  resetActiveLevel = HIGH
)

// Internal clock
ClockDomain.internal(
  name: String,
  [config: ClockDomainConfig,]
  [withReset: Boolean,]
  [withSoftReset: Boolean,]
  [withClockEnable: Boolean,]
  [frequency: IClockDomainFrequency]
)
// Once created, you have to assign the ClockDomain’s signals, as shown in the example below:
class InternalClockWithPllExample extends Component {
  val io = new Bundle {
    val clk100M = in Bool
    val aReset  = in Bool
    val result  = out UInt (4 bits)
  }
  // myClockDomain.clock will be named myClockName_clk
  // myClockDomain.reset will be named myClockName_reset
  val myClockDomain = ClockDomain.internal("myClockName")

  // Instantiate a PLL (probably a BlackBox)
  val pll = new Pll()
  pll.io.clkIn := io.clk100M

  // Assign myClockDomain signals with something
  myClockDomain.clock := pll.io.clockOut
  myClockDomain.reset := io.aReset || !pll.io.

  // Do whatever you want with myClockDomain
  val myArea = new ClockingArea(myClockDomain) {
    val myReg = Reg(UInt(4 bits)) init(7)
    myReg := myReg + 1

    io.result := myReg
  }
}

// External clock
ClockDomain.external(
  name: String,
  [config: ClockDomainConfig,]
  [withReset: Boolean,]
  [withSoftReset: Boolean,]
  [withClockEnable: Boolean,]
  [frequency: IClockDomainFrequency]
)
class ExternalClockExample extends Component {
  val io = new Bundle {
    val result = out UInt (4 bits)
  }

  // On the top level you have two signals  :
  //     myClockName_clk and myClockName_reset
  val myClockDomain = ClockDomain.external("myClockName")

  val myArea = new ClockingArea(myClockDomain) {
    val myReg = Reg(UInt(4 bits)) init(7)
    myReg := myReg + 1

    io.result := myReg
  }
}

// Context
val coreClockDomain = ClockDomain(coreClock, coreReset, frequency=FixedFrequency(100e6))
val coreArea = new ClockingArea(coreClockDomain) {
  val freq = ClockDomain.current.frequency.getValue
  val ctrl = new UartCtrl()
  ctrl.io.config.clockDivider := (freq / 57.6e3 / 8).toInt
}

// Clock domain crossing
//             _____                        _____             _____
//            |     |  (crossClockDomain)  |     |           |     |
//  dataIn -->|     |--------------------->|     |---------->|     |--> dataOut
//            | FF  |                      | FF  |           | FF  |
//  clkA   -->|     |              clkB -->|     |   clkB -->|     |
//  rstA   -->|_____|              rstB -->|_____|   rstB -->|_____|
// Implementation where clock and reset pins are given by components' IO
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
  val area_clkA = new ClockingArea(ClockDomain(io.clkA,io.rstA)) {
    val reg = RegNext(io.dataIn) init(False)
  }

  // 2 register stages to avoid metastability issues
  val area_clkB = new ClockingArea(ClockDomain(io.clkB,io.rstB)) {
    val buf0   = RegNext(area_clkA.reg) init(False) addTag(crossClockDomain)
    val buf1   = RegNext(buf0)          init(False)
  }

  io.dataOut := area_clkB.buf1
}
// Alternative implementation where clock domains are given as parameters
class CrossingExample(clkA : ClockDomain,clkB : ClockDomain) extends Component {
  val io = new Bundle {
    val dataIn  = in Bool
    val dataOut = out Bool
  }

  // sample dataIn with clkA
  val area_clkA = new ClockingArea(clkA) {
    val reg = RegNext(io.dataIn) init(False)
  }

  // 2 register stages to avoid metastability issues
  val area_clkB = new ClockingArea(clkB) {
    val buf0   = RegNext(area_clkA.reg) init(False) addTag(crossClockDomain)
    val buf1   = RegNext(buf0)          init(False)
  }

  io.dataOut := area_clkB.buf1
}
// BufferCC
class CrossingExample(clkA : ClockDomain,clkB : ClockDomain) extends Component {
  val io = new Bundle {
    val dataIn  = in Bool
    val dataOut = out Bool
  }

  // sample dataIn with clkA
  val area_clkA = new ClockingArea(clkA) {
    val reg = RegNext(io.dataIn) init(False)
  }

  // BufferCC to avoid metastability issues
  val area_clkB = new ClockingArea(clkB) {
    val buf1   = BufferCC(area_clkA.reg, False)
  }

  io.dataOut := area_clkB.buf1
}

// Slow Area
class TopLevel extends Component {
  // Use the current clock domain : 100MHz
  val areaStd = new Area {
    val counter = out(CounterFreeRun(16).value)
  }

  // Slow the current clockDomain by 4 : 25 MHz
  val areaDiv4 = new SlowArea(4) {
    val counter = out(CounterFreeRun(16).value)
  }

  // Slow the current clockDomain to 50MHz
  val area50Mhz = new SlowArea(50 MHz) {
    val counter = out(CounterFreeRun(16).value)
  }
}
def main(args: Array[String]) {
  new SpinalConfig(
    defaultClockDomainFrequency = FixedFrequency(100 MHz)
  ).generateVhdl(new TopLevel)
}

// ResetArea
class TopLevel extends Component {
  val specialReset = Bool

  // The reset of this area is done with the specialReset signal
  val areaRst_1 = new ResetArea(specialReset, false) {
    val counter = out(CounterFreeRun(16).value)
  }

  // The reset of this area is a combination between the current reset and the specialReset
  val areaRst_2 = new ResetArea(specialReset, true) {
    val counter = out(CounterFreeRun(16).value)
  }
}

// ClockEnableArea
class TopLevel extends Component {
  val clockEnable = Bool

  // Add a clock enable for this area
  val area_1 = new ClockEnableArea(clockEnable) {
    val counter = out(CounterFreeRun(16).value)
  }
}

/// Instantiate VHDL and Verilog IP

// Defining an blackbox
// Define a Ram as a BlackBox
class Ram_1w_1r(wordWidth: Int, wordCount: Int) extends BlackBox {
  // SpinalHDL will look at Generic classes to get attributes which
  // should be used as VHDL generics / Verilog parameters
  // You can use String, Int, Double, Boolean, and all SpinalHDL base
  // types as generic values
  val generic = new Generic {
    val wordCount = Ram_1w_1r.this.wordCount
    val wordWidth = Ram_1w_1r.this.wordWidth
  }

  // Define IO of the VHDL entity / Verilog module
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

  // Map the current clock domain to the io.clk pin
  mapClockDomain(clock=io.clk)
}

// Generics
class Ram(wordWidth: Int, wordCount: Int) extends BlackBox {
    val generic = new Generic {
      val wordCount = Ram.this.wordCount
      val wordWidth = Ram.this.wordWidth
    }

    // OR

    addGeneric("wordCount", wordCount)
    addGeneric("wordWidth", wordWidth)
}

// Instantiating a blackbox
// Create the top level and instantiate the Ram
class TopLevel extends Component {
  val io = new Bundle {
    val wr = new Bundle {
      val en   = in Bool
      val addr = in UInt (log2Up(16) bit)
      val data = in Bits (8 bit)
    }
    val rd = new Bundle {
      val en   = in Bool
      val addr = in UInt (log2Up(16) bit)
      val data = out Bits (8 bit)
    }
  }

  // Instantiate the blackbox
  val ram = new Ram_1w_1r(8,16)

  // Connect all the signals
  io.wr.en   <> ram.io.wr.en
  io.wr.addr <> ram.io.wr.addr
  io.wr.data <> ram.io.wr.data
  io.rd.en   <> ram.io.rd.en
  io.rd.addr <> ram.io.rd.addr
  io.rd.data <> ram.io.rd.data
}
object Main {
  def main(args: Array[String]): Unit = {
    SpinalVhdl(new TopLevel)
  }
}

// Clock and reset mapping
class MyRam(clkDomain: ClockDomain) extends BlackBox {
  val io = new Bundle {
    val clkA = in Bool
    ...
    val clkB = in Bool
    ...
  }

  // Clock A is map on a specific clock Domain
  mapClockDomain(clkDomain, io.clkA)
  // Clock B is map on the current clock domain
  mapCurrentClockDomain(io.clkB)
}

// io prefix
// Define the Ram as a BlackBox
class Ram_1w_1r(wordWidth: Int, wordCount: Int) extends BlackBox {
  val generic = new Generic {
    val wordCount = Ram_1w_1r.this.wordCount
    val wordWidth = Ram_1w_1r.this.wordWidth
  }

  val io = new Bundle {
    val clk = in Bool

    val wr = new Bundle {
      val en   = in Bool
      val addr = in UInt (log2Up(_wordCount) bit)
      val data = in Bits (_wordWidth bit)
    }
    val rd = new Bundle {
      val en   = in Bool
      val addr = in UInt (log2Up(_wordCount) bit)
      val data = out Bits (_wordWidth bit)
    }
  }

  noIoPrefix()
  mapCurrentClockDomain(clock=io.clk)
}

// Rename all io of a blackbox
class MyRam() extends Blackbox {

  val io = new Bundle {
    val clk = in Bool
    val portA = new Bundle{
      val cs   = in Bool
      val rwn  = in Bool
      val dIn  = in Bits(32 bits)
      val dOut = out Bits(32 bits)
    }
    val portB = new Bundle{
      val cs   = in Bool
      val rwn  = in Bool
      val dIn  = in Bits(32 bits)
      val dOut = out Bits(32 bits)
    }
  }

  // Map the clk
  mapCurrentClockDomain(io.clk)

  // Remove io_ prefix
  noIoPrefix()

  // Function used to rename all signals of the blackbox
  private def renameIO(): Unit = {
    io.flatten.foreach(bt => {
      if(bt.getName().contains("portA")) bt.setName(bt.getName().repalce("portA_", "") + "_A")
      if(bt.getName().contains("portB")) bt.setName(bt.getName().repalce("portB_", "") + "_B")
    })
  }

  // Execute the function renameIO after the creation of the component
  addPrePopTask(() => renameIO())
}
// This code generate these names:
//    clk
//    cs_A, rwn_A, dIn_A, dOut_A
//    cs_B, rwn_B, dIn_B, dOut_B

// Add RTL source
class MyBlackBox() extends Blackbox {
  val io = new Bundle {
    val clk   = in  Bool
    val start = in Bool
    val dIn   = in  Bits(32 bits)
    val dOut  = out Bits(32 bits)
    val ready = out Bool
  }

  // Map the clk
  mapCurrentClockDomain(io.clk)

  // Remove io_ prefix
  noIoPrefix()

  // Add all rtl dependencies
  addRTLPath("./rtl/RegisterBank.v")                         // Add a verilog file
  addRTLPath(s"./rtl/myDesign.vhd")                          // Add a vhdl file
  addRTLPath(s"${sys.env("MY_PROJECT")}/myTopLevel.vhd")     // Use an environement variable MY_PROJECT (System.getenv("MY_PROJECT"))
}
val report = SpinalVhdl(new MyBlackBox)
report.mergeRTLSource("mergeRTL") // Merge all rtl sources into mergeRTL.vhd and mergeRTL.v files

// VHDL - No numeric type
class MyBlackBox() extends BlackBox{
  val io = new Bundle {
    val clk       = in  Bool
    val increment = in  Bool
    val initValue = in  UInt(8 bits)
    val counter   = out UInt(8 bits)
  }

  mapCurrentClockDomain(io.clk)

  noIoPrefix()

  addTag(noNumericType)  // Only std_logic_vector
}

/// Assignments

// There are multiple assignment operators:
// Because of hardware concurrency, `a` is always read as '1' by b and c
val a, b, c = UInt(4 bits)
a := 0
b := a
a := 1  // a := 1 "wins"
c := a
var x = UInt(4 bits)
val y, z = UInt(4 bits)
x := 0
y := x      // y read x with the value 0
x \= x + 1
z := x      // z read x with the value 1
// Automatic connection between two UART interfaces.
uartCtrl.io.uart <> io.uart
// In SpinalHDL, the nature of a signal (combinational/sequential) is defined in its declaration, not by the way it is assigned. 
val a = UInt(4 bits) // Define a combinational signal
val b = Reg(UInt(4 bits)) // Define a registered signal
val c = Reg(UInt(4 bits)) init(0) // Define a registered signal which is set to 0 when a reset occurs

/// When/Switch/Mux

// When
when(cond1) {
  // Execute when cond1 is true
}.elsewhen(cond2) {
  // Execute when (not cond1) and cond2
}.otherwise {
  // Execute when (not cond1) and (not cond2)
}

// Switch
switch(x) {
  is(value1) {
    // Execute when x === value1
  }
  is(value2) {
    // Execute when x === value2
  }
  default {
    // Execute if none of precedent conditions met
  }
}

// Local declaration
val x, y = UInt(4 bits)
val a, b = UInt(4 bits)
when(cond) {
  val tmp = a + b
  x := tmp
  y := tmp + 1
} otherwise {
  x := 0
  y := 0
}

// Mux
val cond = Bool
val whenTrue, whenFalse = UInt(8 bits)
val muxOutput  = Mux(cond, whenTrue, whenFalse)
val muxOutput2 = cond ? whenTrue | whenFalse

// Bitwise selection
val bitwiseSelect = UInt(2 bits)
val bitwiseResult = bitwiseSelect.mux(
  0 -> (io.src0 & io.src1),
  1 -> (io.src0 | io.src1),
  2 -> (io.src0 ^ io.src1),
  default -> (io.src0)
)
// Also, if all possible values are covered in your mux, you can omit the default value:
val bitwiseSelect = UInt(2 bits)
val bitwiseResult = bitwiseSelect.mux(
  0 -> (io.src0 & io.src1),
  1 -> (io.src0 | io.src1),
  2 -> (io.src0 ^ io.src1),
  3 -> (io.src0)
)

// muxLists(...) is another bitwise selection which takes a sequence of tuples as input. Below is an example of dividing a Bits of 128 bits into 32 bits:
val sel  = UInt(2 bits)
val data = Bits(128 bits)
// Dividing a wide Bits type into smaller chunks, using a mux:
val dataWord = sel.muxList(for (index <- 0 until 4) yield (index, data(index*32+32-1 downto index*32)))
// A shorter way to do the same thing:
val dataWord = data.subdivideIn(32 bits)(sel)

/// Rules

// Concurrency
val a, b, c = UInt(8 bits) // Define 3 combinational signals
c := a + b  // c will be set to 7
b := 2      // b will be set to 2
a := b + 3  // a will be set to 5
// This is equivalent to:
val a, b, c = UInt(8 bits) // Define 3 combinational signals
b := 2      // b will be set to 2
a := b + 3  // a will be set to 5
c := a + b  // c will be set to 7

// Last valid assignment wins
val x, y = Bool             // Define two combinational signals
val result = UInt(8 bits)   // Define a combinational signal
result := 1
when(x) {
  result := 2
  when(y) {
    result := 3
  }
}

// Signal and register interactions with Scala (OOP reference + Functions)
val inc, clear = Bool            // Define two combinational signals/wires
val counter = Reg(UInt(8 bits))  // Define an 8 bit register
when(inc) {
  counter := counter + 1
}
when(clear) {
  counter := 0    // If inc and clear are True, then this  assignment wins (Last valid assignment rule)
}
// You can implement exactly the same functionality by mixing the previous example with a function that assigns to counter:
val inc, clear = Bool
val counter = Reg(UInt(8 bits))
def setCounter(value : UInt): Unit = {
  counter := value
}
when(inc) {
  setCounter(counter + 1)  // Set counter with counter + 1
}
when(clear) {
  counter := 0
}
// You can also integrate the conditional check inside the function:
val inc, clear = Bool
val counter = Reg(UInt(8 bits))
def setCounterWhen(cond : Bool,value : UInt): Unit = {
  when(cond) {
    counter := value
  }
}
setCounterWhen(cond = inc,   value = counter + 1)
setCounterWhen(cond = clear, value = 0)

// And also specify what should be assigned to the function:
val inc, clear = Bool
val counter = Reg(UInt(8 bits))
def setSomethingWhen(something : UInt, cond : Bool, value : UInt): Unit = {
  when(cond) {
    something := value
  }
}
setSomethingWhen(something = counter, cond = inc,   value = counter + 1)
setSomethingWhen(something = counter, cond = clear, value = 0)

/// Registers

// Initialization
// UInt register of 4 bits
val reg1 = Reg(UInt(4 bit))
// Register that samples reg1 each cycle
val reg2 = RegNext(reg1 + 1)
// UInt register of 4 bits initialized with 0 when the reset occurs
val reg3 = RegInit(U"0000")
reg3 := reg2
when(reg2 === 5) {
  reg3 := 0xF
}
// Register that samples reg3 when cond is True
val reg4 = RegNextWhen(reg3, cond)
// Also, RegNext is an abstraction which is built over the Reg syntax. The two following sequences of code are strictly equivalent:
// Standard way
val something = Bool
val value = Reg(Bool)
value := something
// Short way
val something = Bool
val value = RegNext(something)

// Reset value
// UInt register of 4 bits initialized with 0 when the reset occurs
val reg1 = Reg(UInt(4 bit)) init(0)
If you have a register containing a Bundle, you can use the init function on each element of the Bundle.
case class ValidRGB() extends Bundle{
  val valid   = Bool
  val r, g, b = UInt(8 bits)
}
val reg = Reg(ValidRGB())
reg.valid init(False)  // Only the valid if that register bundle will have a reset value.

// Initialization value for simulation purposes
// UInt register of 4 bits initialized with a random value
val reg1 = Reg(UInt(4 bit)) randBoot()

/// RAM/ROM

// Syntax
val mem = Mem(Bits(32 bits), wordCount = 256)
mem.write(
  enable  = io.writeValid,
  address = io.writeAddress,
  data    = io.writeData
)
io.readData := mem.readSync(
  enable  = io.readValid,
  address = io.readAddress
)

// Automatic blackboxing
def main(args: Array[String]) {
  SpinalConfig()
    // 4 blackboxing policies:
    // - blackboxAll
    // - blackboxAllWhatsYouCan
    // - blackboxRequestedAndUninferable
    // - blackboxOnlyIfRequested
    .addStandardMemBlackboxing(blackboxAll)
    .generateVhdl(new TopLevel)
}

// Blackboxing policy
val mem = Mem(Rgb(rgbConfig), 1 << 16)
// 4 technology options:
// - auto
// - ramBlock
// - distributedLut
// - registerFile
mem.setTechnology(tech=registerFile)
mem.generateAsBlackBox()

/// Assignment overlap

class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 42
  a := 66 // Erase the a := 42 assignment
}
// A fix could be:
class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 42
  when(something) {
    a := 66
  }
}
// But in the case when you really want to override the previous assignment (as there are times when overriding makes sense), you can do the following:
class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 42
  a.allowOverride
  a := 66
}

/// Clock crossing violation

class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")

  val regA = clkA(Reg(UInt(8 bits)))   // PlayDev.scala:834
  val regB = clkB(Reg(UInt(8 bits)))   // PlayDev.scala:835

  val tmp = regA + regA                // PlayDev.scala:838
  regB := tmp
}
// crossClockDomain tag
class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")

  val regA = clkA(Reg(UInt(8 bits)))
  val regB = clkB(Reg(UInt(8 bits))).addTag(crossClockDomain)

  val tmp = regA + regA
  regB := tmp
}
// setSyncronousWith
class TopLevel extends Component {
  val clkA = ClockDomain.external("clkA")
  val clkB = ClockDomain.external("clkB")
  clkB.setSyncronousWith(clkA)

  val regA = clkA(Reg(UInt(8 bits)))
  val regB = clkB(Reg(UInt(8 bits)))

  val tmp = regA + regA
  regB := tmp
}
// BufferCC
class AsyncFifo extends Component {
   val popToPushGray = Bits(ptrWidth bits)
   val pushToPopGray = Bits(ptrWidth bits)

   val pushCC = new ClockingArea(pushClock) {
     val pushPtr     = Counter(depth << 1)
     val pushPtrGray = RegNext(toGray(pushPtr.valueNext)) init(0)
     val popPtrGray  = BufferCC(popToPushGray, B(0, ptrWidth bits))
     val full        = isFull(pushPtrGray, popPtrGray)
     ...
   }

   val popCC = new ClockingArea(popClock) {
     val popPtr      = Counter(depth << 1)
     val popPtrGray  = RegNext(toGray(popPtr.valueNext)) init(0)
     val pushPtrGray = BufferCC(pushToPopGray, B(0, ptrWidth bit))
     val empty       = isEmpty(popPtrGray, pushPtrGray)
     ...
   }
}

/// Combinatorial loop

class TopLevel extends Component {
  val a = UInt(8 bits) // PlayDev.scala line 831
  val b = UInt(8 bits) // PlayDev.scala line 832
  val c = UInt(8 bits)
  val d = UInt(8 bits)

  a := b
  b := c | d
  d := a
  c := 0
}
// A possible fix could be:
class TopLevel extends Component {
  val a = UInt(8 bits) // PlayDev.scala line 831
  val b = UInt(8 bits) // PlayDev.scala line 832
  val c = UInt(8 bits)
  val d = UInt(8 bits)

  a := b
  b := c | d
  d := 42
  c := 0
}

// False-positives
class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 0
  a(1) := a(0) // False positive because of this line
}
// Could be fixed by:
class TopLevel extends Component {
  val a = UInt(8 bits).noCombLoopCheck
  a := 0
  a(1) := a(0)
}
// Or use Vec(Bool, 8)
class TopLevel extends Component {
  val a = Vec(Bool, 8)
  a(0) := 0
  a(1) := a(0)
}

/// Hierarchy violation

class TopLevel extends Component {
  val io = new Bundle {
    val a = in UInt(8 bits)
  }
  val tmp = U"x42"
  io.a := tmp
}
// A fix could be :
class TopLevel extends Component {
  val io = new Bundle {
    val a = out UInt(8 bits) // changed from in to out
  }
  val tmp = U"x42"
  io.a := tmp
}

/// Io bundle

class TopLevel extends Component {
  val io = new Bundle {
    val a = UInt(8 bits)
  }
}
// A fix could be:
class TopLevel extends Component {
  val io = new Bundle {
    val a = in UInt(8 bits)
  }
}
// But if for meta hardware description reasons you really want io.a to be directionless, you can do:
class TopLevel extends Component {
  val io = new Bundle {
    val a = UInt(8 bits)
  }
  a.allowDirectionLessIo
}

/// Latch detected

class TopLevel extends Component {
  val cond = in(Bool)
  val a = UInt(8 bits)

  when(cond) {
    a := 42
  }
}
// A fix could be:
class TopLevel extends Component {
  val cond = in(Bool)
  val a = UInt(8 bits)

  a := 0
  when(cond) {
    a := 42
  }
}

/// No driver on

class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = UInt(8 bits)
  result := a
}
// A fix could be:
class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = UInt(8 bits)
  a := 42
  result := a
}

/// NullPointerException

class TopLevel extends Component {
  a := 42
  val a = UInt(8 bits)
}
// A fix could be:
class TopLevel extends Component {
  val a = UInt(8 bits)
  a := 42
}

/// Register defined as component input

class TopLevel extends Component {
  val io = new Bundle {
    val a = in(Reg(UInt(8 bits)))
  }
}
// A fix could be :
class TopLevel extends Component {
  val io = new Bundle {
    val a = in UInt(8 bits)
  }
}
// If a registered a is required, it can be done like so:
class TopLevel extends Component {
  val io = new Bundle {
    val a = in UInt(8 bits)
  }
  val a = RegNext(io.a)
}

/// Scope violation

class TopLevel extends Component {
  val cond = Bool()

  var tmp : UInt = null
  when(cond) {
    tmp = UInt(8 bits)
  }
  tmp := U"x42"
}
// A fix could be:
class TopLevel extends Component {
  val cond = Bool()

  var tmp : UInt = UInt(8 bits)
  when(cond) {
  }
  tmp := U"x42"
}

/// Spinal can’t clone class

// cloneOf(this) isn't able to retrieve the width value that was used to construct itself
class RGB(width : Int) extends Bundle {
  val r, g, b = UInt(width bits)
}
class TopLevel extends Component {
  val tmp = Stream(new RGB(8)) // Stream requires the capability to cloneOf(new RGB(8))
}
// A fix could be:
case class RGB(width : Int) extends Bundle {
  val r, g, b = UInt(width bits)
}
class TopLevel extends Component {
  val tmp = Stream(RGB(8))
}

/// Unassigned register

class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = Reg(UInt(8 bits))
  result := a
}
// A fix could be:
class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = Reg(UInt(8 bits))
  a := 42
  result := a
}

// Register with only init
class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = Reg(UInt(8 bits)) init(42)

  if(something)
    a := somethingElse
  result := a
}
// To fix it, you can ask SpinalHDL to transform the register into a combinational one if no assignment is present but it has an init statement:
class TopLevel extends Component {
  val result = out(UInt(8 bits))
  val a = Reg(UInt(8 bits)).init(42).allowUnsetRegToAvoidLatch

  if(something)
    a := somethingElse
  result := a
}

/// Unreachable is statement

class TopLevel extends Component {
  val sel = UInt(2 bits)
  val result = UInt(4 bits)
  switch(sel) {
    is(0){ result := 4 }
    is(1){ result := 6 }
    is(2){ result := 8 }
    is(3){ result := 9 }
    is(0){ result := 2 } // Duplicated is statement!
  }
}
// A fix could be:
class TopLevel extends Component {
  val sel = UInt(2 bits)
  val result = UInt(4 bits)
  switch(sel) {
    is(0){ result := 4 }
    is(1){ result := 6 }
    is(2){ result := 8 }
    is(3){ result := 9 }
  }
}

/// Width mismatch

class TopLevel extends Component {
  val a = UInt(8 bits)
  val b = UInt(4 bits)
  b := a
}
// A fix could be:
class TopLevel extends Component {
  val a = UInt(8 bits)
  val b = UInt(4 bits)
  b := a.resized
}

class TopLevel extends Component {
  val a = UInt(8 bits)
  val b = UInt(4 bits)
  val result = a | b
}
// A fix could be:
class TopLevel extends Component {
  val a = UInt(8 bits)
  val b = UInt(4 bits)
  val result = a | (b.resized)
}

/// Utils

// Cloning hardware datatypes
def plusOne(value : UInt) : UInt = {
  // Will recreate a UInt with the same width than ``value``
  val temp = cloneOf(value)
  temp := value + 1
  return temp
}
// treePlusOne will become a 8 bits value
val treePlusOne = plusOne(U(3, 8 bits))

// Passing a datatype as construction parameter
// The old way
case class ShiftRegister[T <: Data](dataType: T, depth: Int) extends Component {
  val io = new Bundle {
    val input  = in (cloneOf(dataType)) // Not to forget to use cloneOf
    val output = out(cloneOf(dataType)) // Not to forget to use cloneOf
  }
  // ...
}
val shiftReg = ShiftRegister(Bits(32 bits), depth = 8)
// The safe way
case class ShiftRegister[T <: Data](dataType: HardType[T], depth: Int) extends Component {
  val io = new Bundle {
    val input  = in (dataType()) // Add parentheses after the parameter
    val output = out(dataType()) // Add parentheses after the parameter
  }
  // ...
}
val shiftReg = ShiftRegister(Bits(32 bits), depth = 8)

// Frequency and time
val frequency = 100 MHz // HertzNumber
val timeoutLimit = 3 ms // TimeNumber
val period = 100 us
val periodCycles = frequency * period
val timeoutCycles = frequency * timeoutLimit

/// Assertions

class TopLevel extends Component {
  val valid = RegInit(False)
  val ready = in Bool

  when(ready) {
    valid := False
  }
  // Severity levels are:
  // NOTE
  // WARNING
  // ERROR
  // FAILURE
  assert(
    assertion = !(valid.fall && !ready),
    message   = "Valid dropped when ready was low",
    severity  = ERROR
  )
}

/// Formal

class TopLevel extends Component {
  val io = new Bundle {
    val ready = in Bool
    val valid = out Bool
  }
  val valid = RegInit(False)

  when(io.ready) {
    valid := False
  }
  io.valid <> valid
  // some logic

  import spinal.core.GenerationFlags._
  import spinal.core.Formal._
  GenerationFlags.formal {
    when(initstate()) {
      assume(clockDomain.isResetActive)
      assume(io.ready === False)
    }.otherwise {
      assert(!(valid.fall && !io.ready))
    }
  }
}
// To generate a design which includes the formal statements you can use includeFormal:
object MyToplevelSystemVerilogWithFormal {
 def main(args: Array[String]) {
   val config = SpinalConfig(defaultConfigForClockDomains = ClockDomainConfig(resetKind=SYNC, resetActiveLevel=HIGH))
    config.includeFormal.generateSystemVerilog(new TopLevel())
  }
}

/// Analog and inout

// Analog
case class SdramInterface(g : SdramLayout) extends Bundle {
  val DQ    = Analog(Bits(g.dataWidth bits)) // Bidirectional data bus
  val DQM   = Bits(g.bytePerWord bits)
  val ADDR  = Bits(g.chipAddressWidth bits)
  val BA    = Bits(g.bankWidth bits)
  val CKE, CSn, CASn, RASn, WEn  = Bool
}

// inout
case class SdramInterface(g : SdramLayout) extends Bundle with IMasterSlave {
  val DQ    = Analog(Bits(g.dataWidth bits)) // Bidirectional data bus
  val DQM   = Bits(g.bytePerWord bits)
  val ADDR  = Bits(g.chipAddressWidth bits)
  val BA    = Bits(g.bankWidth bits)
  val CKE, CSn, CASn, RASn, WEn  = Bool

  override def asMaster() : Unit = {
    out(ADDR, BA, CASn, CKE, CSn, DQM, RASn, WEn)
    inout(DQ) // Set the Analog DQ as an inout signal of the component
  }
}

// InOutWrapper
// InOutWrapper is a tool which allows you to transform all master TriState/TriStateArray/ReadableOpenDrain bundles of a component into native inout(Analog(...)) signals
case class Apb3Gpio(gpioWidth : Int) extends Component {
  val io = new Bundle{
    val gpio = master(TriStateArray(gpioWidth bits))
    val apb  = slave(Apb3(Apb3Gpio.getApb3Config()))
  }
  ...
}
SpinalVhdl(InOutWrapper(Apb3Gpio(32)))

// Manually driving Analog bundles
case class Example extends Component {
  val io = new Bundle {
    val tri = slave(TriState(Bits(16 bit)))
    val analog = inout Analog(Bits(16 bit))
  }
  tri.read := analog
  when(tri.writeEnable) { analog := tri.write }
}

// InOutWrapper for master
import spinal.lib.io._
case class Gpio() extends Component {
  val io = new Bundle{
    val input = in Bits(16 bits)
    val oe = in Bool
    val gpio = master(TriState(Bits(16 bits)))
  }
  io.gpio.writeEnable := io.oe
  io.gpio.write := io.input
  val read = io.gpio.read
}
object GpioInst extends App{
    SpinalSystemVerilog(InOutWrapper(Gpio(32)))
}
//showRtl(InOutWrapper(Gpio()))

// InOutWrapper for slave, no effect
import spinal.lib.io._
case class Gpio() extends Component {
  val io = new Bundle{
    val input = in Bits(16 bits)
    val gpio = slave(TriState(Bits(16 bits)))
  }
  val write = Reg(Bits(16 bits)) init(0)
  io.gpio.read := io.input
  when(io.gpio.writeEnable){
    write := io.gpio.write
  }
}
object GpioInst extends App{
  SpinalSystemVerilog(InOutWrapper(Gpio(32)))
}
//showRtl(InOutWrapper(Gpio()))

/// VHDL and Verilog generation

// Generate VHDL and Verilog from a SpinalHDL Component
import spinal.core._
// A simple component definition.
class MyTopLevel extends Component {
  // Define some input/output signals. Bundle like a VHDL record or a Verilog struct.
  val io = new Bundle {
    val a = in  Bool
    val b = in  Bool
    val c = out Bool
  }

  // Define some asynchronous logic.
  io.c := io.a & io.b
}
// This is the main function that generates the VHDL and the Verilog corresponding to MyTopLevel.
object MyMain {
  def main(args: Array[String]) {
    SpinalVhdl(new MyTopLevel)
    SpinalVerilog(new MyTopLevel)
  }
}

// Parametrization from Scala
SpinalConfig(mode=VHDL, targetDirectory="temp/myDesign").generate(new UartCtrl)
// Or for Verilog in a more scalable formatting:
SpinalConfig(
  mode=Verilog,
  targetDirectory="temp/myDesign"
).generate(new UartCtrl)

// Parametrization from shell
def main(args: Array[String]): Unit = {
  SpinalConfig.shell(args)(new UartCtrl)
}
// Usage: SpinalCore [options]
//   --vhdl
//         Select the VHDL mode
//   --verilog
//         Select the Verilog mode
//   -d | --debug
//         Enter in debug mode directly
//   -o <value> | --targetDirectory <value>
//         Set the target directory

// Combinational logic
class TopLevel extends Component {
  val io = new Bundle {
    val cond           = in  Bool
    val value          = in  UInt(4 bits)
    val withoutProcess = out UInt(4 bits)
    val withProcess    = out UInt(4 bits)
  }
  io.withoutProcess := io.value
  io.withProcess := 0
  when(io.cond) {
    switch(io.value) {
      is(U"0000") {
        io.withProcess := 8
      }
      is(U"0001") {
        io.withProcess := 9
      }
      default {
        io.withProcess := io.value+1
      }
    }
  }
}

// Sequential logic
class TopLevel extends Component {
  val io = new Bundle {
    val cond   = in Bool
    val value  = in UInt (4 bit)
    val resultA = out UInt(4 bit)
    val resultB = out UInt(4 bit)
  }

  val regWithReset = Reg(UInt(4 bits)) init(0)
  val regWithoutReset = Reg(UInt(4 bits))

  regWithReset := io.value
  regWithoutReset := 0
  when(io.cond) {
    regWithoutReset := io.value
  }

  io.resultA := regWithReset
  io.resultB := regWithoutReset
}

// VHDL and Verilog attributes
val pcPlus4 = pc + 4
pcPlus4.addAttribute("keep")

/// Library/Utils

// Counter
val counter = Counter(2 to 9)  //Create a counter of 10 states (2 to 9)
counter.clear()            //When called it ask to reset the counter.
counter.increment()        //When called it ask to increment the counter.
counter.value              //current value
counter.valueNext          //Next value
counter.willOverflow       //Flag that indicate if the counter overflow this cycle
counter.willOverflowIfInc  //Flag that indicate if the counter overflow this cycle if an increment is done
when(counter === 5){ ... }

// Timeout
val timeout = Timeout(10 ms)  //Timeout who tick after 10 ms
when(timeout){                //Check if the timeout has tick
    timeout.clear()           //Ask the timeout to clear its flag
}

/// Stream

// Specification
class StreamFifo[T <: Data](dataType: T, depth: Int) extends Component {
  val io = new Bundle {
    val push = slave Stream (dataType)
    val pop = master Stream (dataType)
  }
  ...
}
class StreamArbiter[T <: Data](dataType: T,portCount: Int) extends Component {
  val io = new Bundle {
    val inputs = Vec(slave Stream (dataType),portCount)
    val output = master Stream (dataType)
  }
  ...
}

// Functions
case class RGB(channelWidth : Int) extends Bundle{
  val red   = UInt(channelWidth bit)
  val green = UInt(channelWidth bit)
  val blue  = UInt(channelWidth bit)

  def isBlack : Bool = red === 0 && green === 0 && blue === 0
}
val source = Stream(RGB(8))
val sink   = Stream(RGB(8))
sink <-< source.throwWhen(source.payload.isBlack)

// StreamFifo
val streamA,streamB = Stream(Bits(8 bits))
val myFifo = StreamFifo(
  dataType = Bits(8 bits),
  depth    = 128
)
myFifo.io.push << streamA
myFifo.io.pop  >> streamB

// StreamFifoCC
val clockA = ClockDomain(???)
val clockB = ClockDomain(???)
val streamA,streamB = Stream(Bits(8 bits))
//...
val myFifo = StreamFifoCC(
  dataType  = Bits(8 bits),
  depth     = 128,
  pushClock = clockA,
  popClock  = clockB
)
myFifo.io.push << streamA
myFifo.io.pop  >> streamB

// StreamCCByToggle
val clockA = ClockDomain(???)
val clockB = ClockDomain(???)
val streamA,streamB = Stream(Bits(8 bits))
//...
val bridge = StreamCCByToggle(
  dataType    = Bits(8 bits),
  inputClock  = clockA,
  outputClock = clockB
)
bridge.io.input  << streamA
bridge.io.output >> streamB

// StreamArbiter
val streamA, streamB, streamC = Stream(Bits(8 bits))
// Generation functions:
// on(inputs : Seq[Stream[T]])
// onArgs(inputs : Stream[T]*)
val arbitredABC = StreamArbiterFactory.roundRobin.onArgs(streamA, streamB, streamC)
// Arbitration functions:
// lowerFirst
// roundRobin
// sequentialOrder
val streamD, streamE, streamF = Stream(Bits(8 bits))
// Lock functions:
// noLock
// transactionLock
// fragmentLock
val arbitredDEF = StreamArbiterFactory.lowerFirst.noLock.onArgs(streamD, streamE, streamF)

// StreamJoin
val cmdJoin = Stream(Cmd())
cmdJoin.arbitrationFrom(StreamJoin.arg(cmdABuffer, cmdBBuffer))

// StreamFork
val inputStream = Stream(Bits(8 bits))
val (outputstream1, outputstream2) = StreamFork2(inputStream, synchronous=false)
// or
val inputStream = Stream(Bits(8 bits))
val outputStreams = StreamFork(inputStream, portCount=2, synchronous=true)

// StreamDispatcherSequencial
val inputStream = Stream(Bits(8 bits))
val dispatchedStreams = StreamDispatcherSequencial(
  input = inputStream,
  outputCount = 3
)

/// State machine

// Style A :
import spinal.lib.fsm._
class TopLevel extends Component {
  val io = new Bundle{
    val result = out Bool
  }

  val fsm = new StateMachine{
    val counter = Reg(UInt(8 bits)) init (0)
    io.result := False

    val stateA : State = new State with EntryPoint{
      whenIsActive (goto(stateB))
    }
    val stateB : State = new State{
      onEntry(counter := 0)
      whenIsActive {
        counter := counter + 1
        when(counter === 4){
          goto(stateC)
        }
      }
      onExit(io.result := True)
    }
    val stateC : State = new State{
      whenIsActive (goto(stateA))
    }
  }
}

// Style B :
import spinal.lib.fsm._
class TopLevel extends Component {
  val io = new Bundle{
    val result = out Bool
  }

  val fsm = new StateMachine{
    val stateA = new State with EntryPoint
    val stateB = new State
    val stateC = new State

    val counter = Reg(UInt(8 bits)) init (0)
    io.result := False

    stateA
      .whenIsActive (goto(stateB))

    stateB
      .onEntry(counter := 0)
      .whenIsActive {
        counter := counter + 1
        when(counter === 4){
          goto(stateC)
        }
      }
      .onExit(io.result := True)

    stateC
      .whenIsActive (goto(stateA))
  }
}

// StateMachine
val myFsm = new StateMachine{
  // Here will come states definition
}

// States
val stateB : State = new State{
  onEntry(counter := 0)
  whenIsActive {
    counter := counter + 1
    when(counter === 4){
      goto(stateC)
    }
  }
  onExit(io.result := True)
}
// You can also define your state as the entry point of the state machine by extends the EntryPoint trait.
val stateA: State = new State with EntryPoint {
  whenIsActive {
    goto(stateB)
  }
}

// StateDelay
val stateG : State = new StateDelay(cyclesCount=40){
  whenCompleted{
    goto(stateH)
  }
}
// But you can also write it like that :
val stateG : State = new StateDelay(40) { whenCompleted(goto(stateH)) }

// StateFsm
val stateC = new StateFsm(fsm=internalFsm()){
  whenCompleted{
    goto(stateD)
  }
}
def internalFsm() = new StateMachine {
  val counter = Reg(UInt(8 bits)) init (0)

  val stateA: State = new State with EntryPoint {
    whenIsActive {
      goto(stateB)
    }
  }

  val stateB: State = new State {
    onEntry (counter := 0)
    whenIsActive {
      when(counter === 4) {
        exit()
      }
      counter := counter + 1
    }
  }
}

// StateParallelFsm
val stateD = new StateParallelFsm (internalFsmA(), internalFsmB()){
  whenCompleted{
    goto(stateE)
  }
}

/// Generator framework

// Simple dummy example
import spinal.lib.generator._
class Root() extends Generator{
  //Define some Handle which will be later loaded with real values
  val a,b = Handle[Int]

  //Print a + b
  val calculator = new Generator{
    //Specify that this generator need a and b before executing his tasks
    dependencies += a
    dependencies += b

    //Create a new task that will run when all the dependencies are loaded
    add task{
      val sum = a.get + b.get
      println(s"a + b = $sum") //Will print a + b = 7
    }
  }

  //load a and b with values, which will then unlock the calculator generator
  a.load(3)
  b.load(4)
}
// Then you can also chain generators via their handles. For instance we could add the following after the calculator definition :
// Generate a signal of signalWidth bits
val rtl = new Generator{
  dependencies += signalWidth

  val signal = Handle[UInt]
  add task{
    println(s"rtlSignal will have ${signalWidth.get} bits") //Will print "rtlSignal will have 7 bits"
    signal.load(UInt(signalWidth.get bits))
  }
}

// A Generator is composed of :
// dependencies : List of Handles that should be loaded before executing the generator’s tasks
// tasks : List of lambda function which should run once all dependencies are loaded
// products : List of Handles which are loaded by the generator’s tasks

// dependencies
class MyGenerator() extends Generator{
  dependencies += somebodyElseHandle

  val myHandle : Handle[Int] = createDependency[Int] //Create a unloaded Handle[Int]
}

// tasks
class MyGenerator() extends Generator{
  val width = createDependency[Int]
  val logic = add task new Area{
    val a,b,c = UInt(width.get bits)
    val result = a + b + c
  }
}

// products
// At a low level API :
class MyGenerator() extends Generator{
  val interface = Handle[Apb3]
  products += interface
  val rtl = add task new Area{
    val bus = Apb3(32,32)
    interface.load(bus)
  }
}
// The same but less verbose
class MyGenerator() extends Generator{
  val interface = this.produce(rtl.bus)
  val rtl = add task new Area{
    val bus = Apb3(32,32)
  }
}

/// AHB-Lite3

// There is in short how the AHB-Lite3 bus is defined in the SpinalHDL library :
case class AhbLite3(config: AhbLite3Config) extends Bundle with IMasterSlave{
  //  Address and control
  val HADDR = UInt(config.addressWidth bits)
  val HSEL = Bool
  val HREADY = Bool
  val HWRITE = Bool
  val HSIZE = Bits(3 bits)
  val HBURST = Bits(3 bits)
  val HPROT = Bits(4 bits)
  val HTRANS = Bits(2 bits)
  val HMASTLOCK = Bool

  //  Data
  val HWDATA = Bits(config.dataWidth bits)
  val HRDATA = Bits(config.dataWidth bits)

  //  Transfer response
  val HREADYOUT = Bool
  val HRESP = Bool

  override def asMaster(): Unit = {
    out(HADDR,HWRITE,HSIZE,HBURST,HPROT,HTRANS,HMASTLOCK,HWDATA,HREADY,HSEL)
    in(HREADYOUT,HRESP,HRDATA)
  }
}
// There is a short example of usage :
val ahbConfig = AhbLite3Config(
  addressWidth = 12,
  dataWidth    = 32
)
val ahbX = AhbLite3(ahbConfig)
val ahbY = AhbLite3(ahbConfig)
when(ahbY.HSEL){
  //...
}

/// Apb3

// There is in short how the APB3 bus is defined in the SpinalHDL library :
case class Apb3(config: Apb3Config) extends Bundle with IMasterSlave {
  val PADDR      = UInt(config.addressWidth bit)
  val PSEL       = Bits(config.selWidth bits)
  val PENABLE    = Bool
  val PREADY     = Bool
  val PWRITE     = Bool
  val PWDATA     = Bits(config.dataWidth bit)
  val PRDATA     = Bits(config.dataWidth bit)
  val PSLVERROR  = if(config.useSlaveError) Bool else null
  //...
}
// There is a short example of usage :
val apbConfig = Apb3Config(
  addressWidth = 12,
  dataWidth    = 32
)
val apbX = Apb3(apbConfig)
val apbY = Apb3(apbConfig)
when(apbY.PENABLE){
  //...
}

/// Axi4

// There is in short how the AXI4 bus is defined in the SpinalHDL library :
case class Axi4(config: Axi4Config) extends Bundle with IMasterSlave{
  val aw = Stream(Axi4Aw(config))
  val w  = Stream(Axi4W(config))
  val b  = Stream(Axi4B(config))
  val ar = Stream(Axi4Ar(config))
  val r  = Stream(Axi4R(config))

  override def asMaster(): Unit = {
    master(ar,aw,w)
    slave(r,b)
  }
}
// There is a short example of usage :
val axiConfig = Axi4Config(
  addressWidth = 32,
  dataWidth    = 32,
  idWidth      = 4
)
val axiX = Axi4(axiConfig)
val axiY = Axi4(axiConfig)
when(axiY.aw.valid){
  //...
}

/// AvalonMM

// Configuration and instanciation
case class AvalonMMConfig( addressWidth : Int,
                           dataWidth : Int,
                           burstCountWidth : Int,
                           useByteEnable : Boolean,
                           useDebugAccess : Boolean,
                           useRead : Boolean,
                           useWrite : Boolean,
                           useResponse : Boolean,
                           useLock : Boolean,
                           useWaitRequestn : Boolean,
                           useReadDataValid : Boolean,
                           useBurstCount : Boolean,
                           //useEndOfPacket : Boolean,
                           addressUnits : AddressUnits = symbols,
                           burstCountUnits : AddressUnits = words,
                           burstOnBurstBoundariesOnly : Boolean = false,
                           constantBurstBehavior : Boolean = false,
                           holdTime : Int = 0,
                           linewrapBursts : Boolean = false,
                           maximumPendingReadTransactions : Int = 1,
                           maximumPendingWriteTransactions : Int = 0, // unlimited
                           readLatency : Int = 0,
                           readWaitTime : Int = 0,
                           setupTime : Int = 0,
                           writeWaitTime : Int = 0
                           )

// Create a write only AvalonMM configuration with burst capabilities and byte enable
val myAvalonConfig =  AvalonMMConfig.bursted(
                        addressWidth = addressWidth,
                        dataWidth = memDataWidth,
                        burstCountWidth = log2Up(burstSize + 1)
                      ).copy(
                        useByteEnable = true,
                        constantBurstBehavior = true,
                        burstOnBurstBoundariesOnly = true
                      ).getWriteOnlyConfig
// Create an instance of the AvalonMM bus by using this configuration
val bus = AvalonMM(myAvalonConfig)

/// Library/UART

// Bus definition
case class Uart() extends Bundle with IMasterSlave {
  val txd = Bool  // Used to emit frames
  val rxd = Bool  // Used to receive frames

  override def asMaster(): Unit = {
    out(txd)
    in(rxd)
  }
}

/// ReadableOpenDrain

// The ReadableOpenDrain bundle is defined as following :
case class ReadableOpenDrain[T<: Data](dataType : HardType[T]) extends Bundle with IMasterSlave{
  val write,read : T = dataType()

  override def asMaster(): Unit = {
    out(write)
    in(read)
  }
}

// There is an example of usage :
val io = new Bundle{
  val dataBus = master(ReadableOpenDrain(Bits(32 bits)))
}
io.dataBus.write := 0x12345678
when(io.dataBus.read === 42){
  //...
}

/// TriState

// The TriState bundle is defined as following :
case class TriState[T <: Data](dataType : HardType[T]) extends Bundle with IMasterSlave{
  val read,write : T = dataType()
  val writeEnable = Bool

  override def asMaster(): Unit = {
    out(write,writeEnable)
    in(read)
  }
}

// There is an example of usage:
val io = new Bundle{
  val dataBus = master(TriState(Bits(32 bits)))
}
io.dataBus.writeEnable := True
io.dataBus.write := 0x12345678
when(io.dataBus.read === 42){
  //...
}

// TriStateArray is defined as following :
case class TriStateArray(width : BitCount) extends Bundle with IMasterSlave{
  val read,write,writeEnable = Bits(width)

  override def asMaster(): Unit = {
    out(write,writeEnable)
    in(read)
  }
}

// There is an example of usage :
val io = new Bundle{
  val dataBus = master(TriStateArray(32 bits)
}
io.dataBus.writeEnable := 0x87654321
io.dataBus.write := 0x12345678
when(io.dataBus.read === 42){
  //...
}

/// RGB

// You can use an Rgb bundle to model colors in hardware
case class RgbConfig(rWidth : Int,gWidth : Int,bWidth : Int){
  def getWidth = rWidth + gWidth + bWidth
}
case class Rgb(c: RgbConfig) extends Bundle{
  val r = UInt(c.rWidth bits)
  val g = UInt(c.gWidth bits)
  val b = UInt(c.bWidth bits)
}
// Those classes could be used as following :
val config = RgbConfig(5,6,5)
val color = Rgb(config)
color.r := 31

/// VGA

// VGA bus
case class Vga (rgbConfig: RgbConfig) extends Bundle with IMasterSlave{
  val vSync = Bool
  val hSync = Bool

  val colorEn = Bool  //High when the frame is inside the color area
  val color = Rgb(rgbConfig)

  override def asMaster() = this.asOutput()
}

// VGA timings
case class VgaTimingsHV(timingsWidth: Int) extends Bundle {
  val colorStart = UInt(timingsWidth bit)
  val colorEnd = UInt(timingsWidth bit)
  val syncStart = UInt(timingsWidth bit)
  val syncEnd = UInt(timingsWidth bit)
}
case class VgaTimings(timingsWidth: Int) extends Bundle {
  val h = VgaTimingsHV(timingsWidth)
  val v = VgaTimingsHV(timingsWidth)

   def setAs_h640_v480_r60 = ...
   def driveFrom(busCtrl : BusSlaveFactory,baseAddress : Int) = ...
}

// VGA controller
case class VgaCtrl(rgbConfig: RgbConfig, timingsWidth: Int = 12) extends Component {
  val io = new Bundle {
    val softReset = in Bool
    val timings   = in(VgaTimings(timingsWidth))

    val frameStart = out Bool
    val pixels     = slave Stream (Rgb(rgbConfig))
    val vga        = master(Vga(rgbConfig))

    val error      = out Bool
  }
  // ...
}

/// QSysify

// In the case of a UART controller :
case class AvalonMMUartCtrl(...) extends Component{
  val io = new Bundle{
    val bus =  slave(AvalonMM(AvalonMMUartCtrl.getAvalonMMConfig))
    val uart = master(Uart())
  }

  //...
}

// The following main will generate the Verilog and the QSys TCL script with io.bus as an AvalonMM and io.uart as a conduit :
object AvalonMMUartCtrl{
  def main(args: Array[String]) {
    //Generate the Verilog
    val toplevel = SpinalVerilog(AvalonMMUartCtrl(UartCtrlMemoryMappedConfig(...))).toplevel

    //Add some tags to the avalon bus to specify it's clock domain (information used by QSysify)
    toplevel.io.bus addTag(ClockDomainTag(toplevel.clockDomain))

    //Generate the QSys IP (tcl script)
    QSysify(toplevel)
  }
}

// AvalonMM / APB3
io.bus addTag(ClockDomainTag(busClockDomain))
// Interrupt input
io.interrupt addTag(InterruptReceiverTag(relatedMemoryInterfacei, interruptClockDomain))
// Reset output
io.resetOutput addTag(ResetEmitterTag(resetOutputClockDomain))

/// Boot a simulation

// Introduction
//Your hardware toplevel
import spinal.core._
class TopLevel extends Component {
  ...
}
// Your toplevel tester
import spinal.sim._
import spinal.core.sim._
object DutTests {
  def main(args: Array[String]): Unit = {
    SimConfig.withWave.compile(new TopLevel).doSim{ dut =>
      // Simulation code here
    }
  }
}

// Configuration
val spinalConfig = SpinalConfig(defaultClockDomainFrequency = FixedFrequency(10 MHz))
SimConfig
  .withConfig(spinalConfig)
  .withWave
  .allOptimisation
  .workspacePath("~/tmp")
  .compile(new TopLevel)
  .doSim { dut =>
    // Simulation code here
}

// Running multiple tests on the same hardware
val compiled = SimConfig.withWave.compile(new Dut)
compiled.doSim("testA") { dut =>
   // Simulation code here
}
compiled.doSim("testB") { dut =>
   // Simulation code here
}

/// Accessing signals of the simulation

// Read and write signals
dut.io.a #= 42
dut.io.a #= 42l
dut.io.a #= BigInt("101010", 2)
dut.io.a #= BigInt("0123456789ABCDEF", 16)
println(dut.io.b.toInt)

// Accessing signals inside the component’s hierarchy
object SimAccessSubSignal {
  import spinal.core.sim._

  class TopLevel extends Component {
    val counter = Reg(UInt(8 bits)) init(0) simPublic() // Here we add the simPublic tag on the counter register to make it visible
    counter := counter + 1
  }

  def main(args: Array[String]) {
    SimConfig.compile(new TopLevel).doSim{dut =>
      dut.clockDomain.forkStimulus(10)

      for(i <- 0 to 3) {
        dut.clockDomain.waitSampling()
        println(dut.counter.toInt)
      }
    }
  }
}
// Or you can add it later, after having instantiated your toplevel for the simulation:
object SimAccessSubSignal {
  import spinal.core.sim._
  class TopLevel extends Component {
    val counter = Reg(UInt(8 bits)) init(0)
    counter := counter + 1
  }

  def main(args: Array[String]) {
    SimConfig.compile {
      val dut = new TopLevel
      dut.counter.simPublic() // Better way to add simPublic()
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

/// Simulation/Clock domains

// Default ClockDomain
// Example of thread forking to generate a reset, and then toggling the clock each 5 time units.
// dut.clockDomain refers to the implicit clock domain created during component instantiation.
fork {
  dut.clockDomain.assertReset()
  dut.clockDomain.fallingEdge()
  sleep(10)
  while(true) {
    dut.clockDomain.clockToggle()
    sleep(5)
  }
}
// Note that you can also directly fork a standard reset/clock process:
dut.clockDomain.forkStimulus(period = 10)
// An example of how to wait for a rising edge on the clock:
dut.clockDomain.waitRisingEdge()

// New ClockDomain in the testbench
ClockDomain(dut.io.coreClk, dut.io.coreReset).forkStimulus(10)

/// Thread-full API

// Fork and join simulation threads
// Create a new thread
val myNewThread = fork {
  // New simulation thread body
}
// Wait until `myNewThread` is execution is done.
myNewThread.join()

// Sleep and waitUntil
// Sleep 1000 units of time
sleep(1000)
// waitUntil the dut.io.a value is bigger than 42 before continuing
waitUntil(dut.io.a > 42)


