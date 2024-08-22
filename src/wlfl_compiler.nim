import ./tokenizer

const code = """
"\"test!\"" 
'"\'
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
`fmt`0."lol"
"""

proc main(): int =
    for token in tokenize(code):
        echo token

    return 0

when isMainModule:
    quit(main())
