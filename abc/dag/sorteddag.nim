import std/tables
import std/sets
import std/algorithm
import std/heapqueue
import std/hashes
import ./edgeset
import ./merge

## Implements a directed acyclic graph (DAG). Visiting vertices in topological
## order is fast. It is optimized for DAGs that grow by adding new vertices that
## point to existing vertices in the DAG, such as a blockchain transaction DAG.
##
## Uses the dynamic topological sort algorithm by
## [Pearce and Kelly](https://www.doc.ic.ac.uk/~phjk/Publications/DynamicTopoSortAlg-JEA-07.pdf).

type
  SortedDag*[Vertex] = ref object
    ## A DAG whose vertices are kept in topological order
    edges: EdgeSet[Vertex]
    order: Table[Vertex, int]
  SortedVertex[Vertex] = object
    vertex: Vertex
    index: int

func new*[V](_: type SortedDag[V]): SortedDag[V] =
  SortedDag[V]()

func contains*[V](dag: SortedDag[V], vertex: V): bool =
  vertex in dag.order

func contains*[V](dag: SortedDag[V], edge: Edge[V]): bool =
  edge in dag.edges

func lookup[V](dag: SortedDag[V], vertex: V): SortedVertex[V] =
  SortedVertex[V](vertex: vertex, index: dag.order[vertex])

func `<`*[V](a, b: SortedVertex[V]): bool =
  a.index < b.index

func hash*[V](vertex: SortedVertex[V]): Hash =
  vertex.index.hash

func searchForward[V](dag: SortedDag[V],
                      start: SortedVertex[V],
                      upperbound: SortedVertex[V]): seq[SortedVertex[V]] =
  var todo = @[start]
  var seen = @[start].toHashSet
  while todo.len > 0:
    let current = todo.pop()
    result.add(current)
    for neighbour in dag.edges.outgoing(current.vertex):
      let vertex = dag.lookup(neighbour)
      doAssert vertex.index != upperbound.index, "cycle detected"
      if vertex notin seen and vertex < upperbound:
        todo.add(vertex)
        seen.incl(vertex)

func searchBackward[V](dag: SortedDag[V],
                       start: SortedVertex[V],
                       lowerbound: SortedVertex[V]): seq[SortedVertex[V]] =
  var todo = @[start]
  var seen = @[start].toHashSet
  while todo.len > 0:
    let current = todo.pop()
    result.add(current)
    for neighbour in dag.edges.incoming(current.vertex):
      let vertex = dag.lookup(neighbour)
      if vertex notin seen and vertex > lowerbound:
        todo.add(vertex)
        seen.incl(vertex)

func reorder[V](dag: SortedDag[V], forward, backward: seq[SortedVertex[V]]) =
  var vertices: seq[V]
  var indices, forwardIndices, backwardIndices: seq[int]
  for vertex in backward.sorted:
    vertices.add(vertex.vertex)
    backwardIndices.add(vertex.index)
  for vertex in forward.sorted:
    vertices.add(vertex.vertex)
    forwardIndices.add(vertex.index)
  merge(indices, backwardIndices, forwardIndices)
  for i in 0..<vertices.len:
    dag.order[vertices[i]] = indices[i]

func update[V](dag: SortedDag[V], lowerbound, upperbound: SortedVertex[V]) =
  if lowerbound < upperbound:
    let forward = searchForward(dag, lowerbound, upperbound)
    let backward = searchBackward(dag, upperbound, lowerbound)
    dag.reorder(forward, backward)

func add[V](dag: SortedDag[V], vertex: V) =
  if vertex notin dag:
    dag.order[vertex] = -(dag.order.len)

func add*[V](dag: SortedDag[V], edge: tuple[x, y: V]) =
  ## Adds an edge x -> y to the DAG
  dag.add(edge.y)
  dag.add(edge.x)
  dag.edges.incl(edge)
  dag.update(dag.lookup(edge.y), dag.lookup(edge.x))

iterator visit*[V](dag: SortedDag[V], start: V): V =
  ## Visits all vertices that are reachable from the starting vertex. Vertices
  ## are visited in topological order, meaning that vertices close to the
  ## starting vertex are visited first.
  var todo = initHeapQueue[SortedVertex[V]]()
  var seen: HashSet[SortedVertex[V]]
  for neighbour in dag.edges.outgoing(start):
    let vertex = dag.lookup(neighbour)
    todo.push(vertex)
    seen.incl(vertex)
  while todo.len > 0:
    let current = todo.pop()
    yield current.vertex
    for neighbour in dag.edges.outgoing(current.vertex):
      let vertex = dag.lookup(neighbour)
      if vertex notin seen:
        todo.push(vertex)
        seen.incl(vertex)
