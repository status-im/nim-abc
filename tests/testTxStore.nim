import abc/txstore
import ./basics
import ./alicebob

suite "Transaction Store":

  let genesis = Transaction.genesis
  let transaction = Transaction.example

  test "is initialized with a genesis transaction":
    let store = TxStore.init(genesis)
    check store.hasTx(genesis.hash)
    check store[genesis.hash] == genesis

  test "stores transactions":
    var store = TxStore.init(genesis)
    check not store.hasTx(transaction.hash)
    store.add(transaction)
    check store.hasTx(transaction.hash)
    check store[transaction.hash] == transaction
