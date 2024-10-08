type TokenType* = enum
    IllegalToken
        ## An illegal token.
        ## This represents any token that is invalid.

    Ident
        ## Any identifier, a non-reserved keyword.

    QuotedIdent
        ## Like Ident, but quoted with backticks, and can have the same name as a reserved keyword.
        ## Example: ``export`` 

    BadUnclosedQuotedIdent
        ## Like QuotedIdent, but unclosed.
        ## Example: ``export`

    DocBlock
        ## A documentation comment block.
        ## Example: `/// Some documentation`
        ## 
        ## Note that contiguous newline-separated doc comments are merged into one.
        ## Example:
        ## ```
        ## /// Line 1
        ## /// Line 2
        ## /// @param foo The bar of the foo of the bar
        ## ```
        ## 
        ## Is read as: ` Line 1\n Line 2`.
        ## 
        ## The initial whitespace of each line is preserved.
        ## 
        ## Note that special syntax inside doc blocks are not tokenized; this is the responsibility of documentation generators.

    Dot
        ## `.`
    
    Comma
        ## `,`

    OpenParenthesis
        ## `(`

    CloseParenthesis
        ## `)`

    Colon
        ## `:`

    Semicolon
        ## `;`

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
    
    LesserEqualsComparison
        ## `<=`
    
    GreaterEqualsComparison
        ## `>=`

    AndComparison
        ## `&&`

    OrComparison
        ## `||`

    BoolNot
        ## `!`
    
    BitwiseAnd
        ## `&`
    
    BitwiseOr
        ## `|`
    
    BitwiseXor
        ## `^`
    
    BitwiseNot
        ## `~`
    
    Modulo
        ## `%`

    Exponent
        ## `**`
    
    Multiply
        ## `*`

    Divide
        ## `/`
    
    Add
        ## `+`

    Subtract
        ## `-`
    
    MultiplyAssignment
        ## `*=`
    
    DivideAssignment
        ## `/=`

    AddAssignment
        ## `+=`
    
    SubtractAssignment
        ## `-=`

    NamespaceKeyword
        ## `namespace`

    UsingKeyword
        ## `using`

    AsKeyword
        ## `as`

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

    ElseKeyword
        ## `else`

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

    CharLit
        ## A character literal.
        ## Example: `'a'`

    BadUnclosedCharLit
        ## A character literal that was never closed.
        ## Example: `'a`

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
    of IllegalToken:
        illegalTokenVal*: string
    of Ident:
        identName*: string
    of QuotedIdent:
        quotedIdentName*: string
    of BadUnclosedQuotedIdent:
        badUnclosedQuotedIdentVal*: string
    of DocBlock:
        docBlockVal*: string
    of Dot:
        discard
    of Comma:
        discard
    of OpenParenthesis:
        discard
    of CloseParenthesis:
        discard
    of Colon:
        discard
    of Semicolon:
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
    of LesserEqualsComparison:
        discard
    of GreaterEqualsComparison:
        discard
    of AndComparison:
        discard
    of OrComparison:
        discard
    of BoolNot:
        discard
    of BitwiseAnd:
        discard
    of BitwiseOr:
        discard
    of BitwiseXor:
        discard
    of BitwiseNot:
        discard
    of Modulo:
        discard
    of Exponent:
        discard
    of Multiply:
        discard
    of Divide:
        discard
    of Add:
        discard
    of Subtract:
        discard
    of MultiplyAssignment:
        discard
    of DivideAssignment:
        discard
    of AddAssignment:
        discard
    of SubtractAssignment:
        discard
    of NamespaceKeyword:
        discard
    of UsingKeyword:
        discard
    of AsKeyword:
        discard
    of Annotation:
        annotationName*: string
            ## The name of the annotation.
            ## If empty, no valid identifier followed the initial `@`, and the annotation is therefore invalid.
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
    of ElseKeyword:
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
        decimalLitValWhole*: string
            ## The whole part of the decimal literal.

        decimalLitValFrac*: string
            ## The fractional part of the decimal literal.
            ## May be empty.
    of CharLit:
        charLitVal*: string
            ## The content of the character literal.
            ## Represented by a string because it may contain control characters.
            ## Not guaranteed to be valid.
            ## May be empty or contain more than one rune (an invalid state).
    of BadUnclosedCharLit:
        badUnclosedCharLitVal*: string
            ## The content of the character literal that was never closed.
            ## Represented by a string because it may contain control characters.
            ## Not guaranteed to be valid.
    of StringLit:
        stringLitVal*: string
    of BadUnclosedStringLit:
        badUnclosedStringLitVal*: string
    of TrueLit:
        discard
    of FalseLit:
        discard
