import ./basics
import std/times

suite "Performance":

  template repeat(timespan, body): int =
    var count = 0
    let start = now()
    while (now() - start) < timespan:
      body
      inc count
    count

  test "transaction hashing":
    let transaction = Transaction.example
    let count = repeat(initDuration(milliseconds = 10)):
      transaction.calculateHash()
    echo "  hashes per second: ", count * 100

  test "acknowledgement hashing":
    let ack = Ack.example
    let count = repeat(initDuration(milliseconds = 10)):
      ack.calculateHash()
    echo "  hashes per second: ", count * 100

  test "signing":
    var transaction = Transaction.example
    let wallet = Wallet.example
    let count = repeat(initDuration(milliseconds = 10)):
      wallet.sign(transaction)
    echo "  signatures per second: ", count * 100
