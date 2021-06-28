import std/unittest
import pkg/stew/byteutils
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

  test "can be used to sign messages":
    const message = "hello".toBytes
    let key = PrivateKey.random()
    let signature = key.sign(message)
    check signature != Signature.default

  test "can be used to verify signatures":
    let message1 = "hello".toBytes
    let message2 = "hallo".toBytes
    let private = PrivateKey.random()
    let public = private.toPublicKey
    let signature = private.sign(message1)
    check public.verify(message1, signature)
    check not public.verify(message2, signature)
