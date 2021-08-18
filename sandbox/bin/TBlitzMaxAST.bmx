
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
		Local peek:TToken = lexer.getnext()
		'If peek.id=TK_EOLDebugStop
		lexer.getnext()
	End Method
	
End Type
		


