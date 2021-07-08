import abc/txstore
import abc/past
import ./basics
import ./alicebob

suite "Past transactions and acknowledgements":

  let genesis = Transaction.genesis
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  var tx1, tx2, tx3: Transaction
  var ack1, ack2: Ack

  setup:
    tx1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256}, victor)
    tx2 = !Transaction.init({genesis.hash: bob}, {alice: 100.u256}, victor)
    tx3 = !Transaction.init(
      {tx1.hash: bob, tx2.hash: alice},
      {alice: 200.u256},
      victor
    )
    ack1 = !Ack.init([tx1.hash, tx2.hash], victor)
    ack2 = !Ack.init(ack1.hash, [tx3.hash], victor)

  test "finds all transactions that precede a transaction":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2, tx3)
    check store.past(tx1.hash) == [genesis.hash]
    check store.past(tx2.hash) == [genesis.hash]
    check store.past(tx3.hash) == [tx1.hash, genesis.hash, tx2.hash]

  test "past is empty when transaction cannot be found":
    let store = TxStore.init(genesis)
    check store.past(tx1.hash) == []

  test "finds all transactions that precede an acknowledgement":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2, tx3)
    store.add(ack1, ack2)
    check store.past(ack1.hash) == [tx1.hash, genesis.hash, tx2.hash]
    check store.past(ack2.hash) == [tx1.hash, genesis.hash, tx2.hash, tx3.hash]
