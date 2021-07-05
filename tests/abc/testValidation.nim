import abc/txstore
import abc/validation
import ./basics
import ./alicebob

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
    check store.hasValidTx(genesis.hash)
    check store.hasValidTx(tx1.hash)
    check store.hasValidTx(tx2.hash)

  test "checks that no input is missing":
    var store = TxStore.init(genesis)
    store.add(tx2) # tx2 depends on tx1, which is missing
    check not store.hasValidTx(tx2.hash)

  test "checks that inputs and outputs match":
    var store = TxStore.init(genesis)
    var bad1 = !Transaction.init({genesis.hash: alice}, {bob: 999.u256}, victor)
    var bad2 = !Transaction.init({bad1.hash: bob}, {alice: 999.u256}, victor)
    PrivateKey.alice.sign(bad1)
    PrivateKey.bob.sign(bad2)
    store.add(bad1, bad2)
    check not store.hasValidTx(bad1.hash)
    check not store.hasValidTx(bad2.hash)

  test "checks that signatures match":
    var store = TxStore.init(genesis)
    var bad1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256}, victor)
    var bad2 = !Transaction.init({bad1.hash: bob}, {alice: 100.u256}, victor)
    PrivateKey.bob.sign(bad1) # invalid signature, should be signed by alice
    PrivateKey.bob.sign(bad2)
    store.add(bad1, bad2)
    check not store.hasValidTx(bad1.hash)
    check not store.hasValidTx(bad2.hash)

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
    check store.hasValidAck(ack1.hash)
    check store.hasValidAck(ack2.hash)

  test "checks that no previous acknowledgement is missing":
    var store = TxStore.init(genesis)
    store.add(tx1, tx2)
    store.add(ack2) # ack2 depends on ack1, which is missing
    check not store.hasValidAck(ack2.hash)

  test "checks that no transaction is missing":
    var store = TxStore.init(genesis)
    store.add(tx2) # tx2 depends on tx1, which is missing
    store.add(ack1, ack2)
    check not store.hasValidAck(ack2.hash)

  test "checks that no transaction is invalid":
    var store = TxStore.init(genesis)
    var bad = !Transaction.init({genesis.hash: alice}, {bob: 999.u256}, victor)
    var ack = !Ack.init([bad.hash], victor)
    PrivateKey.alice.sign(bad)
    PrivateKey.victor.sign(ack)
    store.add(bad)
    store.add(ack)
    check not store.hasValidAck(ack.hash)

  test "checks that signatures match":
    var store = TxStore.init(genesis)
    var bad1 = !Ack.init([tx1.hash], victor)
    var bad2 = !Ack.init(bad1.hash, [tx2.hash], victor)
    PrivateKey.bob.sign(bad1) # invalid signature, should be signed by victor
    PrivateKey.victor.sign(bad2)
    store.add(tx1, tx2)
    store.add(bad1, bad2)
    check not store.hasValidAck(bad1.hash)
    check not store.hasValidAck(bad2.hash)
