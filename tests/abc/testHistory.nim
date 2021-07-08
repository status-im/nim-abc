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
    PrivateKey.alice.sign(tx1)
    PrivateKey.bob.sign(tx2)
    PrivateKey.alice.sign(tx3)
    PrivateKey.bob.sign(tx3)
    PrivateKey.victor.sign(ack1)
    PrivateKey.victor.sign(ack2)
    PrivateKey.victor.sign(ack3)

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

suite "Transaction validation":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  let genesis = Transaction.genesis
  var tx1, tx2: Transaction

  setup:
    tx1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256}, victor)
    tx2 = !Transaction.init({tx1.hash: bob}, {alice: 100.u256}, victor)
    PrivateKey.alice.sign(tx1)
    PrivateKey.bob.sign(tx2)

  test "checks validity of transactions":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2)
    check isValid store.past(genesis.hash)
    check isValid store.past(tx1.hash)
    check isValid store.past(tx2.hash)

  test "checks that no input is missing":
    var store = TxStore.init(genesis)
    store.add(tx2) # tx2 depends on tx1, which is missing
    check not isValid store.past(tx2.hash)

  test "checks that inputs and outputs match":
    var store = TxStore.init(genesis)
    var bad1 = !Transaction.init({genesis.hash: alice}, {bob: 999.u256}, victor)
    var bad2 = !Transaction.init({bad1.hash: bob}, {alice: 999.u256}, victor)
    PrivateKey.alice.sign(bad1)
    PrivateKey.bob.sign(bad2)
    store.add(bad1, bad2)
    check not isValid store.past(bad1.hash)
    check not isValid store.past(bad2.hash)

  test "checks that signatures match":
    var store = TxStore.init(genesis)
    var bad1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256}, victor)
    var bad2 = !Transaction.init({bad1.hash: bob}, {alice: 100.u256}, victor)
    PrivateKey.bob.sign(bad1) # invalid signature, should be signed by alice
    PrivateKey.bob.sign(bad2)
    store.add(bad1, bad2)
    check not isValid store.past(bad1.hash)
    check not isValid store.past(bad2.hash)

suite "Acknowledgement validation":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  let genesis = Transaction.genesis
  var tx1, tx2: Transaction
  var ack1, ack2: Ack

  setup:
    tx1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256}, victor)
    tx2 = !Transaction.init({tx1.hash: bob}, {alice: 100.u256}, victor)
    ack1 = !Ack.init([tx1.hash], victor)
    ack2 = !Ack.init(ack1.hash, [tx2.hash], victor)
    PrivateKey.alice.sign(tx1)
    PrivateKey.bob.sign(tx2)
    PrivateKey.victor.sign(ack1)
    PrivateKey.victor.sign(ack2)

  test "checks validity of acknowledgements":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2)
    store.add(ack1, ack2)
    check isValid store.past(ack1.hash)
    check isValid store.past(ack2.hash)

  test "checks that no previous acknowledgement is missing":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2)
    store.add(ack2) # ack2 depends on ack1, which is missing
    check not isValid store.past(ack2.hash)

  test "checks that no transaction is missing":
    var store = TxStore.init(genesis)
    store.add(tx2) # tx2 depends on tx1, which is missing
    store.add(ack1, ack2)
    check not isValid store.past(ack2.hash)

  test "checks that no transaction is invalid":
    var store = TxStore.init(genesis)
    var bad = !Transaction.init({genesis.hash: alice}, {bob: 999.u256}, victor)
    var ack = !Ack.init([bad.hash], victor)
    PrivateKey.alice.sign(bad)
    PrivateKey.victor.sign(ack)
    store.add(bad)
    store.add(ack)
    check not isValid store.past(ack.hash)

  test "checks that signatures match":
    var store = TxStore.init(genesis)
    var bad1 = !Ack.init([tx1.hash], victor)
    var bad2 = !Ack.init(bad1.hash, [tx2.hash], victor)
    PrivateKey.bob.sign(bad1) # invalid signature, should be signed by victor
    PrivateKey.victor.sign(bad2)
    store.add(tx1, tx2)
    store.add(bad1, bad2)
    check not isValid store.past(bad1.hash)
    check not isValid store.past(bad2.hash)

  test "checks validity of a set of acknowledgements":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2)
    store.add(ack2)
    check not isValid store.past(ack1.hash, ack2.hash)
    store.add(ack1)
    check isValid store.past(ack1.hash, ack2.hash)
