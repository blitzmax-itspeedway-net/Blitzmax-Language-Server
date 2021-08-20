
'	BlitzMax Abstract Syntax Tree
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	17 AUG 21	Initial version

Type TAST_Comment Extends TASTNode

	Method New( token:TToken )
		name = "COMMENT"
		consume( token )
	End Method
	
End Type

Type TAST_Strictmode Extends TASTNode

	Method New( lexer:TLexer, token:TToken, def:TToken )
		name = "STRICTMODE"
		If def definition = def.value
		consume( token )
		'
		token = lexer.expect( [TK_COMMENT,TK_EOL] )
		If token.id = TK_EOL Return
		' Inline comment becomes the node description
		descr = token.value
		lexer.Expect( TK_EOL )
	End Method
	
End Type
		


