import std/tables
import std/sets

type
  EdgeSet*[Vertex] = object
    # invariant: (∀ x->y ∈ outgoing: y<-x ∈ incoming)
    outgoing: Table[Vertex, HashSet[Vertex]]
    incoming: Table[Vertex, HashSet[Vertex]]
  Edge*[Vertex] = (Vertex, Vertex)

func init*[V](_: type EdgeSet[V]): EdgeSet[V] =
  discard

func incl*[V](edges: var EdgeSet[V], edge: Edge[V]) =
  let (x, y) = edge
  edges.outgoing.mgetOrPut(x, HashSet[V].default).incl(y)
  edges.incoming.mgetOrPut(y, HashSet[V].default).incl(x)

func contains*[V](edges: EdgeSet[V], edge: Edge[V]): bool =
  edge[1] in edges.outgoing.getOrDefault(edge[0])

iterator outgoing*[V](edges: EdgeSet[V], vertex: V): V =
  for v in edges.outgoing.getOrDefault(vertex).items:
    yield v

iterator incoming*[V](edges: EdgeSet[V], vertex: V): V =
  for v in edges.incoming.getOrDefault(vertex).items:
    yield v
