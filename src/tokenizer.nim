import std/unicode
import ./token

const alphanumericChars = {'a'..'z', 'A'..'Z', '0'..'9'}
const identBasicChars = {'a'..'z', 'A'..'Z', '0'..'9', '_', '$'}
const wspChars = {' ', '\t'}
const wspCharsCr = {' ', '\t', '\r'}
const wspCharsCrLf = {' ', '\t', '\r', '\n'}

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

## Adanves the current index if the index is at the start of the provided word and the word is followed by whitespace or EOF.
## Returns whether the word was found and the index was advanced.
template advanceIfWord(word: string): bool = (
    if (
        i + word.len - 1 <= input.len and
        input[(i - 1)..(i + word.len - 2)] == word.toRunes() and
        (i + word.len > input.len or input[i + word.len - 1].char in wspCharsCrLf)
    ):
        i += word.len - 1
        true
    else:
        false
)

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

## Reads an identifier, or returns an empty string if the identifier is invalid.
func handleIdentifierRaw(input: seq[Rune], i: var int): string =
    var val = ""

    var isFirst = true

    while i < input.len:
        let c = input[i]
        inc i

        if (c.char notin identBasicChars and c.int32 <= 160) or (isFirst and c.char in {'0'..'9'}):
            dec i
            return ""
        else:
            val.add(c)
        
        if isFirst:
            isFirst = false

    dec i
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

## Iterator that scans over source code and produces tokens.
## I know that line and column numbers are broken. I'll fix it later.
iterator tokenize*(input: seq[Rune]): Token {.noSideEffect.} =
    var i = 0
    var lineNum: uint32 = 1
    var colNum: uint32 = 1

    var lastToken: Token

    template yieldToken(token: Token): untyped =
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
                    
                    elif nextIs('='):
                        yieldToken Token(kind: DivideAssignment, lineNum: lineNum, colNum: colNum)
                        advance(1)

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
                        yieldToken Token(kind: NotEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: BoolNot, lineNum: lineNum, colNum: colNum)
                
                of '<'.Rune:
                    if nextIs('='):
                        yieldToken Token(kind: LesserEqualsComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: LesserComparison, lineNum: lineNum, colNum: colNum)

                of '>'.Rune:
                    if nextIs('='):
                        yieldToken Token(kind: GreaterEqualsComparison, lineNum: lineNum, colNum: colNum)
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
                        yieldToken Token(kind: OrComparison, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: BitwiseOr, lineNum: lineNum, colNum: colNum)
                
                of '^'.Rune:
                    yieldToken Token(kind: BitwiseXor, lineNum: lineNum, colNum: colNum)
                
                of '~'.Rune:
                    yieldToken Token(kind: BitwiseNot, lineNum: lineNum, colNum: colNum)

                of '%'.Rune:
                    yieldToken Token(kind: Modulo, lineNum: lineNum, colNum: colNum)
                
                of '*'.Rune:
                    if nextIs('*'):
                        yieldToken Token(kind: Exponent, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    elif nextIs('='):
                        yieldToken Token(kind: MultiplyAssignment, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: Multiply, lineNum: lineNum, colNum: colNum)
                
                of '+'.Rune:
                    if nextIs('='):
                        yieldToken Token(kind: AddAssignment, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: Add, lineNum: lineNum, colNum: colNum)

                of '-'.Rune:
                    if nextIs('='):
                        yieldToken Token(kind: SubtractAssignment, lineNum: lineNum, colNum: colNum)
                        advance(1)
                    else:
                        yieldToken Token(kind: Subtract, lineNum: lineNum, colNum: colNum)

                of '@'.Rune:
                    let ident = handleIdentifierRaw(input, i)
                    yieldToken Token(kind: Annotation, annotationName: ident, lineNum: lineNum, colNum: colNum)

                of '.'.Rune:
                    yieldToken Token(kind: Dot, lineNum: lineNum, colNum: colNum)
                
                of ','.Rune:
                    yieldToken Token(kind: Comma, lineNum: lineNum, colNum: colNum)

                of '('.Rune:
                    yieldToken Token(kind: OpenParenthesis, lineNum: lineNum, colNum: colNum)
                
                of ')'.Rune:
                    yieldToken Token(kind: CloseParenthesis, lineNum: lineNum, colNum: colNum)
                
                of ':'.Rune:
                    yieldToken Token(kind: Colon, lineNum: lineNum, colNum: colNum)

                of ';'.Rune:
                    yieldToken Token(kind: Semicolon, lineNum: lineNum, colNum: colNum)
 
                of '{'.Rune:
                    yieldToken Token(kind: OpenCurlyBracket, lineNum: lineNum, colNum: colNum)
                
                of '}'.Rune:
                    yieldToken Token(kind: CloseCurlyBracket, lineNum: lineNum, colNum: colNum)
                
                of '['.Rune:
                    yieldToken Token(kind: OpenSquareBracket, lineNum: lineNum, colNum: colNum)
                
                of ']'.Rune:
                    yieldToken Token(kind: CloseSquareBracket, lineNum: lineNum, colNum: colNum)

                else:
                    if advanceIfWord("namespace"):
                        yieldToken Token(kind: NamespaceKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("using"):
                        yieldToken Token(kind: UsingKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("as"):
                        yieldToken Token(kind: AsKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("export"):
                        yieldToken Token(kind: ExportKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("func"):
                        yieldToken Token(kind: FuncKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("return"):
                        yieldToken Token(kind: ReturnKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("break"):
                        yieldToken Token(kind: BreakKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("continue"):
                        yieldToken Token(kind: ContinueKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("do"):
                        yieldToken Token(kind: DoKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("let"):
                        yieldToken Token(kind: LetKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("var"):
                        yieldToken Token(kind: VarKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("const"):
                        yieldToken Token(kind: ConstKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("if"):
                        yieldToken Token(kind: IfKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("else"):
                        yieldToken Token(kind: ElseKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("while"):
                        yieldToken Token(kind: WhileKeyword, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("true"):
                        yieldToken Token(kind: TrueLit, lineNum: lineNum, colNum: colNum)
                    elif advanceIfWord("false"):
                        yieldToken Token(kind: FalseLit, lineNum: lineNum, colNum: colNum)
                    else:
                        dec i
                        let ident = handleIdentifierRaw(input, i)

                        if ident == "":
                            yieldToken Token(kind: IllegalToken, illegalTokenVal: $input[i], lineNum: lineNum, colNum: colNum)
                            advance(1, cont = true)

                        yieldToken Token(kind: Ident, identName: ident, lineNum: lineNum, colNum: colNum)

                # TODO Other cases
