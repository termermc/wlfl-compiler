import std/unicode
import ./token

const alphanumericChars = {'a'..'z', 'A'..'Z', '0'..'9'}
const wspChars = {' ', '\t'}
const wspCharsCr = {' ', '\t', '\r'}

func `==`(a, b: Rune | char): bool =
    return a.Rune == b.Rune

## Returns whether the character at the specified index equals the provided char.
## Checks bounds before checking the underlying input, so out of bounds indexes will return false instead of erroring.
## Assumes the input string is named `input`.
template indexIs(index: int, c: Rune | char): bool =
    index >= 0 and index < input.len and input[index] == c.Rune
template nextIs(c: Rune | char): bool =
    indexIs(i, c)
template lastIs(c: Rune | char): bool =
    indexIs(i - 2, c)

## Handles tokenizing a string literal.
## Expects the first quote to already have been consumed.
## Does not encode escape sequences; it is only aware of them for escaping quotes.
func handleString(input: seq[Rune], i: var int): Token =
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
func handleChar(input: seq[Rune], i: var int): Token =
    var val = ""

    while i < input.len:
        let c = input[i]
        inc i

        if c == '\'':
            if input[i-2] == '\\':
                val.add(c)
            else:
                return Token(kind: CharLit, charLitVal: val)
        elif c == '\n':
            # Char literals do not support line breaks
            break
        else:
            val.add(c)

    # If it did not return by this point, the char is unclosed
    return Token(kind: BadUnclosedCharLit, badUnclosedCharLitVal: val)

func handleQuotedIdent(input: seq[Rune], i: var int): Token =
    var val = ""

    while i < input.len:
        let c = input[i]
        inc i

        if c == '`':
            return Token(kind: QuotedIdent, quotedIdentName: val)
        else:
            val.add(c)
    
    return Token(kind: BadUnclosedQuotedIdent, badUnclosedQuotedIdentVal: val)

func handleIdentifierRaw(input: seq[Rune], i: var int): string =
    var val = ""

    var isFirst = true

    while i < input.len:
        let c = input[i]
        inc i

        if c.char notin alphanumericChars or isFirst and c.char in {'0'..'9'}:
            break
        else:
            val.add(c)
        
        if isFirst:
            isFirst = false
    
    return val

func handleInteger(input: seq[Rune], i: var int): Token =
    var val = newStringOfCap(1)
    val.add(input[i - 1])

    # fmt will be \0 for the second char, after which the format will be determined
    var fmt = '\0'

    const fmtBin = 'b'
    const fmtDec = 'd'
    const fmtOct = 'o'
    const fmtHex = 'x'
    const fmtChars = {
        fmtBin,
        fmtDec,
        fmtOct,
        fmtHex,
    }

    while i < input.len:
        # No unicode should ever be in an integer literal, so converting to char is safe
        let c = input[i].char
        inc i

        # Underscores are allowed anywhere after the first char
        if c == '_':
            val.add(c)
            continue

        if fmt == '\0':
            case c:
            of '0'..'9':
                fmt = fmtDec
                val.add(c)

            of fmtChars:
                if lastIs('0'):
                    fmt = c
                    val.add(c)
                else:
                    break

            else:
                break

        elif fmt == fmtBin:
            case c:
            of '0'..'1':
                val.add(c)
            
            else:
                break

        elif fmt == fmtDec:
            case c:
            of '0'..'9':
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

func handleDocBlock(input: seq[Rune], i: var int): Token =
    var val = ""

    while i < input.len:
        let c = input[i]
        inc i

        if c == '\n':
            # Skip over whitespace
            while i < input.len and input[i].char in wspChars:
                inc i
            
            if i + 2 < input.len and input[i] == '/' and input[i + 1] == '/' and input[i + 2] == '/':
                # Encountered contiguous doc block initiator
                val.add('\n')
                i += 3
                continue

            else:
                # End of doc block
                break

        else:
            val.add(c)
    
    return Token(kind: DocBlock, docBlockVal: val)

iterator tokenize*(input: seq[Rune]): Token {.noSideEffect.} =
    var i = 0
    var lineNum: uint32 = 1
    var colNum: uint32 = 1

    var lastToken: Token

    template yieldToken(token: Token) =
        lastToken = token
        yield lastToken

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
                if c.char in wspCharsCr:
                    continue

                case c:
                of '"'.Rune:
                    let strToken = handleString(input, i)

                    yieldToken strToken

                    if strToken.kind == TokenType.BadUnclosedStringLit:
                        # Return
                        break mainLoop

                of '\''.Rune:
                    yieldToken handleChar(input, i)

                of '`'.Rune:
                    let quotedIdentToken = handleQuotedIdent(input, i) 

                    yieldToken quotedIdentToken

                    if quotedIdentToken.kind == TokenType.BadUnclosedQuotedIdent:
                        # Return
                        break mainLoop
                
                of Rune('0')..Rune('9'):
                    let intToken = handleInteger(input, i)

                    if nextIs('.'):
                        var fracStr: string
                        if i + 1 < input.len and input[i + 1].char in {'0'..'9'}:
                            i += 2
                            fracStr = handleInteger(input, i).integerLitVal
                        else:
                            i += 1
                            fracStr = ""

                        yieldToken Token(
                            kind: DecimalLit,
                            decimalLitValWhole: intToken.integerLitVal,
                            decimalLitValFrac: fracStr,
                            lineNum: lineNum,
                            colNum: colNum,
                        )
                    else:
                        yieldToken intToken
                
                of '/'.Rune:
                    if i < input.len and input[i] == '/':
                        if i + 1 < input.len and input[i + 1] == '/':
                            # Doc block
                            i += 2
                            yieldToken handleDocBlock(input, i)
                        else:
                            # Comment, read until newline
                            while i < input.len and input[i] != '\n':
                                inc i
                                inc colNum
                            
                            inc lineNum
                    
                    else:
                        yieldToken Token(kind: Divide, lineNum: lineNum, colNum: colNum)

                of '='.Rune:
                    if nextIs('='):
                        yieldToken Token(kind: EqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: Assignment, lineNum: lineNum, colNum: colNum)

                of '!'.Rune:
                    if nextIs('='):
                        yield Token(kind: NotEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: BoolNot, lineNum: lineNum, colNum: colNum)
                
                of '<'.Rune:
                    if nextIs('='):
                        yield Token(kind: LesserEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: LesserComparison, lineNum: lineNum, colNum: colNum)

                of '>'.Rune:
                    if nextIs('='):
                        yield Token(kind: GreaterEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: GreaterComparison, lineNum: lineNum, colNum: colNum)

                of '&'.Rune:
                    if nextIs('&'):
                        yieldToken Token(kind: AndComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: BitwiseAnd, lineNum: lineNum, colNum: colNum)

                of '|'.Rune:
                    if nextIs('|'):
                        yield Token(kind: OrComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: BitwiseOr, lineNum: lineNum, colNum: colNum)
                
                of '^'.Rune:
                    yieldToken Token(kind: BitwiseXor, lineNum: lineNum, colNum: colNum)
                
                of '~'.Rune:
                    yieldToken Token(kind: BitwiseNot, lineNum: lineNum, colNum: colNum)

                of '@'.Rune:
                    let ident = handleIdentifierRaw(input, i)
                    yieldToken Token(kind: Annotation, annotationName: ident, lineNum: lineNum, colNum: colNum)

                of '.'.Rune:
                    yieldToken Token(kind: Dot, lineNum: lineNum, colNum: colNum)
                
                of '('.Rune:
                    yieldToken Token(kind: OpenParenthesis, lineNum: lineNum, colNum: colNum)
                
                of ')'.Rune:
                    yieldToken Token(kind: CloseParenthesis, lineNum: lineNum, colNum: colNum)
                
                of ':'.Rune:
                    yieldToken Token(kind: Colon, lineNum: lineNum, colNum: colNum)

                of ';'.Rune:
                    yieldToken Token(kind: Semicolon, lineNum: lineNum, colNum: colNum)

                of '*'.Rune:
                    yieldToken Token(kind: Asterisk, lineNum: lineNum, colNum: colNum)
 
                else:
                    debugEcho "TODO Other cases"
                    quit(1)

                # TODO Other cases
