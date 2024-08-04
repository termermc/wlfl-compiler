type TokenType* = enum
    Keyword
    QuotedKeyword
    Dot
    OpenParenthesis
    CloseParenthesis
    Colon
    Semicolon
    Asterisk
    Assignment
    EqualsComparison
    NotEqualsComparison
    LesserComparison
    GreaterComparison
    AndComparison
    OrComparison
    NamespaceKeyword
    UsingKeyword
    Annotation
    ExportKeyword
    FuncKeyword
    ReturnKeyword
    BreakKeyword
    ContinueKeyword
    DoKeyword
    LetKeyword
    VarKeyword
    ConstKeyword
    IfKeyword
    WhileKeyword
    OpenCurlyBracket
    CloseCurlyBracket
    OpenSquareBracket
    CloseSquareBracket
    IntegerLit
    DecimalLit
    HexLit
    CharLit
    StringLit
    TrueLit
    FalseLit

type Token* = object
    lineNum*: uint32
    colNum*: uint32

    case kind*: TokenType
    of Keyword:
        keywordName*: string
    of QuotedKeyword:
        quotedKeywordName*: string
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
    of TrueLit:
        discard
    of FalseLit:
        discard
