import std/tables
import std/sets

type
  EdgeSet*[Vertex] = object
    # invariant: (∀ x->y ∈ outgoing: y<-x ∈ incoming)
    outgoing: Table[Vertex, seq[Vertex]]
    incoming: Table[Vertex, seq[Vertex]]
  Edge*[Vertex] = object
    x*, y* : Vertex

func init*[V](_: type EdgeSet[V]): EdgeSet[V] =
  discard

func incl*[V](edges: var EdgeSet[V], edge: Edge[V]) =
  if not edges.outgoing.hasKey(edge.x):
    edges.outgoing[edge.x] = @[]
  if not edges.incoming.hasKey(edge.y):
    edges.incoming[edge.y] = @[]
  if edge.y notin edges.outgoing[edge.x]:
    edges.outgoing[edge.x].add(edge.y)
  if edge.x notin edges.incoming[edge.y]:
    edges.incoming[edge.y].add(edge.x)

func contains*[V](edges: EdgeSet[V], edge: Edge[V]): bool =
  edge.y in edges.outgoing.getOrDefault(edge.x)

iterator outgoing*[V](edges: EdgeSet[V], vertex: V): V =
  for v in edges.outgoing.getOrDefault(vertex).items:
    yield v

iterator incoming*[V](edges: EdgeSet[V], vertex: V): V =
  for v in edges.incoming.getOrDefault(vertex).items:
    yield v

func `->`*[V](x, y: V): Edge[V] =
  Edge[V](x: x, y: y)
