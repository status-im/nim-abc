ABC - asynchronous blockchain
=============================

A highly experimental implementation of the permissionless, asynchronous
blockchain architecture as laid out in the [ABC paper][1]. The goal of this
proof-of-concept is to evaluate the practicality and performance of the approach
laid out in the paper.

Usage
-----

Run the unit tests, including performance tests:

`nimble test`

Design
------

Most of the concepts in the paper are fairly easy to implement.
[Transactions](abc/transactions.nim) and [acknowledgements](abc/acks.nim) are
simple data structures. We're using [BLS](abc/keys.nim) signatures so that we
can aggregate all signatures for a transaction into a single signature.

The most tricky part to implement is the algorithm for determining whether a
transaction is confirmed. It depends on the amount of stake that is assigned to
the validators that provided acknowledgements for the transaction, at the time
these acknowledgements were signed. Because these stakes can change with every
transaction, a naive algorithm would have to traverse a large part of the DAG
for every new acknowledgement.

A solution to this problem is implemented in the [transaction
store](abc/txstore.nim). It keeps track of all the [votes](abc/voting.nim) in
favor or against a transaction. When a transaction A assigns stake to a
validator, which in turn acknowledges transaction B, then we count that as a
vote for confirmation of B. When a transaction removes stake from a validator,
then it is counted as a vote against confirmation.

To limit the amount of edges that we have to traverse in the
[DAG](abc/dag/sorteddag.nim) when adding an acknowledgement, we visit the edges
in topological order, and stop when we have enough votes to confirm the
transactions from the acknowledgement. By traversing the DAG in topological
order we avoid counting of stake that is later removed.

To keep the DAG in topological order while we add transactions and
acknowledgments to it, we use the dynamic topological sort algorithm by [Pearce
and
Kelly](https://www.doc.ic.ac.uk/~phjk/Publications/DynamicTopoSortAlg-JEA-07.pdf).

Performance
-----------

Performance measurements are printed as part of the test run. These are very
crude measurements of the individual parts of the ABC design. Realistic
simulations of an ABC network including network latency are left as a future
excercise.

On a single core of an Intel i7-10710U CPU we observed the folowing:

- Transaction hashing (SHA256): ~50 000 hashes per second
- Acknowledgement hashing (SHA256): ~80 0000 hashes per second
- Signing transactions and acknowledgements (BLS): ~1 500 signatures per second
- Adding transactions to the store: ~80 0000 transactions per second
- Adding transaction + acknowledgement to the store: ~15 000 acks per second

Adding transactions and acknowledgements to the store includes topological
sorting and updating of transaction confirmations.

Open Questions
--------------

These questions came up during the creation of this proof-of-concept:

- How can we counter solidification of validator stakes when users lose their
  keys and cannot re-assign stake?
- How can we best add state channels, and cross-chain exchange mechanisms?
- Can we use zero-knowledge proofs to improve privacy and allow smart contracts?
- Is the checkpointing design from the paper implementable, and how much does it
  improve long-term performance?

Preliminary conclusions
-----------------------

From this proof-of-concept we can conclude that the basic ABC architecture can
be implemented, and that it is very likely that it can be made performant. A
number of open questions still need to be answered.

[1]: https://arxiv.org/pdf/1909.10926.pdf
