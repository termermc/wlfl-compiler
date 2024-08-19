import ./tokenizer

const code = """
"\"test!\"" 
"test"
`export`
"""

proc main(): int =
    for token in tokenize(code):
        echo token

    return 0

when isMainModule:
    # Exit with main() return code
    quit(main())
