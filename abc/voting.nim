import std/tables
import std/sets
import ./transactions

type
  Voting* = object
    confirmed: HashSet[Hash]
    majority: UInt256
    yea: VoteTable # elector -> voter -> weight
    nay: VoteTable # elector -> voter -> weight
    unconfirmedYea: VoteTable # voter -> elector -> weight
    unconfirmedNay: VoteTable # voter -> elector -> weight
  VoteTable = Table[Hash, Table[Hash, UInt256]]

func init*(_: type Voting, majority: UInt256): Voting =
  Voting(majority: majority)

func `[]=`(table: var VoteTable, a, b: Hash, weight: UInt256) =
  table.mgetOrPut(a, Table[Hash, UInt256].default)[b] = weight

func addYea(voting: var Voting, elector, voter: Hash, weight: UInt256) =
  voting.yea[elector, voter] = weight

func addNay(voting: var Voting, elector, voter: Hash, weight: UInt256) =
  voting.nay[elector, voter] = weight

func addUnconfirmedYea(voting: var Voting,
                       elector, voter: Hash, weight: UInt256) =
  voting.unconfirmedYea[voter, elector] = weight

func addUnconfirmedNay(voting: var Voting,
                       elector, voter: Hash, weight: UInt256) =
  voting.unconfirmedNay[voter, elector] = weight

func sumYea(voting: Voting, elector: Hash): UInt256 =
  if not voting.yea.hasKey(elector):
    return

  for weight in voting.yea[elector].values:
    result += weight

func sumNay(voting: Voting, elector: Hash): UInt256 =
  if not voting.nay.hasKey(elector):
    return

  for weight in voting.nay[elector].values:
    result += weight

func update(voting: var Voting, elector: Hash)

func voteYea*(voting: var Voting, elector, voter: Hash, weight: UInt256) =
  doAssert elector != voter
  if elector in voting.confirmed:
    return

  if voter in voting.confirmed:
    voting.addYea(elector, voter, weight)
    voting.update(elector)
  else:
    voting.addUnconfirmedYea(elector, voter, weight)

func voteNay*(voting: var Voting, elector, voter: Hash, weight: UInt256) =
  doAssert elector != voter
  if elector in voting.confirmed:
    return

  if voter in voting.confirmed:
    voting.addNay(elector, voter, weight)
  else:
    voting.addUnconfirmedNay(elector, voter, weight)

func confirm*(voting: var Voting, transaction: Hash) =
  if transaction in voting.confirmed:
    return

  voting.confirmed.incl(transaction)

  voting.yea.del(transaction)
  voting.nay.del(transaction)

  if voting.unconfirmedNay.hasKey(transaction):
    for (elector, weight) in voting.unconfirmedNay[transaction].pairs:
      voting.addNay(elector, transaction, weight)
    voting.unconfirmedNay.del(transaction)
  if voting.unconfirmedYea.hasKey(transaction):
    for (elector, weight) in voting.unconfirmedYea[transaction].pairs:
      voting.addYea(elector, transaction, weight)
      voting.update(elector)
    voting.unconfirmedYea.del(transaction)

func update(voting: var Voting, elector: Hash) =
  let yea = voting.sumYea(elector)
  let nay = voting.sumNay(elector)
  if yea > nay and yea - nay >= voting.majority:
    voting.confirm(elector)

func outstandingVotes*(voting: Voting): int =
  for votes in voting.yea.values:
    result += votes.len
  for votes in voting.nay.values:
    result += votes.len
  for votes in voting.unconfirmedYea.values:
    result += votes.len
  for votes in voting.unconfirmedNay.values:
    result += votes.len

func isConfirmed*(voting: Voting, transaction: Hash): bool =
  transaction in voting.confirmed
