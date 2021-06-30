import abc/txstore
import abc/txvalidation
import ./basics
import ./alicebob

suite "Transaction validation":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let genesis = Transaction.genesis
  var tx1, tx2: Transaction

  setup:
    tx1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256})
    tx2 = !Transaction.init({tx1.hash: bob}, {alice: 100.u256})
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
    var invalid1 = !Transaction.init({genesis.hash: alice}, {bob: 999.u256})
    var invalid2 = !Transaction.init({invalid1.hash: bob}, {alice: 999.u256})
    PrivateKey.alice.sign(invalid1)
    PrivateKey.bob.sign(invalid2)
    store.add(invalid1, invalid2)
    check not store.hasValidTx(invalid1.hash)
    check not store.hasValidTx(invalid2.hash)

  test "checks that signatures match":
    var store = TxStore.init(genesis)
    var invalid1 = !Transaction.init({genesis.hash: alice}, {bob: 100.u256})
    var invalid2 = !Transaction.init({invalid1.hash: bob}, {alice: 100.u256})
    PrivateKey.bob.sign(invalid1) # invalid signature, should be signed by alice
    PrivateKey.bob.sign(invalid2)
    store.add(invalid1, invalid2)
    check not store.hasValidTx(invalid1.hash)
    check not store.hasValidTx(invalid2.hash)
