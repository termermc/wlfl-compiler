import std/unicode
import ./tokenizer

const code = """
"\"test!\"" 
'"\'
''
'fdsfoih
'\0'
"test"
`export`
==
=
!=
    /// Doc block line 1
    /// Doc block line 2
0// Normal comment 1
!
&& // Normal comment 2
&
||
|
<=
<
>=
>
@cat0
`fmt`0.1"lol"00.
'中国'
""".toRunes()

proc main(): int =
    for token in tokenize(code):
        echo token

    return 0

when isMainModule:
    quit(main())
