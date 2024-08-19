import token

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

iterator tokenize*(input: string): Token =
    var i = 0
    var lineNum = 1
    var colNum = 1
    block mainLoop:
        while i < input.len:
            block mainLoopInner:
                template advance(): untyped =
                    inc i
                    inc colNum

                    # Continue
                    break mainLoopInner
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
                        # Return
                        break mainLoop
                else:
                    echo "TODO Other cases"
                    quit(1)

                # TODO Other cases
