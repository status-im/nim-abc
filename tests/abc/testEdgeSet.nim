import std/sequtils
import std/random
import abc/dag/edgeset
import ./basics

suite "DAG edge set":

  var edges: EdgeSet[string]

  setup:
    edges = EdgeSet[string].init()

  test "contains edges":
    edges.incl( ("a", "b") )
    check ("a", "b") in edges
    check not ( ("a", "c") in edges )
    check not ( ("b", "a") in edges )

  test "iterates over outgoing edges":
    edges.incl( ("a", "b") )
    edges.incl( ("b", "c") )
    edges.incl( ("a", "c") )
    let neighboursA = toSeq(edges.outgoing("a"))
    let neighboursB = toSeq(edges.outgoing("b"))
    let neighboursC = toSeq(edges.outgoing("c"))
    check neighboursA.len == 2
    check neighboursB.len == 1
    check neighboursC.len == 0
    check "b" in neighboursA and "c" in neighboursA
    check "c" in neighboursB

  test "iterates over incoming edges":
    edges.incl( ("a", "b") )
    edges.incl( ("b", "c") )
    edges.incl( ("a", "c") )
    let neighboursA = toSeq(edges.incoming("a"))
    let neighboursB = toSeq(edges.incoming("b"))
    let neighboursC = toSeq(edges.incoming("c"))
    check neighboursA.len == 0
    check neighboursB.len == 1
    check neighboursC.len == 2
    check "a" in neighboursB
    check "a" in neighboursC and "b" in neighboursC

  test "works for large sets":
    var large = EdgeSet[int].init
    for _ in 0..10_000:
      let x, y = rand(100)
      if x != y:
        let (x, y) = (min(x,y), max(x,y))
        large.incl((x,y))
        check (x, y) in large
        check y in toSeq large.outgoing(x)
        check x in toSeq large.incoming(y)
