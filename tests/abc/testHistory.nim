import abc/txstore
import abc/history
import ./basics
import ./alicebob

func set[T](elements: varargs[T]): HashSet[T] =
  elements.toHashSet

suite "Past transactions and acknowledgements":

  let genesis = Transaction.genesis
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  var store: TxStore
  var tx1, tx2, tx3: Transaction
  var ack1, ack2, ack3: Ack

  setup:
    store = TxStore.new(genesis)
    tx1 = !Transaction.new({genesis.hash: alice}, {bob: 100.u256}, victor)
    tx2 = !Transaction.new({genesis.hash: bob}, {alice: 100.u256}, victor)
    tx3 = !Transaction.new(
      {tx1.hash: bob, tx2.hash: alice},
      {alice: 200.u256},
      victor
    )
    ack1 = !Ack.new([tx1.hash], victor)
    ack2 = !Ack.new([tx2.hash], victor)
    ack3 = !Ack.new(ack1.hash, [tx2.hash, tx3.hash], victor)
    PrivateKey.alice.sign(tx1)
    PrivateKey.bob.sign(tx2)
    PrivateKey.alice.sign(tx3)
    PrivateKey.bob.sign(tx3)
    PrivateKey.victor.sign(ack1)
    PrivateKey.victor.sign(ack2)
    PrivateKey.victor.sign(ack3)

  test "finds all transactions that precede a transaction":
    store.add(tx1, tx2, tx3)
    check store.past(tx1.hash).transactions == set(genesis.hash)
    check store.past(tx2.hash).transactions == set(genesis.hash)
    check store.past(tx3.hash).transactions ==
      set(genesis.hash, tx1.hash, tx2.hash)

  test "past is empty when transaction cannot be found":
    check store.past(tx1.hash).transactions == set[Hash]()

  test "finds all transactions that precede an acknowledgement":
    store.add(tx1, tx2, tx3)
    store.add(ack1, ack2, ack3)
    check store.past(ack1.hash).transactions == set(genesis.hash, tx1.hash)
    check store.past(ack2.hash).transactions == set(genesis.hash, tx2.hash)
    check store.past(ack3.hash).transactions ==
      set(genesis.hash, tx1.hash, tx2.hash, tx3.hash)

  test "finds all transactions that precede a set of acknowledgements":
    store.add(tx1, tx2, tx3)
    store.add(ack1, ack2, ack3)
    check store.past(ack1.hash, ack2.hash).transactions ==
      set(genesis.hash, tx1.hash, tx2.hash)

  test "past contains the genesis hash":
    store.add(tx1, tx3)
    store.add(ack3)
    check store.past(tx1.hash).genesis == store.genesis
    check store.past(tx3.hash).genesis == store.genesis
    check store.past(ack3.hash).genesis == store.genesis

suite "Transaction validation":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  let genesis = Transaction.genesis
  var store: TxStore
  var tx1, tx2: Transaction

  setup:
    store = TxStore.new(genesis)
    tx1 = !Transaction.new({genesis.hash: alice}, {bob: 100.u256}, victor)
    tx2 = !Transaction.new({tx1.hash: bob}, {alice: 100.u256}, victor)
    PrivateKey.alice.sign(tx1)
    PrivateKey.bob.sign(tx2)

  test "checks validity of transactions":
    store.add(tx1, tx2)
    check isValid store.past(genesis.hash)
    check isValid store.past(tx1.hash)
    check isValid store.past(tx2.hash)

  test "checks that no input is missing":
    store.add(tx2) # tx2 depends on tx1, which is missing
    let past = store.past(tx2.hash)
    check not isValid past
    check past.missing == set(tx1.hash)

  test "checks that inputs and outputs match":
    var bad1 = !Transaction.new({genesis.hash: alice}, {bob: 999.u256}, victor)
    var bad2 = !Transaction.new({bad1.hash: bob}, {alice: 999.u256}, victor)
    PrivateKey.alice.sign(bad1)
    PrivateKey.bob.sign(bad2)
    store.add(bad1, bad2)
    for transaction in [bad1, bad2]:
      let past = store.past(transaction.hash)
      check not isValid past
      check past.invalid == set(bad1.hash)

  test "checks that signatures match":
    var bad1 = !Transaction.new({genesis.hash: alice}, {bob: 100.u256}, victor)
    var bad2 = !Transaction.new({bad1.hash: bob}, {alice: 100.u256}, victor)
    PrivateKey.bob.sign(bad1) # invalid signature, should be signed by alice
    PrivateKey.bob.sign(bad2)
    store.add(bad1, bad2)
    for transaction in [bad1, bad2]:
      let past = store.past(transaction.hash)
      check not isValid past
      check past.invalid == set(bad1.hash)

suite "Acknowledgement validation":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  let genesis = Transaction.genesis
  var store: TxStore
  var tx1, tx2: Transaction
  var ack1, ack2: Ack

  setup:
    store = TxStore.new(genesis)
    tx1 = !Transaction.new({genesis.hash: alice}, {bob: 100.u256}, victor)
    tx2 = !Transaction.new({tx1.hash: bob}, {alice: 100.u256}, victor)
    ack1 = !Ack.new([tx1.hash], victor)
    ack2 = !Ack.new(ack1.hash, [tx2.hash], victor)
    PrivateKey.alice.sign(tx1)
    PrivateKey.bob.sign(tx2)
    PrivateKey.victor.sign(ack1)
    PrivateKey.victor.sign(ack2)

  test "checks validity of acknowledgements":
    store.add(tx1, tx2)
    store.add(ack1, ack2)
    check isValid store.past(ack1.hash)
    check isValid store.past(ack2.hash)

  test "checks that no previous acknowledgement is missing":
    store.add(tx1, tx2)
    store.add(ack2) # ack2 depends on ack1, which is missing
    let past = store.past(ack2.hash)
    check not isValid past
    check past.missing == set(ack1.hash)

  test "checks that no transaction is missing":
    store.add(tx2) # tx2 depends on tx1, which is missing
    store.add(ack1, ack2)
    let past = store.past(ack2.hash)
    check not isValid past
    check past.missing == set(tx1.hash)

  test "checks that no transaction is invalid":
    var bad = !Transaction.new({genesis.hash: alice}, {bob: 999.u256}, victor)
    var ack = !Ack.new([bad.hash], victor)
    PrivateKey.alice.sign(bad)
    PrivateKey.victor.sign(ack)
    store.add(bad)
    store.add(ack)
    let past = store.past(ack.hash)
    check not isValid past
    check past.invalid == set(bad.hash)

  test "checks that signatures match":
    var bad1 = !Ack.new([tx1.hash], victor)
    var bad2 = !Ack.new(bad1.hash, [tx2.hash], victor)
    PrivateKey.bob.sign(bad1) # invalid signature, should be signed by victor
    PrivateKey.victor.sign(bad2)
    store.add(tx1, tx2)
    store.add(bad1, bad2)
    for ack in [bad1, bad2]:
      let past = store.past(ack.hash)
      check not isValid past
      check past.invalid == set(bad1.hash)

  test "checks validity of a set of acknowledgements":
    store.add(tx1, tx2)
    store.add(ack2)
    check not isValid store.past(ack1.hash, ack2.hash)
    store.add(ack1)
    check isValid store.past(ack1.hash, ack2.hash)
