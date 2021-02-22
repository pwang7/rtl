package spinal.exercises

import spinal.core._
import spinal.lib._

// case class StreamIoBundle[T <: Data](dataType: HardType[T]) extends Bundle {
//   val push = slave Stream (dataType())
//   val pop = master Stream (dataType())
// }

abstract class StreamBase[T <: Data](dataType: HardType[T]) extends Component {
  // val io = StreamIoBundle(dataType)
  val io = new Bundle {
    val push = slave Stream (dataType())
    val pop = master Stream (dataType())
  }
}

class StreamM2S[T <: Data](dataType: HardType[T]) extends StreamBase(dataType) {
  io.pop <-< io.push
}

// class StreamM2S[T <: Data](dataType: HardType[T]) extends Component {
//   val io = new Bundle {
//     val push = slave Stream (dataType())
//     val pop = master Stream (dataType())
//   }
//   io.pop <-< io.push
// }

class StreamS2M[T <: Data](dataType: HardType[T]) extends StreamBase(dataType) {
  io.pop </< io.push
}

class StreamQueue[T <: Data](dataType: HardType[T]) extends StreamBase(dataType) {
  io.pop << io.push.queue(16)
}

class StreamOnly[T <: Data](dataType: HardType[T]) extends StreamBase(dataType) {
  io.pop << io.push
}
