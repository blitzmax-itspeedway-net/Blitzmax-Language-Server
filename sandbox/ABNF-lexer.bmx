
'   ABNF BASED GENERIC LEXER
'   (c) Copyright Si Dunford, July 2021, All Rights Reserved

'   # HOLDING PAGE
'   # THINGS TO DO

'   TARGET:
'   * Use rules defined in abnf.abnf to lex and parse into a Node-Tree
'   * Use rules defined in custom (JSON and Blitzmax) abnf to lex and parse into node-tree
'

REM Notes
* Lexer will need to obtain tokens/symbols from the abnf to create the token stream
* To do this it must identify:
    Constants
        ; ForNext = "for" ["local"] VarDef "=" "eachin" identifer EOL ForBlock "next" EOL
    Single word constants:
        ; SuperStrict = "superstrict"
        ; Strict = "Strict"
        ; StrictMode = "strict" / "superstrict"
        ; comma = ","
        ; EOL = %d13.10
    Optional Symbol Lists
        (This should create a searchstring of individual characters: "~q ~r~n" )
        ; WSP = TAB / SP / CR / LF
* All tokens will be saved in typecase specified in the constant
end rem

incbin "bin/abnf.abnf"

local abnf:TABNF = new TABNF( "incbin::bin/abnf.abnf" )

Type TABNF
End Type

Type TLexer
end Type

Type TParser
end Type

