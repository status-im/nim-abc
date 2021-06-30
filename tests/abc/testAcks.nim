import abc/acks
import ./basics
import ./alicebob

suite "Acknowledgements":

  let tx1, tx2 = Transaction.example

  test "a first acknowledgement can be made":
    let ack = Ack.init([tx1.hash, tx2.hash])
    check ack.isSome
    check ack.?transactions == @[tx1.hash, tx2.hash].some
    check ack.?previous == Hash.none

  test "an acknowledgement has a hash":
    let ack1, ack2 = Ack.example
    check ack1.hash == ack1.hash
    check ack2.hash == ack2.hash
    check ack1.hash != ack2.hash

  test "an acknowledgement references a previous acknowledgement":
    let previous = Ack.example
    let ack = Ack.init(previous.hash, [tx1.hash, tx2.hash])
    check ack.isSome
    check ack.?transactions == @[tx1.hash, tx2.hash].some
    check ack.?previous == previous.hash.some

  test "an acknowledgement can be converted to bytes":
    let previous = Ack.example
    let ack = !Ack.init(previous.hash, [tx1.hash, tx2.hash])
    var expected: seq[byte]
    expected.add(previous.hash.toBytes)
    expected.add(2) # amount of transactions
    expected.add(tx1.hash.toBytes)
    expected.add(tx2.hash.toBytes)
    check ack.toBytes == expected

  test "a signature can be added to an acknowledgment":
    let key = PrivateKey.example
    var ack = Ack.example
    let signature = key.sign(ack.hash.toBytes)
    ack.signature = signature
    check ack.signature == signature.some

  test "an acknowledgement can be signed by a private key":
    let key = PrivateKey.example
    var ack = Ack.example
    key.sign(ack)
    check ack.signature == key.sign(ack.hash.toBytes).some

  test "an acknowledgement must contain at least one transaction":
    let previous = Ack.example
    check Ack.init(previous.hash, []).isNone
