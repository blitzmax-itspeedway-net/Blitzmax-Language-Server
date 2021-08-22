
'	Generic Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	TERMINAL		- Token that defines a constant or optional string
'	NON-TERMINAL	- Token that defines the rules (usually leading to another rule)

'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version
'	V1.1	16 AUG 21	Removed BNF generic parsing due to limitations

' Exception handler for Parse errors
Type TParseError Extends TException
End Type

Function ThrowParseError( message:String, line:Int=-1, pos:Int=-1 )
	Throw( New TParseError( message, line, pos ) )
End Function

Type TParseResult
	Field ast:TASTNode
	Field syntax:TToken[] = []
	'Field success:Int = false
	
	Method New( syntax:TToken )
		Self.syntax :+ [syntax]
	End Method
	
	Method New( syntax:TToken[] )
		Self.syntax = syntax
	End Method
	
	Method add( token:TToken )
		syntax :+ [token]
	End Method
	
	Method add( tokens:TToken[] )
		syntax :+ tokens
	End Method
End Type

' Generic Parser

Type TParser

	Field lexer:TLexer
	Field token:TToken
	
	Field ast:TASTNode		' Abstract Syntax Tree
	
	Method New( lexer:TLexer )
'DebugStop
		Self.lexer = lexer
		Self.token = lexer.getnext()
	End Method
	
	Method parse:TASTNode()
'	Method testabnf:Int( rulename:String, path:String="" )
'DebugStop
		Print "~nSTARTING LEXER:"
		' First order of the day is to run the lexer...
		Local start:Int, finish:Int
		start = MilliSecs()
		lexer.run()
		finish = MilliSecs()
		Print( "LEXER.TIME: "+(finish-start)+"ms" )
	
		Print( "STARTING LEXER DEBUG:")
		Print( lexer.reveal() )
'DebugStop
		' If no rulename passed, then use first rule in ANBF		
		'If rulename="" rulename = abnf.first()
		'If rulename="" Return Null' No starting node (Empty ABNF?)
		'ast = walk_rule( rulename )

'DebugStop
		Print "~nSTARTING PARSER:"
		Publish( "PARSE-START", Null )		
		lexer.reset()
		Local program:TASTNode = parse_program()
		Publish( "PARSE-FINISH", Null )
		
		' Check that file parsing has completed successfully
		Local after:TToken = lexer.peek()
		If after.id <> TK_EOF ; ThrowParseError( "'"+after.value+"' unexpected past End", after.line, after.pos )
		
		' Print state and return value
'DebugStop
		If program
			Print "PARSING SUCCESS"
			Return program
		Else
			Print "PARSING FAILURE"
			Return Null
		End If
	End Method

	Private
		
	Method parse_program:TASTNode() Abstract
	
	
	Rem
	Method parse_rule:TASTNode( rulename:String, indent:String="" )
		Local result:TASTnode[] '= New TParseResult()
		
		' Get grammar node
		If rulename = "" Return Null	' Rule cannot be empty!
		Local node:TGrammarNode = abnf.find( rulename )
		If Not node Return Null			' Missing rule

'DebugStop
'If rulename="optseq" DebugStop

		Print indent+"RULE: "+rulename
		indent :+ "  "
		result = parse_sequence( node, indent )
		Local tree:TASTNode
		
		If result And result[0]
			Print indent+"REFLECT: rule_"+Replace(Lower(rulename),"-","")+"()"
			
			' DEBUG THE MATCH
			Local line:String = rulename+"="
			For Local node:TASTNode = EachIn result
				line :+ "["+node.token.value+":"+node.token.class+"]"
			Next
			Print indent+line
			
			' Parse into AST
'DebugStop
			tree = reflect( Replace(Lower(rulename),"-",""), result )
		Else
			Print indent+rulename+" failed"
			Return Null
		End If
		
		Return tree
	End Method

	' Parse a sequence. 
	'	Returns Syntax=[] if that sequence fails
	Method parse_sequence:TASTNode[]( node:TGrammarNode, indent:String )
		Local sequence:TASTNode[] = []
'DebugStop		
		' Walk the successor until node complete
		While node And node.token.id<>TK_EOF
'Print indent+"WALKING: "+node.token.reveal()
'DebugStop
			Local result:TASTNode[] = parse_node( node, indent )
			If result And result[0]
				Print indent+node.token.value+" is Success"
'DebugStop
				sequence :+ result
			Else
				Print indent+node.token.value+" is Fail"
' 10/8/21, Changed return type from sequence to null on failure
				Return Null
			End If
			node = node.suc
		Wend
		Return sequence
	End Method
	
	Method parse_node:TASTNode[]( node:TGrammarNode, indent:String )
'DebugStop
		Local result:TASTNode[] = []
		If node.terminal
			Local token:TToken = lexer.peek()
'If token.id=603 DebugStop
			Print indent+"GOAL: ("+token.id+") "+token.class+"="+token.value
			'Print "TERMINAL"
			'Print indent+node.token.value+":"+node.token.class+" ("+node.token.id+") - TERMINAL"
			'Print indent+"- Comparing with "+token.reveal()
			' Try alternatives until we get a match (or not)
			While node
				Select node.token.id
				Case TK_Group
'DebugStop					
					Print indent+"Matching group"
					result = parse_sequence( node.opt, indent+"  " )
					If result And result[0]
						Print indent+"Matched"
						node = Null		' Force loop exit upon match
					Else
						Print indent+"No match"
						node = node.alt	' Try next alternative (if one exists)
					End If

				Case TK_Optional
					
					Print indent+"Matching optional"
'DebugStop
					result = parse_sequence( node.opt, indent+"  " )
					If result And result[0]
						Print indent+"Matched optional"
					Else
						Print indent+"No match (optional)"
						' If no match was found, Create an empty node
						'result = New TParseResult( New TToken( TK_Empty, "EMPTY",0,0,"EMPTY") ) 
						result = [ New TASTNode( New TToken( TK_Empty, "EMPTY",0,0,"EMPTY") ) ]
					End If

					node = node.alt	' Try next alternative (if one exists)

				Case TK_Repeater
					' The next token or sequence is repeated
					Print indent+"Matching Repeating Pattern"
'DebugStop
					Local repeater:TASTNode[]
					Repeat
						result = parse_sequence( node.opt, indent+"  " )
'DebugStop
						If result And result[0]
							Print indent+"Matched"
							repeater :+ result
						Else
							Print indent+"No match"
						End If
					Until Not result
					
'DebugStop
					
					'Return New TParseResult( repeater )
					Return repeater
				Default
					'Print indent+node.token.value+" (TERMINAL)"
					Print indent+"Comparing ("+token.id+") '"+token.value+":"+token.class+"' with "+node.token.value

' When matching COMMENT, it needs to match the node.token.value with token.class
					If node.token.value = token.class
						Print indent+"MATCHED CLASS"
						lexer.getnext()	' Consume the token
						'Return New TParseResult( token )
						Return [New TASTNode( token )]
					End If
'					If node.token.value = token.value
'						Print indent+"MATCHED"
'						lexer.getnext()	' Consume the token
'						Return New TParseResult( token )
'					End If
					node = node.alt

				End Select
			Wend
			'Print indent+"NO MATCHES"
			'ThrowParseError( "'"+token.value+"' was unexpected at this time", token.line,token.pos)
			Return result
		Else
'DebugStop
			Print indent+node.token.value+" (NON-TERMINAL)"
			Return [parse_rule( node.token.value, indent )]
		End If
	
	End Method
	
	End Rem

'/// BAD PARSING ATTEMPTS PAST HERE


Rem
	Method parse_token:AST( token:TToken )
		Select token.id
		Case TK_Alpha
			Return parse_alpha( token )
		End Select
	End Method
	
	Method parse_alpha:AST( token:TToken )
		Return New AST( "alpha", token )
	End Method
	
	Method walk_rule:AST( rulename:String, path:String="" )
	
		Local token:TToken
		Local match:AST = Null
		Local column:String = (path+rulename)[..30]
		
		Print "# RULE: "+rulename
		Local node:TGrammarNode = abnf.find( rulename )
		If Not node
			Print column+" - Rule '"+rulename+"' Not found"
			
			' NEED TO CHECK FOR IN-BUILT LIKE ALPHA/COMMENT ETC
			' MAYBE EXTEND ABNF TO MAKE THESE <linecomment> or <alpha> SYMBOLS
			
			Return Null
		End If
		
		Local rule_ast:AST = New AST( rulename, New TToken( 0, rulename, 0,0, "rulename" ) )
		
		
		While node And node.token.id<>TK_EOF
			Local result:AST = walk_node( node, token )
			node = node.suc
		Wend
		
		'Rule will either be success (AST) or fail (NULL)
		Repeat
			' If the node is a non-terminal, parse that rule
			' If it has options or alternatives, make sure those are checked
			Local result:AST = walk_node( node, token )
		
		Until Not node Or node.token.id=TK_EOF
		Return match		
	End Method
	
	Method walk_node:AST( node:TGrammarNode, token:TToken )
	
		Select node.token.id
		Case TK_Group
			token = lexer.getNext()
			Return walk_node( node.alt, token )
		Case TK_Optional
			token = lexer.getNext()
			Return walk_node( node.opt, token )
		Case TK_Repeater
			token = lexer.getNext()
			Local result:AST
			Repeat
				result = walk_node( node.opt, token )
			Until Not result
			Return ast
		Default
			While node And node.token.id<>TK_EOF
				' Move to alternative
				node = node.alt			
			Wend
			Return Null	' No match
		End Select
		
	End Method
	
	Method walk_alt:AST( node:TGrammarNode, token:TToken )
		While node And node.token.id<>TK_EOF		
			If node.terminal
				If node.token.id = TK_lessthan
					' Token compare
					' THIS IS A TOKEN COMPARE NOT A VALUE COMPARE
				Else
					' Value compare
					' ALSO NEED TO CHECK FOR "EMPTY" WHICH IS ALWAYS TRUE
					If compare( node.token, token )
						' We have a match, so return an AST node
						Return New AST( "", token )
					End If
					' Move to alternative
					node = node.alt
				End If
			Else
				Local result:AST = walkxxx( node.token.value )
			End If
		Wend
		Return Null	' No match
	End Method
	
	
	
	' Generic ABNF tree walker that generates AST
	Method walkxxx:AST( rulename:String, path:String="" )
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

If node.token.value = "linecomment" DebugStop
DebugStop
			If node.terminal
				Print column+"- Node '"+rulename+"' is a terminal"

				token = lexer.peek()
				Print "# TOKEN: "+node.token.value
				Print column+"- Comparing tokens"
DebugStop
				match = Null
				If compare( node.token, token )
					match = New AST( "",token )
					lexer.getnext()
				End If
			Else
				Print column+"- Node '"+node.token.value+"' is a non-terminal"
				match = walkxxx( node.token.value, rulename+"|" )
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
				Else
					Print column+"-No successor"
					Return match
				End If
			Else 
				Print "- UNMATCHED"
				'Publish( "DIAGNOSTIC", "Unexpected token", token )
				'Print "###> DIAGNOSTIC : Unexpected token '"+ token.value + "' at "+token.line+","+token.pos
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
				match = New AST( "",token )
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
End Rem

	' Used for debugging purposes.
	Method reveal:String()
	End Method
	
	Private

	' This method is used by the parser to synchronise following a syntax error
	' It is ALWAYS language dependent, so is defined as abstract here
	Method error_recovery() Abstract
	
	' Use Reflection to call the token method
	Rem 
	Method reflects:Object( token:TToken, argumentspre:String="token", defaultMethod:Int=True )
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( pre+token.class )
		If methd 
			methd.invoke( Self, [token] )
		ElseIf defaultMethod
			token_(token)
		End If
	End Method
	End Rem
	
'22 AUG 21	I cannot use reflection here until I can find a way
'			of passing the Token (Argument) by reference
	Method reflect:TASTNode( identifier:String, argument:TToken )
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( "Parse_"+identifier )
'DebugStop
		If methd Return TASTNode( methd.invoke( Self, [argument] ))
		'Print( "- Parser.Farse_"+identifier+"() does not exist" )
		'Return New TASTNode( "ERROR" )
		Throw( "Parser.Parse_"+identifier+"() does not exist" )
		'Return Null
	End Method
	
	' Null Token handler
	'Method token_( token:TToken )
	'	ThrowException( "No method implemented for token '"+token.class+"'", token.line, token.pos )
	'End Method

End Type