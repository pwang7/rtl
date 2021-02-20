package spinal.exercises

import org.scalatest.FunSuite

//Just a simple wrapper for scala test purposes
class StreamJoinForkTest extends FunSuite {
  test("pass on bug-free hardware") {
    StreamJoinFork.errorId = 0
    StreamJoinForkSim.main(null)
  }

  test("catch bad xor") {
    intercept [Throwable]{
      StreamJoinFork.errorId = 1
      StreamJoinForkSim.main(null)
    }
  }

  test("catch bad mul") {
    intercept [Throwable]{
      StreamJoinFork.errorId = 2
      StreamJoinForkSim.main(null)
    }
  }

  test("catch cmdA transaction vanish") {
    intercept [Throwable]{
      StreamJoinFork.errorId = 3
      StreamJoinForkSim.main(null)
    }
  }

  StreamJoinFork.errorId = 0
}

