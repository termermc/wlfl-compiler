type TokenType* = enum
    Keyword
        ## Any unreserved keyword

    QuotedKeyword
        ## Like Keyword, but quoted with backticks, and can have the same name as a reserved keyword.
        ## Example: ``export`` 

    BadUnclosedQuotedKeyword
        ## Like QuotedKeyword, but unclosed.
        ## Example: ``export`

    Dot
        ## `.`

    OpenParenthesis
        ## `(`

    CloseParenthesis
        ## `)`

    Colon
        ## `:`

    Semicolon
        ## `;`

    Asterisk
        ## `*`

    Assignment
        ## `=`

    EqualsComparison
        ## `==`

    NotEqualsComparison
        ## `!=`

    LesserComparison
        ## `<`

    GreaterComparison
        ## `>`

    AndComparison
        ## `&&`

    OrComparison
        ## `||`

    NamespaceKeyword
        ## `namespace`

    UsingKeyword
        ## `using`

    Annotation
        ## `@` followed by zero or more alphanumeric characters.
        ## A number must not immediately follow the `@`.

    ExportKeyword
        ## `export`

    FuncKeyword
        ## `func`

    ReturnKeyword
        ## `return`

    BreakKeyword
        ## `break`

    ContinueKeyword
        ## `continue`

    DoKeyword
        ## `do`

    LetKeyword
        ## `let`

    VarKeyword
        ## `var`

    ConstKeyword
        ## `const`

    IfKeyword
        ## `if`

    WhileKeyword
        ## `while`

    OpenCurlyBracket
        ## `{`

    CloseCurlyBracket
        ## `}`

    OpenSquareBracket
        ## `[`

    CloseSquareBracket
        ## `]`

    IntegerLit
        ## An integer literal.
        ## Example: `123`

    DecimalLit
        ## A decimal literal.
        ## Example: `123.456`

    HexLit
        ## A hexadecimal literal.
        ## Example: `0x123`

    CharLit
        ## A character literal.
        ## Example: `'a'`

    StringLit
        ## A string literal.
        ## String literals store the string value without processing any escape sequences.
        ## Example: `"Hello, world!"`
    
    BadUnclosedStringLit
        ## A string literal that was never closed.
        ## Example: `"Hello, world!`

    TrueLit
        ## A true literal.
        ## Example: `true`

    FalseLit
        ## A false literal.
        ## Example: `false`

type Token* = object
    lineNum*: uint32
    colNum*: uint32

    case kind*: TokenType
    of Keyword:
        keywordName*: string
    of QuotedKeyword:
        quotedKeywordName*: string
    of BadUnclosedQuotedKeyword:
        badUnclosedQuotedKeywordVal*: string
    of Dot:
        discard
    of OpenParenthesis:
        discard
    of CloseParenthesis:
        discard
    of Colon:
        discard
    of Semicolon:
        discard
    of Asterisk:
        discard
    of Assignment:
        discard
    of EqualsComparison:
        discard
    of NotEqualsComparison:
        discard
    of LesserComparison:
        discard
    of GreaterComparison:
        discard
    of AndComparison:
        discard
    of OrComparison:
        discard
    of NamespaceKeyword:
        discard
    of UsingKeyword:
        discard
    of Annotation:
        annotationName*: string
    of ExportKeyword:
        discard
    of FuncKeyword:
        discard
    of ReturnKeyword:
        discard
    of BreakKeyword:
        discard
    of ContinueKeyword:
        discard
    of DoKeyword:
        discard
    of LetKeyword:
        discard
    of VarKeyword:
        discard
    of ConstKeyword:
        discard
    of IfKeyword:
        discard
    of WhileKeyword:
        discard
    of OpenCurlyBracket:
        discard
    of CloseCurlyBracket:
        discard
    of OpenSquareBracket:
        discard
    of CloseSquareBracket:
        discard
    of IntegerLit:
        integerLitVal*: string
    of DecimalLit:
        decimalLitVal*: string
    of HexLit:
        hexLitVal*: string
    of CharLit:
        charLitVal*: char
    of StringLit:
        stringLitVal*: string
    of BadUnclosedStringLit:
        badUnclosedStringLitVal*: string
    of TrueLit:
        discard
    of FalseLit:
        discard
