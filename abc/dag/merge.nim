# Copied from Nim standard library, development version:
# https://github.com/nim-lang/Nim/blob/493721c16c06b5681dc270679bdcbb41011614b2/lib/pure/algorithm.nim#L545
# See merge.license file for copyright info.

proc merge*[T](
  result: var seq[T],
  x, y: openArray[T], cmp: proc(x, y: T): int {.closure.}
) =
  ## Merges two sorted `openArray`. `x` and `y` are assumed to be sorted.
  ## If you do not wish to provide your own `cmp`,
  ## you may use `system.cmp` or instead call the overloaded
  ## version of `merge`, which uses `system.cmp`.
  ##
  ## .. note:: The original data of `result` is not cleared,
  ##    new data is appended to `result`.
  ##
  ## **See also:**
  ## * `merge proc<#merge,seq[T],openArray[T],openArray[T]>`_
  runnableExamples:
    let x = @[1, 3, 6]
    let y = @[2, 3, 4]

    block:
      var merged = @[7] # new data is appended to merged sequence
      merged.merge(x, y, system.cmp[int])
      assert merged == @[7, 1, 2, 3, 3, 4, 6]

    block:
      var merged = @[7] # if you only want new data, clear merged sequence first
      merged.setLen(0)
      merged.merge(x, y, system.cmp[int])
      assert merged.isSorted
      assert merged == @[1, 2, 3, 3, 4, 6]

    import std/sugar

    var res: seq[(int, int)]
    res.merge([(1, 1)], [(1, 2)], (a, b) => a[0] - b[0])
    assert res == @[(1, 1), (1, 2)]

    assert seq[int].default.dup(merge([1, 3], [2, 4])) == @[1, 2, 3, 4]

  let
    sizeX = x.len
    sizeY = y.len
    oldLen = result.len

  result.setLen(oldLen + sizeX + sizeY)

  var
    ix = 0
    iy = 0
    i = oldLen

  while true:
    if ix == sizeX:
      while iy < sizeY:
        result[i] = y[iy]
        inc i
        inc iy
      return

    if iy == sizeY:
      while ix < sizeX:
        result[i] = x[ix]
        inc i
        inc ix
      return

    let itemX = x[ix]
    let itemY = y[iy]

    if cmp(itemX, itemY) > 0: # to have a stable sort
      result[i] = itemY
      inc iy
    else:
      result[i] = itemX
      inc ix

    inc i

proc merge*[T](result: var seq[T], x, y: openArray[T]) {.inline.} =
  ## Shortcut version of `merge` that uses `system.cmp[T]` as the comparison function.
  ##
  ## **See also:**
  ## * `merge proc<#merge,seq[T],openArray[T],openArray[T],proc(T,T)>`_
  runnableExamples:
    let x = [5, 10, 15, 20, 25]
    let y = [50, 40, 30, 20, 10].sorted

    var merged: seq[int]
    merged.merge(x, y)
    assert merged.isSorted
    assert merged == @[5, 10, 10, 15, 20, 20, 25, 30, 40, 50]
  merge(result, x, y, system.cmp)
