
'	LEXER CONSTANTS FOR ABNF
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

' 	DEFINE SYMBOLS

Const SYM_LINECOMMENT:String = ";"
Const SYM_ALPHAEXTRA:String  = "-"	' Additional Characters allowed in ALPHA

'	COMPOUND SYMBOLS

Const TK_HEXDIGIT:Int		= 512	'	%x

'	IDENTIFIERS

Const TK_Group:Int 			= 610	'	()
Const TK_Optional:Int 		= 611	'	[]
Const TK_Repeat:Int 		= 612	'	*


