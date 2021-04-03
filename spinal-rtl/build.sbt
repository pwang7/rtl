name := "spinal-rtl"

version := "0.1.0"

scalaVersion := "2.12.13"
val spinalVersion = "1.4.3"

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "3.0.8" % "test",
  "com.github.spinalhdl" % "spinalhdl-core_2.11" % spinalVersion,
  "com.github.spinalhdl" % "spinalhdl-lib_2.11"  % spinalVersion,
  compilerPlugin("com.github.spinalhdl" % "spinalhdl-idsl-plugin_2.11" % spinalVersion),
)

fork := true
