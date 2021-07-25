
'	Generic Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TParser

	Field lexer:TLexer
	Field token:TSymbol
	
	Field symbolTable:TSymbolTable = New TSymbolTable()
	
	Method New( lexer:TLexer )
		Self.lexer = lexer
		Self.token = lexer.getnext()
	End Method
	
	Method parse:AST()
		ThrowException( "PARSER NOT IMPLEMENTED" )
	End Method

	' Dump the symbol table into a string
	Method reveal:String()
		Local report:String = "POSITION  NAME     TYPE          SCOPE~n"
		For Local row:TSymbolTableRow = EachIn symbolTable.list
			report :+ (row.line+","+row.pos)[..8]+"  "+row.name[..15]+"  "+row.symtype[..15]+"  "+row.scope+"~n"
		Next
		Return report
	End Method
	
	Private
	
	' Use Reflection to call the token method
	' REFLECTION HAS A BUG IN INVOKE THAT PREVENTS CALLING METHODS
	' THIS HAS THEREFORE BEEN DEPRECIATED
	'Method reflect( token:TSymbol )
	'	Local this:TTypeId = TTypeId.ForObject( Self )
	'	Local methd:TMethod = this.FindMethod( "token_"+token.class )
	'	If methd 
	'		methd.invoke( this, [token] )
	'	Else
	'		token_(token)
	'	End If
	'End Method
	
	' Null Token handler
	Method token_( token:TSymbol )
		ThrowException( "No method implemented for token '"+token.class+"'", token.line, token.pos )
	End Method

	
End Type