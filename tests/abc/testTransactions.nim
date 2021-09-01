import ./basics
import ./alicebob

suite "Transactions":

  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor

  test "a genesis transaction can be made":
    let genesis = Transaction.new({alice: 32.u256, bob: 10.u256}, victor)
    check genesis.isSome

  test "a transaction has a hash":
    let transaction1, transaction2 = Transaction.example
    check transaction1.hash == transaction1.hash
    check transaction2.hash == transaction2.hash
    check transaction1.hash != transaction2.hash

  test "a transaction references outputs from other transactions":
    let genesis = !Transaction.new({alice: 32.u256, bob: 10.u256}, victor)
    let transaction = !Transaction.new(
      {genesis.hash: alice},
      {alice: 2.u256, bob: 30.u256},
      victor
    )
    check transaction.inputs.len == 1
    check transaction.outputs.len == 2

  test "transaction value is the sum of its output values":
    let genesis = !Transaction.new({alice: 32.u256, bob: 10.u256}, victor)
    check genesis.value == 42.u256

  test "output value is the value of the output for given owner":
    let genesis = !Transaction.new({alice: 32.u256, bob: 10.u256}, victor)
    check genesis.outputValue(alice) == 32.u256
    check genesis.outputValue(bob) == 10.u256
    check genesis.outputValue(victor) == 0.u256

  test "a transaction hash is derived from its fields":
    let genesis = !Transaction.new({alice: 32.u256, bob: 10.u256}, victor)
    let transaction = !Transaction.new(
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
    check transaction.hash == hash(expected, HashKind.Tx)

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
    let genesis = !Transaction.new({alice: 32.u256, bob: 10.u256}, victor)
    check not genesis.hasValidSignature()
    var transaction = !Transaction.new(
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
    check Transaction.new([], victor).isNone

  test "multiple outputs to the same owner are not allowed":
    check Transaction.new({alice: 40.u256, alice: 2.u256}, victor).isNone

  test "inputs must have correct hash kind":
    let invalid = Ack.example
    check Transaction.new({invalid.hash: alice}, {bob: 1.u256}, victor).isNone
