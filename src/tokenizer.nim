import token

const escapeSequences = {
    'n': '\n',
    'r': '\r',
    't': '\t',
}

func charForEscape(escape: char): char =
    if escape in escapeSequences:
        return escapeSequences[escape]
    else:
        return escape

iterator tokenize*(input: string): Token =
    var i = 0
    var lineNum = 1
    var colNum = 1
    mainLoop: while i < input.len:
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

        if c == '"':
            var gotClose = false
            var buf = ""

            while i < input.len:
                let c = input[i]
                inc i
                if c == '"':
                    gotClose = true
                    break
                buf.add c
            
            if not gotClose:
                # Bad string literal, nothing to return
                break mainLoop

        
    
