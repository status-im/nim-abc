import abc/txstore
import ./basics
import ./alicebob

suite "Transaction Store":

  let genesis = Transaction.genesis
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  let vanna = PublicKey.vanna

  test "is initialized with a genesis transaction":
    let store = TxStore.new(genesis)
    check store.getTransaction(genesis.hash) == genesis.some

  test "stores transactions":
    let store = TxStore.new(genesis)
    let transaction = Transaction.example
    check store.getTransaction(transaction.hash).isNone
    store.add(transaction)
    check store.getTransaction(transaction.hash) == transaction.some

  test "stores acks":
    let store = TxStore.new(genesis)
    let ack = Ack.example
    check store.getAck(ack.hash).isNone
    store.add(ack)
    check store.getAck(ack.hash) == ack.some

  test "genesis is confirmed":
    let store = TxStore.new(genesis)
    check store.isConfirmed(genesis.hash)

  test "transaction without acknowledgements is not confirmed":
    let store = TxStore.new(genesis)
    let transaction = Transaction.example
    store.add(transaction)
    check not store.isConfirmed(transaction.hash)

  test "transaction with acknowledgement by all stake is confirmed":
    var tx = !Transaction.init({genesis.hash: bob}, {bob: 100.u256}, victor)
    var ack = !Ack.init([tx.hash], victor)
    PrivateKey.bob.sign(tx)
    PrivateKey.victor.sign(ack)
    let store = TxStore.new(genesis)
    store.add(tx)
    store.add(ack)
    check store.isConfirmed(tx.hash)

  test "transaction with acknowledgements > 2/3 stake is confirmed":
    let genesis = !Transaction.init({alice: 67.u256, bob: 33.u256}, victor)
    var tx1 = !Transaction.init({genesis.hash: alice}, {alice: 67.u256}, vanna)
    var tx2 = !Transaction.init({tx1.hash: alice}, {alice: 67.u256}, victor)
    var ack1 = !Ack.init([tx1.hash], victor)
    var ack2 = !Ack.init([tx2.hash], vanna)
    PrivateKey.alice.sign(tx1)
    PrivateKey.alice.sign(tx2)
    PrivateKey.victor.sign(ack1)
    PrivateKey.vanna.sign(ack2)
    let store = TxStore.new(genesis)
    store.add(tx1, tx2)
    store.add(ack1)
    store.add(ack2)
    check store.isConfirmed(tx2.hash)

  test "transaction with acknowledgements < 2/3 stake is not confirmed":
    let genesis = !Transaction.init({alice: 66.u256, bob: 34.u256}, victor)
    var tx1 = !Transaction.init({genesis.hash: alice}, {alice: 66.u256}, vanna)
    var tx2 = !Transaction.init({tx1.hash: alice}, {alice: 66.u256}, victor)
    var ack1 = !Ack.init([tx1.hash], victor)
    var ack2 = !Ack.init([tx2.hash], vanna)
    PrivateKey.alice.sign(tx1)
    PrivateKey.alice.sign(tx2)
    PrivateKey.victor.sign(ack1)
    PrivateKey.vanna.sign(ack2)
    let store = TxStore.new(genesis)
    store.add(tx1, tx2)
    store.add(ack1)
    store.add(ack2)
    check not store.isConfirmed(tx2.hash)
