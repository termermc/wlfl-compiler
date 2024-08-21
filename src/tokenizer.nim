import token

const alphanumericChars = {'a'..'z', 'A'..'Z', '0'..'9'}

## Returns whether the character at the specified index equals the provided char.
## Checks bounds before checking the underlying input, so out of bounds indexes will return false instead of erroring.
## Assumes the input string is named `input`.
template indexIs(index: int, c: char): bool =
    index >= 0 and index < input.len and input[index] == c
template nextIs(c: char): bool =
    indexIs(i, c)
template lastIs(c: char): bool =
    indexIs(i - 2, c)

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
                val.add(c)
            else:
                return Token(kind: StringLit, stringLitVal: val)
        else:
            val.add(c)
    
    # If it did not return by this point, the string is unclosed
    return Token(kind: BadUnclosedStringLit, badUnclosedStringLitVal: val)

## Handles tokenizing a string character literal.
## Expects the first quote to already have been consumed.
## Does not encode escape sequences; it is only aware of them for escaping quotes.
func handleChar(input: string, i: var int): Token =
    var val = ""

    while i < input.len:
        let c = input[i]
        inc i

        if c == '\'':
            if input[i-2] == '\\':
                val.add(c)
            else:
                dec i
                return Token(kind: CharLit, charLitVal: val)
        elif c == '\n':
            # Char literals do not support line breaks
            break
        else:
            val.add(c)
    
    # If it did not return by this point, the char is unclosed
    return Token(kind: BadUnclosedCharLit, badUnclosedCharLitVal: val)

func handleQuotedKeyword(input: string, i: var int): Token =
    var val = ""

    while i < input.len:
        let c = input[i]
        inc i

        if c == '`':
            return Token(kind: QuotedKeyword, quotedKeywordName: val)
        else:
            val.add(c)
    
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

func handleInteger(input: string, i: var int): Token =
    var val = ""
    var fmt = '\0'

    const fmtBin = 'b'
    const fmtOct = 'o'
    const fmtHex = 'x'
    const fmtChars = {
        fmtBin,
        fmtOct,
        fmtHex,
    }

    var isFirst = true

    # Start from char when this function was invoked
    dec i

    while i < input.len:
        let c = input[i]
        inc i

        # Underscores are allowed anywhere in integer literals
        if c == '_':
            continue

        if fmt == '\0':
            case c:
            of '1'..'9':
                val.add(c)

            of '0':
                # First char can only be a zero if it is followed by a format char
                if not isFirst or i < input.len and input[i] in fmtChars:
                    val.add(c)
                else:
                    break

            of fmtChars:
                if lastIs('0'):
                    fmt = c
                    val.add(c)
                else:
                    break

            else:
                break

            if isFirst:
                isFirst = false

        elif fmt == fmtBin:
            case c:
            of '0'..'1':
                val.add(c)
            
            else:
                break
        
        elif fmt == fmtOct:
            case c:
            of '0'..'7':
                val.add(c)
            
            else:
                break
        
        elif fmt == fmtHex:
            case c:
            of '0'..'9', 'a'..'f':
                val.add(c)
            
            else:
                break
    
        else:
            break

    dec i
    return Token(kind: IntegerLit, integerLitVal: val)

iterator tokenize*(input: string): Token =
    var i = 0
    var lineNum: uint32 = 1
    var colNum: uint32 = 1

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

                of '\'':
                    yield handleChar(input, i)

                of '`':
                    let quotedKeywordToken = handleQuotedKeyword(input, i)

                    yield quotedKeywordToken

                    if quotedKeywordToken.kind == TokenType.BadUnclosedQuotedKeyword:
                        # Return
                        break mainLoop
                
                of '0'..'9':
                    yield handleInteger(input, i)

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
                
                of '^':
                    yield Token(kind: BitwiseXor, lineNum: lineNum, colNum: colNum)
                
                of '~':
                    yield Token(kind: BitwiseNot, lineNum: lineNum, colNum: colNum)

                of '@':
                    let ident = handleIdentifierRaw(input, i)
                    yield Token(kind: Annotation, annotationName: ident, lineNum: lineNum, colNum: colNum)

                of '.':
                    yield Token(kind: Dot, lineNum: lineNum, colNum: colNum)
                
                of '(':
                    yield Token(kind: OpenParenthesis, lineNum: lineNum, colNum: colNum)
                
                of ')':
                    yield Token(kind: CloseParenthesis, lineNum: lineNum, colNum: colNum)
                
                of ':':
                    yield Token(kind: Colon, lineNum: lineNum, colNum: colNum)

                of ';':
                    yield Token(kind: Semicolon, lineNum: lineNum, colNum: colNum)

                of '*':
                    yield Token(kind: Asterisk, lineNum: lineNum, colNum: colNum)

                else:
                    echo "TODO Other cases"
                    quit(1)

                # TODO Other cases
