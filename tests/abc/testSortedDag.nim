import std/sequtils
import std/algorithm
import std/random
import abc/dag/sorteddag
import ./basics

suite "Sorted DAG":

  test "contains vertices":
    var dag = SortedDag[int].new
    dag.add(1->2)
    check 1 in dag
    check 2 in dag
    check 42 notin dag
    dag.add(2->42)
    check 42 in dag

  test "contains edges":
    var dag = SortedDag[int].new
    dag.add(1->2)
    check (1->2) in dag
    check (2->3) notin dag
    dag.add(2->3)
    check (2->3) in dag

  test "visits reachable vertices, nearest first":

    # ⓪  →  ①
    #  ↘   ↙
    #    ②

    var dag = SortedDag[int].new
    for edge in [0->1, 1->2, 0->2]:
      dag.add(edge)

    check toSeq(dag.visit(0)) == @[1, 2]
    check toSeq(dag.visit(1)) == @[2]
    check toSeq(dag.visit(2)).len == 0

  test "visits vertices in topological order":

    #    ⑤   ④
    #   ↙ ↘ ↙ ↘
    #  ②  ⓪  ①
    #   ↘     ↗
    #      ③

    var dag = SortedDag[int].new
    for edge in [5->2, 5->0, 4->0, 4->1, 2->3, 3->1]:
      dag.add(edge)

    let reachableFrom5 = toSeq(dag.visit(5))
    let reachableFrom4 = toSeq(dag.visit(4))
    check reachableFrom5.sorted == @[0, 1, 2, 3]
    check reachableFrom4.sorted == @[0, 1]
    check reachableFrom5.find(2) < reachableFrom5.find(3)
    check reachableFrom5.find(3) < reachableFrom5.find(1)

  test "handles spending transactions before gaining transactions":

    #      acks
    #     ↙    ↘
    #  ack1    ack2
    #   ↓       ↓
    # gain  ←  spend

    var dag = SortedDag[string].new
    for edge in ["acks"->"ack1",
                 "acks"->"ack2",
                 "ack1"->"gain",
                 "ack2"->"spend",
                 "spend"->"gain"]:
      dag.add(edge)

    let walk = toSeq dag.visit("acks")
    check walk.find("spend") < walk.find("gain")

  test "handles cross-referencing branches":

    #     ⓪
    #   ↙    ↘
    #  ①  →  ⑥
    #  ↓      ↓
    #  ②  ←  ⑦
    #  ↓      ↓
    #  ③  →  ⑧
    #  ↓      ↓
    #  ④  ←  ⑨
    #  ↓      ↓
    #  ⑤  →  ⑩

    var dag = SortedDag[int].new
    for vertex in [1,6]:
      dag.add(0->vertex)
    for vertex in 1..<5:
      dag.add(vertex->vertex + 1)
    for vertex in 6..<10:
      dag.add(vertex->vertex + 1)
    for vertex in [1, 3, 5]:
      dag.add(vertex->vertex + 5)
    for vertex in [2, 4]:
      dag.add(vertex+5->vertex)

    check toSeq(dag.visit(0)) == @[1, 6, 7, 2, 3, 8, 9, 4, 5, 10]

  test "handles DAGs with many edges":

    var dag = SortedDag[int].new
    for _ in 0..10_000:
      let x, y = rand(100)
      if x != y:
        dag.add(min(x,y)->max(x,y))

    var latest = -1
    for vertex in dag.visit(0):
      latest = vertex
    check latest != -1

  test "handles large DAGs that grow by adding new vertices":

    #  ⓪ ← ① ← ② ← ...

    var dag = SortedDag[int].new
    for i in 1..10_000:
      dag.add(i->i-1)

    var latest = 10_000
    for vertex in dag.visit(10_000):
      check vertex < latest
      latest = vertex
    check latest == 0
