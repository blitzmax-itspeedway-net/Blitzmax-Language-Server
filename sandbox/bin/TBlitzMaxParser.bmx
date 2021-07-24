
'	BlitzMax Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "TParser.bmx"

'	A LANGUAGE SYNTAX IS CURRENTLY UNAVAILABLE
'	THIS IS THEREFORE HARDCODED AT THE MOMENT
'	IT WILL BE RE-WRITTEN WHEN SYNTAX IS DONE

Type TBlitzMaxParser Extends TParser

	Field strictmode:Int = 0
	
	Method parse:AST()
		Local token:TSymbol
		
		Rem 	ABNF
				program = [ application | module ]
				application = [strictmode] [framework] [*import] [*include] block
				module = [strictmode] moduledef [*import] [*include] block
		End Rem
DebugStop
		' STRICTMODE
		If lexer.peek( ["superstrict","strict"] )
			Print "STRICTMODE"
			'reflect( lexer.getnext() )
			token_strictmode( lexer.getnext() )
		End If
		'If lexer.peek( ["module"]
		'	Print
		'If lexer.peek( ["framework"]

	End Method

	Private
	
	Method token_strictmode( token:TSymbol )
		Select token.class
		Case "strict"		;	strictmode = 1
		Case "superstrict"	;	strictmode = 2
		End Select
	End Method

	Private
	
	Method Do_Strict_Mode()
		lexer.skip( "comment" )
		Local sym:TSymbol = lexer.peek( "reserved" )
		If Not sym Return
		Select sym.value
		Case "strict"		;	strictmode = 1
		Case "superstrict"	;	strictmode = 2
		End Select
		If strictmode>0 lexer.getnext()
	End Method
	
	Method Do_Framework()
		lexer.skip( "comment" )
		Local sym:TSymbol = lexer.peek( "reserved" )
		If Not sym Return
		If sym.value="framework"
			lexer.getnext()	' framework
			lexer.expect( "alpha" )
			lexer.expect( "symbol",".")
			lexer.expect( "alpha" )
		End If
	End Method

	Method Do_Imports()
		lexer.skip( "comment" )
		Local sym:TSymbol = lexer.peek( "reserved" )
		If Not sym Return
		If sym.value="import"
			lexer.getnext()	' framework
			lexer.expect( "alpha" )
			lexer.expect( "symbol",".")
			lexer.expect( "alpha" )
		End If
	End Method	
	
End Type