
'	Generic Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TParser

	Field lexer:TLexer
	Field token:TToken
	
	Field symbolTable:TSymbolTable = New TSymbolTable()
	
	Field abnf:TABNF = New TABNF			' ANBF Grammar rules
	
	Method New( lexer:TLexer )
		Self.lexer = lexer
		Self.token = lexer.getnext()
	End Method
	
		Method testabnf:String( rulename:String )
DebugStop	
		'Local s:TGNode =
		Local token:TToken = lexer.peek()
		' Find rule
		'Local rule:TGNode = abnf.find( rulename )
		Local node:TGnode = abnf.find( rulename )
		Repeat
			If node.terminal
				If node.sym.value = token.class
					'MATCHED
				Else
					'GETNEXT SYMBOL
				EndIf
			Else
				Local match:String = testabnf( node.sym.value )
				If match
					node=node.suc
				Else 
					node=node.alt
				End If
			End If
		Until Not node
		
	End Method
	
	Method parse:AST()
		ThrowException( "PARSER NOT IMPLEMENTED" )
	End Method

	' Dump the symbol table into a string
	Method reveal:String()
		Local report:String = "POSITION  SCOPE     NAME      TYPE~n"
		For Local row:TSymbolTableRow = EachIn symbolTable.list
			report :+ (row.line+","+row.pos)[..8]+"  "+row.scope[..8]+"  "+row.name[..8]+"  "+row.class[..8]+"~n"
		Next
		Return report
	End Method
	
	Private
	
	' Use Reflection to call the token method
	Method reflect( token:TToken )
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( "token_"+token.class )
		If methd 
			methd.invoke( Self, [token] )
		Else
			token_(token)
		End If
	End Method
	
	' Null Token handler
	Method token_( token:TToken )
		ThrowException( "No method implemented for token '"+token.class+"'", token.line, token.pos )
	End Method

	
End Type