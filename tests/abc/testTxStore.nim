import abc/txstore
import ./basics
import ./alicebob

suite "Transaction Store":

  let genesis = Transaction.genesis
  let transaction = Transaction.example
  let ack = Ack.example

  test "is initialized with a genesis transaction":
    let store = TxStore.init(genesis)
    check store[genesis.hash] == genesis.some

  test "stores transactions":
    var store = TxStore.init(genesis)
    check store[transaction.hash].isNone
    store.add(transaction)
    check store[transaction.hash] == transaction.some

  test "stores acks":
    var store = TxStore.init(genesis)
    check store[ack.hash].isNone
    store.add(ack)
    check store[ack.hash] == ack.some
