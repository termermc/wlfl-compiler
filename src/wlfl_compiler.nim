import std/unicode
import ./tokenizer

# const code = """
# "\"test!\"" 
# '"\'
# ''
# 'fdsfoih
# '\0'
# "test"
# `export`
# ==
# =
# !=
#     /// Doc block line 1
#     /// Doc block line 2
# 0// Normal comment 1
# !
# && // Normal comment 2
# &
# ||
# |
# <=
# <
# >=
# >
# @cat0
# `fmt`0.1"lol"00.
# '中国'
# var const
# varconst lol const
# testingIdent_lol
# const 中国 = "china"
# test let
# 0a
# _0a""".toRunes()
const code = """

namespace thing.stuff.code;

// Import time library
using std.time as stdtime;
using std.math.random;

/// Does stuff
/// @returns Stuff
@NoMangle
export func doStuff(): String {
    println(time.nowEpoch().toString());

    let someRandom = random(0, 100);
    println("Now: " + someRandom.toString());

    let multiLineString = "Line1
Line2
Line3";
    println(multiLineString);

    // Use backtick-quoted keywords to use them as identifiers
    var `export` = "something something";

    if (`export` == "something something") {
        return "something something";
    } else {
        return "something else";
    }

    var i = 0;
    do {
        i += 1;
        println(i);
    } while (i < 10);

    // Should produce an illegal token:
    \
}

""".toRunes()

proc main(): int =
    for token in tokenize(code):
        echo token

    return 0

when isMainModule:
    quit(main())
