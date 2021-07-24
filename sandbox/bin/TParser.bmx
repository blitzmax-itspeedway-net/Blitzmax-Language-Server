
'	Generic Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TParser

	Field lexer:TLexer
	Field token:TSymbol
	
	Method New( lexer:TLexer )
		Self.lexer = lexer
		Self.token = lexer.getnext()
	End Method
	
	Method parse:AST()
		ThrowException( "PARSER NOT IMPLEMENTED" )
	End Method
	
	' Use Reflection to call the token method
	Method reflect( token:TSymbol )
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( "token_"+token.class )
		If methd 
			methd.invoke( this, [token] )
		Else
			token_(token)
		End If
	End Method
	
	' Null Token handler
	Method token_( token:TSymbol )
		ThrowException( "No method implemented for token "+token.class, token.line, token.pos )
	End Method
	
End Type