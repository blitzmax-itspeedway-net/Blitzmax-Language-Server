
'	Generic Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "AbstractSyntaxTree.bmx"

' Exception handler for Parse errors
Type TParseError Extends TException
End Type

Function ThrowParseError( message:String, line:Int=-1, pos:Int=-1 )
	Throw( New TParseError( message, line, pos ) )
End Function

' Generic Parser

Type TParser

	Field lexer:TLexer
	Field token:TToken
	
	Field abnf:TABNF			' ANBF Grammar rules
	Field ast:AST				' Abstract Syntax Tree
	
	Method New( lexer:TLexer )
'DebugStop
		Self.lexer = lexer
		Self.token = lexer.getnext()
	End Method
	
	Method parse( rulename:String = "" )
'	Method testabnf:Int( rulename:String, path:String="" )
DebugStop
		' First order of the day is to run the lexer...
		Local start:Int, finish:Int
		start = MilliSecs()
		lexer.run()
		finish = MilliSecs()
		Print( "LEXER.TIME: "+(finish-start)+"ms" )
	
		Print( "Starting debug output...")
		Print( lexer.reveal() )
DebugStop
		' If no rulename passed, then use first rule in ANBF
		If rulename="" rulename = abnf.first()
		If rulename="" Return ' No starting node (Empty ABNF?)
		ast = walk( rulename )
		
	End Method
	
	' Generic ABNF tree walker that generates AST
	Method walk:AST( rulename:String, path:String="" )
DebugStop	
		Local match:AST = Null
		Local column:String = (path+rulename)[..30]
		
		Local node:TGrammarNode = abnf.find( rulename )
		If Not node
			Print column+"-Rule '"+rulename+"' Not found"
			Return Null
		End If		

		' Find rule
		'Local rule:TGNode = abnf.find( rulename )
		Repeat
			If node.terminal
				Print column+"-Node '"+rulename+"' is a terminal"

				Local token:TToken = lexer.peek()
				Print column+"-Comparing token '"+token.class+"' with '"+node.token.class+"'"
				
				If node.token.class = token.class
					'MATCHED
					Print column+"-MATCHED"
					match = New AST( token )
					lexer.getnext()
					Print column+"-CALLING rule_"+rulename+"()"
				Else
					'GETNEXT SYMBOL
					Print column+"-NO MATCH"
					match = Null
				EndIf
			Else
				Print column+"-Node '"+rulename+"' is a non-terminal"
				match = walk( node.token.class, rulename+"|" )
				Print column+"-Returned to '"+rulename+"'"
			End If
			'
			If match
				node=node.suc
				If node 
					Print column+"-Moving To successor ("+node.token.class+")"
				Else
					Print column+"-No successor"
				End If
			Else 
				node=node.alt
				If node 
					Print column+"-Moving To alternate ("+node.token.class+")"
				Else
					Print column+"-No alternate"
				End If
			End If
		Until Not node
		Return match
	End Method
	
	Method OLDparse:AST()
		ThrowException( "PARSER NOT IMPLEMENTED" )
	End Method

	' Used for debugging purposes.
	Method reveal:String()
	End Method
	
	Private

	' This method is used by the parser to synchronise following a syntax error
	' It is ALWAYS language dependent, so is defined as abstract here
	Method error_recovery() Abstract
	
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