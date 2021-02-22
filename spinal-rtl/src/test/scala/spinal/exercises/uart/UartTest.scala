package spinal.exercises.uart

import org.scalatest.FunSuite

class UartTest extends FunSuite {
  test("Uart Loopback test") {
    UartSim.main(null)
  }
}
