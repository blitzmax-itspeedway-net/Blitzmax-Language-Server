
'	Generic Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

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
	
	Method New( lexer:TLexer, abnf:TABNF=Null )
'DebugStop
		Self.lexer = lexer
		Self.token = lexer.getnext()
		Self.abnf  = abnf
	End Method
	
	Method parse:Object( rulename:String = "" )
'	Method testabnf:Int( rulename:String, path:String="" )
'DebugStop
		' First order of the day is to run the lexer...
		Local start:Int, finish:Int
		start = MilliSecs()
		lexer.run()
		finish = MilliSecs()
		Print( "LEXER.TIME: "+(finish-start)+"ms" )
	
		Print( "Starting debug output...")
		Print( lexer.reveal() )
'DebugStop
		' If no rulename passed, then use first rule in ANBF
		Publish( "PARSE-START", Null )
		
		If rulename="" rulename = abnf.first()
		If rulename="" Return Null' No starting node (Empty ABNF?)
		ast = walk( rulename )

		Publish( "PARSE-FINISH", Null )
		
	End Method
	
	' Generic ABNF tree walker that generates AST
	Method walk:AST( rulename:String, path:String="" )
DebugStop	
		Local token:TToken
		Local match:AST = Null
		Local column:String = (path+rulename)[..30]
		
		Print "# RULE: "+rulename
		Local node:TGrammarNode = abnf.find( rulename )
		If Not node
			Print column+" - Rule '"+rulename+"' Not found"
			Return Null
		End If

		' Find rule
		'Local rule:TGNode = abnf.find( rulename )
		Repeat
		Print "# NODE: "+node.token.value

DebugStop
			If node.terminal
				Print column+"- Node '"+rulename+"' is a terminal"

				token = lexer.peek()
				Print "# TOKEN: "+node.token.value
				Print column+"- Comparing tokens"
DebugStop
				match = Null
				If compare( node.token, token )
					match = New AST( token )
					lexer.getnext()
				End If
Rem				
				Select True
				Case (node.token.id=TK_QString) And (token.id=TK_Identifier)
'DebugStop
					If node.token.value = token.class
						Print column+"- MATCHED"
						match = New AST( token )
						lexer.getnext()
						'Print column+"-CALLING rule_"+rulename+"()"
				'	Else
				'		match = Null
					End If
				'Case TK_QString
'DebugStop
				'	If node.token.value = "~q"+token.class+"~q"
				'		Print column+"- QSTRING MATCHED"
				'		match = New AST( token )
				'		lexer.getnext()
						'Print column+"-CALLING rule_"+rulename+"()"
				'	Else
				'		match = Null
				'	End If
				Default
					Print column+"- Unable to compare different token types"
				'	match = Null
				End Select
				
				If Not match Print column+"- NO MATCH"
End Rem
			Else
				Print column+"- Node '"+node.token.value+"' is a non-terminal"
				match = walk( node.token.value, rulename+"|" )
				Print column+"- Returned to '"+rulename+"'"
			End If
			'
			' Do we have a no-match but alternatives?
			If Not match And node.alt ; match = walk_alternate( node.alt, token )
			'
			If match
				Print "- MATCHED"
				node=node.suc
				If node 
					Print column+"-Moving To successor ("+node.token.value+")"
					lexer.getnext()
WHEN LINECOMMENT IS READ HERE, WE MUST COMPARE THE TOKENS Not THE
RULE
				Else
					Print column+"-No successor"
					Return match
				End If
			Else 
				Print "- UNMATCHED"
				Publish( "DIAGNOSTIC", "Unexpected token", token )
				Print "###> DIAGNOSTIC : Unexpected token '"+ token.value + "' at "+token.line+","+token.pos
				Return Null
			End If
		Until Not node Or node.token.id=TK_EOF
		Return match
	End Method
	
	Method walk_alternate:AST( node:TGrammarNode, token:TToken )
		Local match:AST = Null
'DebugStop

		While node
			If compare( node.token, token )
				match = New AST( token )
				Exit
			End If
			node = node.alt
		Wend
	
		Return match
	End Method

	Method compare:Int( this:TToken, that:TToken )
		Print "- Comparing ["+this.id+"/"+this.class+"/"+this.value+"] to ["+that.id+"/"+that.class+"/"+that.value+"]"
		Select True
		Case ( this.id=TK_QString ) And ( that.id=TK_Identifier )
			If this.value = that.class ; Return True
		Default
			Print "- Unable to compare different token types"
		End Select
		Print "- NO MATCH"
		Return False
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