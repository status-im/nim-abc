import ./basics
import abc/voting

suite "Voting":

  let majority = 67.u256
  var voting: Voting

  setup:
    voting = Voting.init(majority)

  test "transactions can be confirmed directly (genesis)":
    let tx = Transaction.example.hash
    check not voting.isConfirmed(tx)
    voting.confirm(tx)
    check voting.isConfirmed(tx)

  test "transactions can be confirmed when majority votes yea":
    let tx1, tx2, tx3 = Transaction.example.hash
    voting.confirm(tx1)
    voting.confirm(tx2)
    voting.voteYea(tx3, tx1, 66.u256)
    check not voting.isConfirmed(tx3)
    voting.voteYea(tx3, tx2, 1.u256)
    check voting.isConfirmed(tx3)

  test "transactions remain unconfirmed when nays outweigh yeas":
    let tx1, tx2, tx3 = Transaction.example.hash
    voting.confirm(tx1)
    voting.confirm(tx2)
    voting.voteNay(tx3, tx1, 34.u256)
    voting.voteYea(tx3, tx2, 100.u256)
    check not voting.isConfirmed(tx3)

  test "votes from unconfirmed transaction do not count":
    let tx1, tx2 = Transaction.example.hash
    voting.voteYea(tx2, tx1, 100.u256)
    check not voting.isConfirmed(tx2)

  test "when a transaction is confirmed its votes are taken into account":
    let tx1, tx2, tx3 = Transaction.example.hash
    voting.voteYea(tx2, tx1, 100.u256)
    voting.voteYea(tx3, tx2, 100.u256)
    check not voting.isConfirmed(tx2)
    check not voting.isConfirmed(tx3)
    voting.confirm(tx1)
    check voting.isConfirmed(tx2)
    check voting.isConfirmed(tx3)

  test "outstanding votes are removed when a transaction is confirmed":
    let tx1, tx2, tx3 = Transaction.example.hash
    voting.voteYea(tx2, tx1, 100.u256)
    voting.voteYea(tx3, tx2, 100.u256)
    check voting.outstandingVotes == 2
    voting.confirm(tx1)
    check voting.outstandingVotes == 0

  test "a transaction can vote both nay and yay with different weights":
    let tx1, tx2 = Transaction.example.hash
    voting.confirm(tx1)
    voting.voteNay(tx2, tx1, 33.u256)
    check not voting.isConfirmed(tx2)
    voting.voteYea(tx2, tx1, 100.u256)
    check voting.isConfirmed(tx2)
