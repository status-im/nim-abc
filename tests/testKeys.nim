import std/unittest
import pkg/questionable
import pkg/stew/byteutils
import abc/keys
import ./examples

suite "Keys":

  test "generates random private keys":
    check PrivateKey.random != PrivateKey.random

  test "erases memory associated with a private key":
    var key = PrivateKey.example
    let bytes = cast[ptr[uint64]](addr key)
    check bytes[] != 0
    erase key
    check bytes[] == 0

  test "derives public key from private key":
    let key1, key2 = PrivateKey.example
    check key1.toPublicKey == key1.toPublicKey
    check key2.toPublicKey == key2.toPublicKey
    check key1.toPublicKey != key2.toPublicKey

  test "can be used to sign messages":
    const message = "hello".toBytes
    let key = PrivateKey.example
    let signature = key.sign(message)
    check signature != Signature.default

  test "can be used to verify signatures":
    let message1 = "hello".toBytes
    let message2 = "hallo".toBytes
    let private = PrivateKey.example
    let public = private.toPublicKey
    let signature = private.sign(message1)
    check public.verify(message1, signature)
    check not public.verify(message2, signature)

  test "public key can be converted to bytes":
    let key = PublicKey.example
    let bytes = key.toBytes
    check PublicKey.fromBytes(bytes) == key.some

  test "conversion from bytes to public key can fail":
    let key = PublicKey.example
    let bytes = key.toBytes
    let invalid = bytes[1..^1]
    check PublicKey.fromBytes(invalid) == PublicKey.none

  test "public keys can be aggregated":
    let key1, key2, key3 = PublicKey.example
    check aggregate(key1, key2) != aggregate(key1, key3)
    check aggregate(key1, key2) == aggregate(key2, key1)
    check aggregate(PublicKey.default, key1) == key1
    check aggregate(aggregate(key1, key2), key3) == aggregate(key1, key2, key3)

  test "signatures can be aggregated":
    let key1, key2 = PrivateKey.example
    let message = "hello".toBytes
    let sig1 = key1.sign(message)
    let sig2 = key2.sign(message)
    let aggregateKey = aggregate(key1.toPublicKey, key2.toPublicKey)
    let aggregateSig = aggregate(sig1, sig2)
    check aggregateKey.verify(message, aggregateSig)
