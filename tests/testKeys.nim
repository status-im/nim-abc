import std/unittest
import abc/keys

suite "Keys":

  test "generates random private keys":
    check PrivateKey.random != PrivateKey.random

  test "erases memory associated with a private key":
    var key = PrivateKey.random
    let bytes = cast[ptr[uint64]](addr key)
    check bytes[] != 0
    erase key
    check bytes[] == 0

  test "derives public key from private key":
    let key1, key2 = PrivateKey.random()
    check key1.toPublicKey == key1.toPublicKey
    check key2.toPublicKey == key2.toPublicKey
    check key1.toPublicKey != key2.toPublicKey
