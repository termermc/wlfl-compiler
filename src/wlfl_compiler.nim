import ./tokenizer

const code = """
"\"test!\"" 
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
"""

proc main(): int =
    for token in tokenize(code):
        echo token

    return 0

when isMainModule:
    quit(main())
