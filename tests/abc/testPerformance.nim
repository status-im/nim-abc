import std/times
import std/strutils
import abc/txstore
import ./basics
import ./alicebob

suite "Performance":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor

  template repeat(timespan, body): int =
    var count = 0
    let start = now()
    while (now() - start) < timespan:
      body
      inc count
    count - 1

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

  proc generateTransactions(amount: int): seq[Transaction] =
    var tx = Transaction.genesis
    var payer = alice
    var receiver = bob
    for _ in 0..<amount:
      tx = !Transaction.new({tx.hash: payer}, {receiver: 100.u256}, victor)
      result.add(tx)
      (payer, receiver) = (receiver, payer)

  test "add transaction to store":
    let transactions = generateTransactions(10_000)
    var store = TxStore.new(Transaction.genesis)
    var index = 0
    for _ in 0..<4:
      let count = repeat(initDuration(milliseconds = 10)):
        store.add(transactions[index])
        inc index
      statistic "transactions per second", count * 100
