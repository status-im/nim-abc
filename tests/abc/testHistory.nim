import abc/txstore
import abc/history
import ./basics
import ./alicebob

suite "Past transactions and acknowledgements":

  let genesis = Transaction.genesis
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  var tx1, tx2, tx3: Transaction
  var ack1, ack2, ack3: Ack

  setup:
    tx1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256}, victor)
    tx2 = !Transaction.init({genesis.hash: bob}, {alice: 100.u256}, victor)
    tx3 = !Transaction.init(
      {tx1.hash: bob, tx2.hash: alice},
      {alice: 200.u256},
      victor
    )
    ack1 = !Ack.init([tx1.hash], victor)
    ack2 = !Ack.init([tx2.hash], victor)
    ack3 = !Ack.init(ack1.hash, [tx2.hash, tx3.hash], victor)

  func set(transactions: varargs[TxHash]): HashSet[TxHash] =
    transactions.toHashSet

  test "finds all transactions that precede a transaction":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2, tx3)
    check store.past(tx1.hash).transactions == set(genesis.hash)
    check store.past(tx2.hash).transactions == set(genesis.hash)
    check store.past(tx3.hash).transactions ==
      set(genesis.hash, tx1.hash, tx2.hash)

  test "past is empty when transaction cannot be found":
    let store = TxStore.init(genesis)
    check store.past(tx1.hash).transactions == set()

  test "finds all transactions that precede an acknowledgement":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2, tx3)
    store.add(ack1, ack2, ack3)
    check store.past(ack1.hash).transactions == set(genesis.hash, tx1.hash)
    check store.past(ack2.hash).transactions == set(genesis.hash, tx2.hash)
    check store.past(ack3.hash).transactions ==
      set(genesis.hash, tx1.hash, tx2.hash, tx3.hash)

  test "finds all transactions that precede a set of acknowledgements":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2, tx3)
    store.add(ack1, ack2, ack3)
    check store.past(ack1.hash, ack2.hash).transactions ==
      set(genesis.hash, tx1.hash, tx2.hash)
