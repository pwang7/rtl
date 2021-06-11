package spinal.exercises.mips32

import scala.sys.process.{Process, ProcessIO}

object ShellRunner{
  def apply(cmds: Seq[String]): Int ={
    doCmd(cmds)
  }

  def doCmd(cmds: Seq[String]): Int ={
    var out, err: String = null
    val io = new ProcessIO(
      stdin  => {
        for (cmd <- cmds)
          stdin.write((cmd + "\n").getBytes)
        stdin.close()
      },
      stdout => {
        out = scala.io.Source.fromInputStream(stdout).getLines.foldLeft("")(_ + "\n" + _)
        stdout.close()
      },
      stderr => {
        err = scala.io.Source.fromInputStream(stderr).getLines.foldLeft("")(_ + "\n" + _)
        stderr.close()
      })
    val proc = Process("sh").run(io)
    // println(s"stdout:\n$out")
    // println(s"stderr:\n$err")
    proc.exitValue()
  }
}
