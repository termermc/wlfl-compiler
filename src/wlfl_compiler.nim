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
!
&&
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
