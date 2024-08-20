import token

const alphanumericChars = {'a'..'z', 'A'..'Z', '0'..'9'}

## Handles tokenizing a string literal.
## Expects the first quote to already have been consumed.
## Does not encode escape sequences; it is only aware of them for escaping quotes.
func handleString(input: string, i: var int): Token =
    var val = ""

    while i < input.len:
        let c = input[i]
        inc i

        if c == '"':
            if input[i-2] == '\\':
                val.add c
            else:
                return Token(kind: StringLit, stringLitVal: val)
        else:
            val.add c
    
    # If it did not return by this point, the string is unclosed
    return Token(kind: BadUnclosedStringLit, badUnclosedStringLitVal: val)

func handleQuotedKeyword(input: string, i: var int): Token =
    var val = ""

    while i < input.len:
        let c = input[i]
        inc i

        if c == '`':
            return Token(kind: QuotedKeyword, quotedKeywordName: val)
        else:
            val.add c
    
    return Token(kind: BadUnclosedQuotedKeyword, badUnclosedQuotedKeywordVal: val)

func handleIdentifierRaw(input: string, i: var int): string =
    var val = ""

    var isFirst = true

    while i < input.len:
        let c = input[i]
        inc i

        if c notin alphanumericChars or isFirst and c in {'0'..'9'}:
            break
        else:
            val.add(c)
        
        if isFirst:
            isFirst = false
    
    return val

iterator tokenize*(input: string): Token =
    var i = 0
    var lineNum: uint32 = 1
    var colNum: uint32 = 1

    template indexIs(index: int, c: char): bool =
        index >= 0 and index < input.len and input[index] == c
    template nextIs(c: char): bool =
        indexIs(i, c)

    block mainLoop:
        while i < input.len:
            block mainLoopInner:
                template advance(chars: int, cont: static bool = false): untyped =
                    i += chars
                    colNum += chars

                    # Continue
                    when cont:
                        break mainLoopInner
            
                let c = input[i]
                inc i

                if c == '\n':
                    inc lineNum
                    continue
                if c == '\r':
                    continue

                # Confirmed not to be a line break, column advances
                inc colNum

                # Ignore whitespace
                if c == ' ' or c == '\t':
                    continue

                case c:
                of '"':
                    let strToken = handleString(input, i)

                    yield strToken

                    if strToken.kind == TokenType.BadUnclosedStringLit:
                        # Return
                        break mainLoop
                of '`':
                    let quotedKeywordToken = handleQuotedKeyword(input, i)

                    yield quotedKeywordToken

                    if quotedKeywordToken.kind == TokenType.BadUnclosedQuotedKeyword:
                        # Return
                        break mainLoop
                of '=':
                    if nextIs('='):
                        yield Token(kind: EqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yield Token(kind: Assignment, lineNum: lineNum, colNum: colNum)

                of '!':
                    if nextIs('='):
                        yield Token(kind: NotEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yield Token(kind: BoolNot, lineNum: lineNum, colNum: colNum)
                
                of '<':
                    if nextIs('='):
                        yield Token(kind: LesserEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yield Token(kind: LesserComparison, lineNum: lineNum, colNum: colNum)

                of '>':
                    if nextIs('='):
                        yield Token(kind: GreaterEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yield Token(kind: GreaterComparison, lineNum: lineNum, colNum: colNum)

                of '&':
                    if nextIs('&'):
                        yield Token(kind: AndComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yield Token(kind: BitwiseAnd, lineNum: lineNum, colNum: colNum)

                of '|':
                    if nextIs('|'):
                        yield Token(kind: OrComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yield Token(kind: BitwiseOr, lineNum: lineNum, colNum: colNum)
                
                of '@':
                    let ident = handleIdentifierRaw(input, i)
                    yield Token(kind: Annotation, annotationName: ident, lineNum: lineNum, colNum: colNum)

                else:
                    echo "TODO Other cases"
                    quit(1)

                # TODO Other cases
