package spinal.exercises

import org.scalatest.FunSuite

import spinal.core._
import spinal.core.sim._
import spinal.lib._
import spinal.sim._

import testutils.CocotbRunner

//Run this scala test to generate and check that your RTL work correctly
class UdpAppSelfTester extends FunSuite{
  test("test") {
    // SpinalConfig(targetDirectory = "rtl").dumpWave(0,"../../../../../../waves/UdpAppSelfTester.vcd").generateVerilog(
    //   UdpApp(udpPort = 37984)
    // )

    val compiled = SimConfig.withWave.compile(
      rtl = new UdpApp(udpPort = 37984)
    )
    assert(CocotbRunner("./src/test/python/udp/selftested"), "Simulation faild")
    println("SUCCESS")
  }
}
