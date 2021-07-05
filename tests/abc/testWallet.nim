import ./basics

suite "Wallets":

  let key = PrivateKey.example
  var wallet: Wallet

  setup:
    wallet = Wallet.init(key)

  test "wallet is created from private key":
    check wallet.id == key.toPublicKey

  test "wallet can sign transaction":
    var transaction = Transaction.example
    check transaction.signature == Signature.default
    wallet.sign(transaction)
    check transaction.signature == key.sign(transaction.hash.toBytes)

  test "wallet can sign acknowledgment":
    var ack = Ack.example
    check ack.signature.isNone
    wallet.sign(ack)
    check ack.signature == key.sign(ack.hash.toBytes).some
