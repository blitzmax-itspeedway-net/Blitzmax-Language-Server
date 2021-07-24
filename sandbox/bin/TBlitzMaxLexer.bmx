
'	BlitzMax Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "TLexer.bmx"

Type BlitzMaxLexer Extends TLexer

	Method New( text:String )
		Super.New( text )
		Print "Starting MAXLexer"
		
		' Define Lexer options
		linecomment_symbol = "'"
		valid_symbols      = "#$%()*+,-.:;<=>[]^"
		compound_symbols   = "<> >= <= :+ :- :* :/ .."
		
		' Language specific definitions
		RestoreData bmx_expressions
		define( "expression", expressions )
		RestoreData bmx_reservedwords
		define( "reserved", reservedwords )

		' For debugging:
		include_comments = True
	End Method

	Method LexAlpha:TSymbol( text:String, line:Int, pos:Int )
		Local criteria:String = "["+Lower(text)+"]"	' Case insensitive search criteria
		For Local token:String = EachIn tokens.keys()
			If Instr( String(tokens[token]), criteria ) Return New TSymbol( token, Lower(text), line, pos )
		Next
		Return New TSymbol( "alpha", text, line, pos )
	End Method
		
End Type

