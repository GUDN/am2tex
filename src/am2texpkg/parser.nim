import strutils
import lists

import tokenizer

type
  NodeType* = enum
    ntInterval, ntMatrix, ntLine,
    ntFunction, ntBinary, ntUnary,
    ntFString, ntString, ntLatex
    ntBExpr, ntExpr,
    ntOperation, ntFraction,
    ntSubsup,
    ntEmpty, ntToken, ntBracket
  Node* = ref object
    value*: string
    case nodeType*: NodeType
    of ntToken: tokenType*: TokenType
    of ntFString: font*: string
    of ntBracket: isLeft: bool
    of ntInterval, ntMatrix, ntLine, ntFunction, ntBinary, ntUnary,
      ntBExpr, ntExpr, ntOperation, ntFraction:
      children*: seq[Node]
    of ntSubsup:
      base*, sub*, sup*: Node
    else: discard
  DLNode = DoublyLinkedNode[Node]
  NodeList = object
    startNode, endNode: DLNode

using
  nodeList: NodeList
  dlnode: DLNode


let Empty = Node(nodeType: ntEmpty)


## Helper functions
proc toString(node: Node; indent = 0): string =
  case node.nodeType
  of ntToken: result = node.value & " " & $node.tokenType
  of ntFString: result = node.value & " (font " & node.font & ")"
  of ntEmpty: result = "empty"
  of ntBracket, ntString: result = node.value
  of ntSubsup:
    result = "subsup\n"
    result &= toString(node.base, indent + 1) & '\n'
    result &= toString(node.sub, indent + 1) & '\n'
    result &= toString(node.sup, indent + 1)
  else:
    if node.value.len > 0: result = node.value
    else: result = $node.nodeType
    result &= "\n"
    for child in node.children:
      result &= toString(child, indent + 1) & "\n"
    result.removeSuffix("\n")
  result = "  ".repeat(indent) & result

proc `$`*(node: Node): string = toString(node)

iterator items(nodeList): DLNode =
  var currentNode = nodeList.startNode
  while currentNode != nil and currentNode != nodeList.endNode:
    yield currentNode
    currentNode = currentNode.next
  if currentNode != nil:
    yield currentNode

iterator reversedItems(nodeList): DLNode =
  var currentNode = nodeList.endNode
  while currentNode != nil and currentNode != nodeList.startNode:
    yield currentNode
    currentNode = currentNode.prev
  if currentNode != nil: yield currentNode

proc len(nodeList): int =
  var currentNode = nodeList.startNode
  while currentNode != nil and currentNode != nodeList.endNode:
    inc result
    currentNode = currentNode.next
  if currentNode != nil: inc result

proc next(nodeList): DLNode = nodeList.endNode.next
proc prev(nodeList): DLNode = nodeList.startNode.prev
proc first(nodeList): DLNode = nodeList.startNode.next
proc last(nodeList): DLNode = nodeList.endNode.prev

proc replaceWith(nodeList; dlnode) =
  dlnode.prev = nodeList.prev
  if nodeList.prev != nil: nodeList.prev.next = dlnode
  dlnode.next = nodeList.next
  if nodeList.next != nil: nodeList.next.prev = dlnode

proc replaceWith(nodeList; node: Node) = nodeList.replaceWith newDoublyLinkedNode(node)

proc vvalue(dlnode): string = dlnode.value.value

proc selfdelete(dlnode) =
  if dlnode.prev != nil:
    dlnode.prev.next = dlnode.next
  if dlnode.next != nil:
    dlnode.next.prev = dlnode.prev

proc replaceWith(dlnode; node: Node) =
  let node = newDoublyLinkedNode(node)
  node.prev = dlnode.prev
  if dlnode.prev != nil: dlnode.prev.next = node
  node.next = dlnode.next
  if dlnode.next != nil: dlnode.next.prev = node

proc isNil(dlnode): bool = dlnode == nil


proc simplify(node: Node; parentType: NodeType): Node =
  if node.nodeType != ntBExpr: result = node
  else:
    let
      left = node.children[0]
      right = node.children[2]
      inner = node.children[1]
    if left.value & right.value != "()": return node
    case parentType
    of ntEmpty: result = node
    of ntFraction, ntSubsup: result = inner
    of ntBinary, ntUnary: result = inner
    else: result = node


proc parse(nodeList) =
  let
    prev = nodeList.prev
    next = nodeList.next
    startNode, endNode = newDoublyLinkedNode(Empty)
  startNode.next = nodeList.startNode
  nodeList.startNode.prev = startNode
  endNode.prev = nodeList.endNode
  nodelist.endNode.next = endNode
  let nodeList = NodeList(
    startNode: startNode,
    endNode: endNode
  )
  proc check(dlnode): bool =
    result = true
    if dlnode.isNil: result = false
    elif dlnode == startNode or dlnode == endNode: result = false
    else:
      let value = dlnode.value
      if value.value in ["_", "^"]: result = false
      elif value.nodeType == ntToken and value.tokenType == ttOperator: result = false
  # Parse functions
  for dlnode in nodeList.reversedItems:
    let node = dlnode.value
    case node.nodeType
    of ntUnary:
      let next = dlnode.next
      if not next.check:
        dlnode.value.children.add Empty
      else:
        dlnode.value.children.add simplify(next.value, parentType=ntUnary)
        next.selfdelete()
    of ntBinary:
      let next1 = dlnode.next
      if not next1.check: dlnode.selfdelete()
      let next2 = next1.next
      dlnode.value.children.add simplify(next1.value, parentType=ntBinary)
      next1.selfdelete()
      if not next2.check:
        dlnode.value.children.add Empty
      else:
        dlnode.value.children.add simplify(next2.value, parentType=ntBinary)
        next2.selfdelete()
    of ntFunction:
      var
        sub, sup: DLNode
        argument: DLNode
        next = dlnode.next
      while next != nil and next != endNode:
        let vvalue = next.vvalue
        if vvalue == "_":
          if sub != nil: break
          let subNext = next.next
          if not subnext.check: break
          sub = subNext
          next.selfdelete()
          next = subNext.next
        elif vvalue == "^":
          if sup != nil: break
          let supNext = next.next
          if not supNext.check: break
          sup = supNext
          next.selfdelete()
          next = supNext.next
        elif next.check:
          argument = next
          break
        else: break
      dlnode.value.children = block:
        var children = newSeq[Node]()
        if sub == nil: children.add Empty
        else:
          children.add simplify(sub.value, parentType=ntSubsup)
          sub.selfdelete()
        if sup == nil: children.add Empty
        else:
          children.add simplify(sup.value, parentType=ntSubsup)
          sup.selfdelete()
        if argument == nil: children.add Empty
        else:
          children.add simplify(argument.value, parentType=ntFunction)
          argument.selfdelete()
        children
    else: discard
  # Parse subsups
  for dlnode in nodeList.reversedItems:
    case dlnode.vvalue
    of "_":
      let base = dlnode.prev
      if not base.check:
        dlnode.selfdelete()
        continue
      let next = dlnode.next
      if not next.check: dlnode.selfdelete()
      elif next.value.nodeType == ntSubsup and next.value.sub == Empty:
        let nValue = next.value
        nValue.sub = simplify(nValue.base, parentType=ntSubsup)
        nValue.base = simplify(base.value, parentType=ntEmpty)
        dlnode.selfdelete()
        base.selfdelete()
      else:
        let node = Node(
          nodeType: ntSubsup,
          base: base.value,
          sub: simplify(next.value, parentType=ntSubsup),
          sup: Empty
        )
        next.selfdelete()
        dlnode.selfdelete()
        base.replaceWith node
    of "^":
      let base = dlnode.prev
      if not base.check:
        dlnode.selfdelete()
        continue
      let next = dlnode.next
      if not next.check: dlnode.selfdelete()
      elif next.value.nodeType == ntSubsup and next.value.sup == Empty:
        let nValue = next.value
        nValue.sup = simplify(nValue.base, parentType=ntSubsup)
        nValue.base = simplify(base.value, parentType=ntEmpty)
        dlnode.selfdelete()
        base.selfdelete()
      else:
        let node = Node(
          nodeType: ntSubsup,
          base: base.value,
          sub: Empty,
          sup: simplify(next.value, parentType=ntSubsup)
        )
        next.selfdelete()
        dlnode.selfdelete()
        base.replaceWith node
    else: discard
  # Parse fractions
  for dlnode in nodeList:
    if dlnode.vvalue == "/":
      var
        prev, next: Node
      if dlnode.prev.check:
        prev = simplify(dlnode.prev.value, parentType=ntFraction)
        dlnode.prev.selfdelete()
      else:
        prev = Empty
      if dlnode.next.check:
        next = simplify(dlnode.next.value, parentType=ntFraction)
        dlnode.next.selfdelete()
      else:
        next = Empty
      let node = Node(
        nodeType: ntFraction,
        children: @[prev, next]
      )
      dlnode.replaceWith node
  # Parse other operators
  for dlnode in nodeList:
    let node = dlnode.value
    if node.nodeType == ntToken and node.tokenType == ttOperator:
      let
        prev = dlnode.prev
        next = dlnode.next
      if next.check and prev.check:
        let node = Node(
          nodeType: ntOperation,
          value: node.value,
          children: @[prev.value, next.value]
        )
        prev.selfdelete()
        next.selfdelete()
        dlnode.replaceWith node
  # Collapse all into one node
  var dlnode: DLNode
  case nodeList.len
  of 3: dlnode = nodeList.first
  of 2: dlnode = newDoublyLinkedNode(Empty)
  else:
    let node = Node(
      nodeType: ntExpr,
      children: newSeq[Node]()
    )
    proc isLetter(node: Node): bool = node.nodeType == ntToken and node.tokenType == ttLetter
    for dlnode in nodeList:
      if dlnode == startNode or dlnode == endNode: continue
      let value = dlnode.value
      if node.children.len > 0 and value.isLetter and node.children[^1].isLetter:
        node.children[^1].value &= value.value
        dlnode.selfdelete()
      else: node.children.add simplify(value, parentType=ntExpr)
    if node.children.len == 1:
      dlnode = newDoublyLinkedNode(node.children[0])
    else:
      dlnode = newDoublyLinkedNode(node)
  prev.next = dlnode
  dlnode.prev = prev
  next.prev = dlnode
  dlnode.next = next

proc parseBracket(nodeList) =
  if nodeList.len <= 2:
    nodeList.replaceWith Node(
      nodeType: ntBExpr,
      children: @[
        nodeList.startNode.value,
        Empty,
        nodeList.endNode.value
      ]
    )
    return
  let
    left = nodeList.startNode.value
    right = nodeList.endNode.value
  let (delimiters, wasSemicolon) = block:
    var
      delimiters = newSeq[DLNode]()
      wasSemicolon = false
    for dlnode in nodeList:
      let vvalue = dlnode.vvalue
      if vvalue == ";":
        delimiters.add dlnode
        wasSemicolon = true
      elif vvalue in [":", ","]: delimiters.add dlnode
    (delimiters, wasSemicolon)
  if delimiters.len == 1 and delimiters[0].vvalue == ":":
    # Interval
    let delimiter = delimiters[0]
    if nodeList.first == delimiter:
      let node = newDoublyLinkedNode(Empty)
      node.prev = nodeList.startNode
      nodeList.startNode.next = node
    else:
      parse NodeList(
        startNode: nodeList.first,
        endNode: delimiter.prev
      )
    nodeList.first.next = delimiter.next
    delimiter.next.prev = nodeList.first
    if nodeList.last == delimiter:
      let node = newDoublyLinkedNode(Empty)
      node.next = nodeList.endNode
      node.prev = nodeList.first
      nodeList.endNode.prev = node
    else:
      parse NodeList(
        startNode: delimiter.next,
        endNode: nodeList.last
      )
      nodeList.last.prev = nodeList.first
    let children = block:
      var children = newSeq[Node]()
      for node in nodeList: children.add node.value
      children
    nodeList.replaceWith Node(
      nodeType: ntInterval,
      children: children
    )
  elif wasSemicolon:
    # Matrix
    var matrixLines = newSeq[seq[Node]]()
    matrixLines.add newSeq[Node]()
    var start = nodeList.first
    for delimiter in delimiters:
      let vvalue = delimiter.vvalue[0]
      if vvalue == ':': continue
      if start == delimiter:
        if vvalue == ',': matrixLines[^1].add Empty
        continue
      parse NodeList(
        startNode: start,
        endNode: delimiter.prev
      )
      matrixLines[^1].add delimiter.prev.value
      if vvalue == ';': matrixLines.add newSeq[Node]()
      start = delimiter.next
    if start != nodeList.endNode:
      parse NodeList(
        startNode: start,
        endNode: nodeList.last
      )
      matrixLines[^1].add nodeList.last.value
    if matrixLines[^1].len == 0: matrixLines.del(matrixLines.len - 1)
    let matrixNodes = block:
      var matrixNodes = newSeq[Node]()
      matrixNodes.add left
      for line in matrixLines:
        matrixNodes.add Node(
          nodeType: ntLine,
          children: line
        )
      matrixNodes.add right
      matrixNodes
    nodeList.replaceWith Node(
      nodeType: ntMatrix,
      children: matrixNodes
    )
  else:
    parse NodeList(
      startNode: nodeList.first,
      endNode: nodeList.last
    )
    nodeList.replaceWith Node(
      nodeType: ntBExpr,
      children: @[
        nodeList.startNode.value,
        nodeList.first.value,
        nodeList.endNode.value
      ]
    )


proc parse*(stream: string): Node =
  var
    nodesList = initDoublyLinkedList[Node]()
    fontValue = ""
  nodesList.append newDoublyLinkedNode(Empty)
  for token in toTokens(stream):
    if fontValue != "":
      if token.tokenType == ttString:
        nodesList.append newDoublyLinkedNode(Node(
          nodeType: ntFString,
          value: token.value,
          font: fontValue
        ))
        fontValue = ""
        continue
      fontValue = ""
    case token.tokenType
    of ttLatex:
      nodesList.append newDoublyLinkedNode(Node(
        nodeType: ntLatex,
        value: token.value
      ))
    of ttString:
      nodesList.append newDoublyLinkedNode(Node(
        nodeType: ntString,
        value: token.value,
      ))
    of ttFont:
      fontValue = token.value
    of ttUnary:
      nodesList.append newDoublyLinkedNode(Node(
        nodeType: ntUnary,
        value: token.value
      ))
    of ttBinary:
      nodesList.append newDoublyLinkedNode(Node(
        nodeType: ntBinary,
        value: token.value
      ))
    of ttFunction:
      nodesList.append newDoublyLinkedNode(Node(
        nodeType: ntFunction,
        value: token.value
      ))
    of ttLeftBracket, ttRightBracket:
      nodesList.append newDoublyLinkedNode(Node(
        nodeType: ntBracket,
        value: token.value,
        isLeft: token.value in ["(", "{", "[", "(:", "{:"]
      ))
    else:
      nodesList.append newDoublyLinkedNode(Node(
        nodeType: ntToken,
        tokenType: token.tokenType,
        value: token.value
      ))
  nodesList.append newDoublyLinkedNode(Empty)

  var stack = newSeq[DLNode]()
  for dlnode in nodesList.nodes:
    let node = dlnode.value
    if node.nodeType != ntBracket: continue
    if node.isLeft: stack.add dlnode
    elif stack.len == 0: nodesList.remove(dlnode)
    else:
      parseBracket(NodeList(
        startNode: stack.pop,
        endNode: dlnode
      ))
  for dlnode in stack:
    nodesList.remove dlnode

  parse NodeList(
    startNode: nodesList.head.next,
    endNode: nodesList.tail.prev
  )

  result = nodesList.head.next.value
