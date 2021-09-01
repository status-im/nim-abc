import std/times
import std/strutils
import ./basics

suite "Performance":

  template repeat(timespan, body): int =
    var count = 0
    let start = now()
    while (now() - start) < timespan:
      body
      inc count
    count

  template statistic(name, value) =
    echo "  ", alignLeft(name & ":", 30), " ", align($value, 7)

  test "transaction hashing":
    let transaction = Transaction.example
    let count = repeat(initDuration(milliseconds = 10)):
      transaction.calculateHash()
    statistic "hashes per second", count * 100

  test "acknowledgement hashing":
    let ack = Ack.example
    let count = repeat(initDuration(milliseconds = 10)):
      ack.calculateHash()
    statistic "hashes per second", count * 100

  test "signing":
    var transaction = Transaction.example
    let wallet = Wallet.example
    let count = repeat(initDuration(milliseconds = 10)):
      wallet.sign(transaction)
    statistic "signatures per second", count * 100
