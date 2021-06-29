func hasDuplicates*[T](elements: openArray[T]): bool =
  for i in 0..<elements.len:
    for j in i+1..<elements.len:
      if elements[i] == elements[j]:
        return true
  false
