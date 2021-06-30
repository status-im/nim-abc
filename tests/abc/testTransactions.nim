import ./basics
import ./alicebob

suite "Transactions":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor

  test "a genesis transaction can be made":
    let genesis = Transaction.init({alice: 32.u256, bob: 10.u256}, victor)
    check genesis.isSome

  test "a transaction has a hash":
    let transaction1, transaction2 = Transaction.example
    check transaction1.hash == transaction1.hash
    check transaction2.hash == transaction2.hash
    check transaction1.hash != transaction2.hash

  test "a transaction references outputs from other transactions":
    let genesis = !Transaction.init({alice: 32.u256, bob: 10.u256}, victor)
    let transaction = !Transaction.init(
      {genesis.hash: alice},
      {alice: 2.u256, bob: 30.u256},
      victor
    )
    check transaction.inputs.len == 1
    check transaction.outputs.len == 2

  test "a transaction can be converted to bytes":
    let genesis = !Transaction.init({alice: 32.u256, bob: 10.u256}, victor)
    let transaction = !Transaction.init(
      {genesis.hash: alice},
      {alice: 2.u256, bob: 30.u256},
      victor
    )
    var expected: seq[byte]
    expected.add(1) # amount of inputs
    expected.add(genesis.hash.toBytes)
    expected.add(alice.toBytes)
    expected.add(2) # amount of outputs
    expected.add(alice.toBytes)
    expected.add(2.u256.toBytes)
    expected.add(bob.toBytes)
    expected.add(30.u256.toBytes)
    expected.add(victor.toBytes)
    check transaction.toBytes == expected

  test "signatures can be added to a transaction":
    let key1, key2 = PrivateKey.example
    var transaction = Transaction.example
    let sig1 = key1.sign(transaction.hash.toBytes)
    let sig2 = key2.sign(transaction.hash.toBytes)
    transaction.add(sig1)
    check transaction.signature == sig1
    transaction.add(sig2)
    check transaction.signature == aggregate(sig1, sig2)

  test "transaction can be signed by a private key":
    let key = PrivateKey.example
    var transaction = Transaction.example
    key.sign(transaction)
    check transaction.signature == key.sign(transaction.hash.toBytes)

  test "transaction signature can be checked for validity":
    let genesis = !Transaction.init({alice: 32.u256, bob: 10.u256}, victor)
    check not genesis.hasValidSignature()
    var transaction = !Transaction.init(
      {genesis.hash: alice},
      {alice: 2.u256, bob: 30.u256},
      victor
    )
    let hash = transaction.hash.toBytes
    check not transaction.hasValidSignature
    transaction.add(PrivateKey.alice.sign(hash))
    check transaction.hasValidSignature
    transaction.add(PrivateKey.bob.sign(hash))
    check not transaction.hasValidSignature

  test "transaction must have at least one output":
    check Transaction.init([], victor).isNone

  test "multiple outputs to the same owner are not allowed":
    check Transaction.init({alice: 40.u256, alice: 2.u256}, victor).isNone
