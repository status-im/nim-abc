import abc/keys

proc example*(_: type PrivateKey): PrivateKey =
  PrivateKey.random

proc example*(_: type PublicKey): PublicKey =
  PrivateKey.example.toPublicKey
