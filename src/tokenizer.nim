import token

## Handles tokenizing a string literal.
## Expects the first quote to already have been consumed.
## Does not encode escape sequences; it is only aware of them for escaping quotes.
func handleString(input: string, var i: int): Token =
    var val = ""

    while i < input.len:
        inc i
        let c = input[i]

        if c == '"':
            if input[i-1] == '\\':
                val.add c
            else:
                return Token(kind: StringLit, stringLitVal: val)
        else:
            val.add c
    
    # If it did not return by this point, the string is unclosed
    return Token(kind: BadUnclosedStringLit, badUnclosedStringLitVal: val)

iterator tokenize*(input: string): Token =
    var i = 0
    var lineNum = 1
    var colNum = 1
    mainLoop: while i < input.len:
        template advance(): untyped =
            inc i
            inc colNum
            continue mainLoop
        template returnToken(token: Token): untyped =
            yield token
            advance()
    
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
                return

        # TODO Other cases
