
'	BlitzMax Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version
'	V1.1	16 AUG 21	Removed BNF generic parsing due to limitations

Global SYM_HEADER:Int[] = [ TK_STRICT, TK_SUPERSTRICT, TK_FRAMEWORK, TK_IMPORT, TK_MODULE, TK_MODULEINFO ]
Global SYM_FUNCTIONBODY:Int[] = [ TK_LOCAL, TK_GLOBAL ]
Global SYM_METHODBODY:Int[] = [ TK_LOCAL, TK_GLOBAL ]
Global SYM_TYPEBODY:Int[] = [ TK_FIELD, TK_GLOBAL, TK_METHOD, TK_FUNCTION ]


Type TBlitzMaxParser Extends TParser

	Field strictmode:Int = 0
	Field symbolTable:TSymbolTable = New TSymbolTable()	
	
	Method New( lexer:TLexer )
		Super.New(lexer )
	End Method

	' We do not need to over-ride the parser entry point
	' because it will call parse_program to begin
	
	Private

	' Every story starts, as they say, with a beginning...
	Method parse_program:TASTNode()
		
		Const FSM_STRICTMODE:Int = 0
		Const FSM_FRAMEWORK:Int = 1
		Const FSM_IMPORT:Int = 2
		Const FSM_MODULE:Int = 3
		Const FSM_BODY:Int = 4
		
		' 	ABNF
		'		Program = [Strictmode] | [ Application | Module ]
		'		Application = [Strictmode] [Framework] [*Import] [*Include] Block
		'		Module = [Strictmode] ModuleDef [*Import] [*Include] Block
		'
'DebugStop
		Local fsm:Int = FSM_STRICTMODE

		' Build a block structure
		Local ast:TASTCompound = New TASTCompound( "PROGRAM" )
		
		' Scan the tokens, creating children
		lexer.reset()	' Starting position
		
		Local token:TToken = lexer.getnext()
		Local prev:TToken, save:TToken
		Local definition:TToken
		
		' [STRICTMODE]
		Repeat
		
			Try
'DebugStop
				If Not token Throw( "Unexpected end of token stream (STRICTMODE)" )

				' Save previous token
				prev = save
				save = token
				
				' Parse this token
				Select token.id
				Case TK_EOF
					Exit
				Case TK_EOL
					' Empty lines mark the end of a block comment and not a defintion
					If prev And prev.id=TK_EOL And definition
						ast.add( New TAST_Comment( definition ) )
						definition = Null
					End If
					token = lexer.getnext()
					Continue
				Case TK_COMMENT
					' No definition for this identifier
					If definition
						ast.add( New TAST_Comment( definition ) )
						definition = Null					
					End If
					ast.add( New TAST_Comment( token ) )
					' Next should (MUST) be an EOL
					token = lexer.getnext()	' Skip "COMMENT"
					token = lexer.getnext()	' SKip "EOL"
					Continue
				Case TK_REM
					' Previous comments are blocks, not definitions
					If definition ast.add( New TAST_Comment( definition ) )
					definition = token
'DebugStop
					' Now look for ENDREM or END REM
					token = lexer.expect( [TK_ENDREM, TK_END] )
					If token.id = TK_END lexer.expect( TK_REM )
					
					' Next we look for a weird trailing comment and EOL
					token = lexer.expect( [TK_COMMENT, TK_EOL] )
					If token.id = TK_EOL Continue
					' After ENDREM is a weird place to put a comment; just ignore the stupid thing!
					' The next thing must be an EOL
					token = lexer.expect( TK_EOL )
					Continue
				Case TK_STRICT, TK_SUPERSTRICT
					If fsm<>FSM_STRICTMODE
						Publish( "syntax-error", "'"+token.value+"' was unexpected at this time", token )
						Continue
					End If
'DebugStop
					ast.add( New TAST_Strictmode( lexer, token, definition ) )
					definition=Null
					fsm :+ 1
					token = lexer.peek()
					Continue
				Default
DebugStop			
					ThrowParseError( "'"+token.value+"' is unknown at this time", token.line, token.pos )
				End Select
		
			Catch e:TParseError
DebugStop
				If e 
					token = lexer.fastFwd( TK_EOL )	' Skip to end of line
				End If

			EndTry
		Forever
		
	Rem	
		'	OPTIONAL STRICTMODE
		'	StrictMode = "superstrict" / "strict" EOL
		If lexer.peek( ["superstrict","strict"] )
			token_strictmode( lexer.getnext() )
		End If
		
		'	OPTIONAL FRAMEWORK
		'	Framework = "framework" ModuleIdentifier EOL
		If lexer.peek( ["framework"] )
			Print "FRAMEWORK"
			token_framework( lexer.getnext() )
		End If
		
		'	OPTIONAL IMPORTS
		'	OPTIONAL INCLUDES
		'	OPTIONAL EXTERN
		
		'	APPLICATION CODE BODY
		Parse_Body( ["local","global","function","type","print"] )

		If lexer.isAtEnd() Return Null 'Completed successfully
		
		' Tokens exist past end of file!
		Local tok:TToken = lexer.peek()
		ThrowException( "Unexpected Symbol", tok.line, tok.pos )
End Rem
		Return ast
	End Method

	' Obtain closing token(s) for a given token if
	Method closingTokens:Int[]( tokenid:Int )
		Select tokenid
		Case TK_EXTERN		;	Return [ TK_END, TK_ENDEXTERN ]
		Case TK_FUNCTION	;	Return [ TK_END, TK_ENDFUNCTION ]
		Case TK_IF			;	Return [ TK_END, TK_ENDIF ]
		Case TK_INTERFACE	;	Return [ TK_END, TK_ENDINTERFACE ]
		Case TK_METHOD		;	Return [ TK_END, TK_ENDMETHOD ]
		Case TK_REM			;	Return [ TK_END, TK_ENDREM ]
		Case TK_REPEAT		;	Return [ TK_FOREVER, TK_UNTIL ]
		Case TK_SELECT		;	Return [ TK_END, TK_ENDSELECT ]
		Case TK_STRUCT		;	Return [ TK_END, TK_ENDSTRUCT ]
		Case TK_TRY			;	Return [ TK_END, TK_ENDTRY ]
		Case TK_TYPE		;	Return [ TK_END, TK_ENDTYPE ]
		Case TK_WHILE		;	Return [ TK_END, TK_ENDWHILE, TK_WEND]
		End Select
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
	
	' Recover from syntax errors
	' Called by parse method during try-catch for TParseError()
	Method error_recovery()
		Rem
		local peek:TToken
		repeat
			peek = lexer.peek()
			select peek.id
			case TK_End
				' End marks the end of a block and we dont want the
				' following token to be mis-interpreted as the start of a new block 
				' so we have to drop it
				lexer.getnext()
				lexer.getnext()
				continue
			case TK_Function, TK_Method, TK_Type, TK_Struct, TK_For, TK_Local, TK_Field, TK_If
				return
			default
				' Consume the token as we are uncertain following an error
				lexer.getnext()
			end select
		until peek.id=TK_EOF
		End Rem
	End Method
	
	'	DYNAMIC METHODS
	'	CALLED BY REFLECTOR

Rem 	
	Method rule_program:TASTNode( syntax:TASTNode[] )
'DebugStop
		Local tree:TASTCompound = New TASTCompound( "PROGRAM" )
		For Local ast:TASTNode = EachIn syntax
			If ast.token.id <> TK_EOL ; tree.add( ast )
		Next
		Return tree
	End Method

	Method rule_ceol:TASTNode( syntax:TASTNode[] )
		' EOL is ignored, but comments are added to the tree
		'	Create an AST for this statement
'DebugStop
		Select syntax.length
		Case 1	' 	c-eol = EOL
			'syntax[0].name = "EOL"
			Return syntax[0]
		Case 2	'	c-eol = COMMENT EOL
			' We will recycle the comment
			syntax[0].name = "linecomment"
			syntax[0].descr = syntax[0].token.value
			'Return New TASTNode( "comment", syntax[0] )
			Return syntax[0]
		Default
			Throw "rule_ceol(), FAILED, Invalid arguments"
		End Select
	End Method

	Method rule_strictmode:TASTNode( syntax:TASTNode[] )		
		Print "RULE STRICTMODE"
'DebugStop
		'	Set Parser state to selected strict mode
		strictmode = syntax[0].token.id

		'	Create an AST for this statement
		Select syntax.length
		Case 1	' 	strictmode = MODE EOL
			syntax[0].name = "strictmode"
			'Return New TASTNode( "strictmode", syntax[0] )
			Return syntax[0]
		Case 2	' 	strictmode = MODE COMMENT EOL
'DebugStop
			syntax[0].name = "strictmode"
			syntax[0].descr = syntax[1].token.value
			'Return New TASTNode( "strictmode", syntax[0], syntax[1].value )
			Return syntax[0]
		Default
			Throw "rule_strictmode(), FAILED, Invalid arguments"
		End Select

	End Method
End Rem
	
Rem
	' Field = "field" VarDecl *[ "," VarDecl ]
	Method token_field( token:TToken )
		Parse_VarDeclarations( "field", token )
	End Method
	
	' Framework = "framework" ModuleIdentifier EOL
	' ModuleIdentifier = Name DOT Name
	' Name = ALPHA *(ALPHA / DIGIT / UNDERSCORE )
	Method token_framework( token:TToken )
		Local moduleIdentifier:String = Parse_ModuleIdentifier()
		' Add to symbol table
		symbolTable.add( token, "global", moduleIdentifier ) 
	End Method

	' Global = "global" VarDecl *[ "," VarDecl ]
	Method token_global( token:TToken )
		Parse_VarDeclarations( "global", token )
	End Method

	' Local = "local" VarDecl *[ "," VarDecl ]
	Method token_local( token:TToken )
'DebugStop
		Parse_VarDeclarations( "local", token )
'Print "LOCAL DONE"
	End Method
	
	' StrictMode = "superstrict" / "strict" EOL
	Method token_strictmode( token:TToken )
		Select token.class
		Case "strict"		;	strictmode = 1
		Case "superstrict"	;	strictmode = 2
		End Select
		'lexer.expect( "EOL" )
	End Method
	
	'	STATIC METHODS
	'	CALLED DIRECTLY
	
	' ApplicationBody = Local / Global / Function / Struct / Type / BlockBody
	Method Parse_Body:String( expected:String[] )
		Local token:TToken
		Local found:TToken
		Repeat
			token = lexer.peek()
'DebugStop
			If token.class="EOF" 
				lexer.getNext()
				Exit
			End If
			If token.class="EOL" Or token.class="comment"
				lexer.getNext()
				Continue
			End If
			found = Null
			For Local expect:String = EachIn expected
				If expect=token.class 
					found = token
					Exit
				End If
			Next
			'
			If found  ' Expected token
				reflect( lexer.getNext() )
				' 
'				Local token:TToken = lexer.getNext()
'				Select token.class
'				Case "field"		;	Parse_VarDeclarations( "field", token )
'				Case "global"		;	Parse_VarDeclarations( "global", token )
'				Case "local"		;	Parse_VarDeclarations( "local", token )
'				Default
'					ThrowException( "Unhandled token '"+token.value+"'", token.line, token.pos )
'				End Select
			Else
				' Unexpected token...
				ThrowException( "Unexpected token '"+token.value+"'", token.line, token.pos )
			End If
		Forever
	End Method

	' ModuleIdentifier = Name DOT Name
	Method Parse_ModuleIdentifier:String()
		Local collection:TToken = lexer.Expect( "alpha" )
		lexer.Expect( "symbol", "." )
		Local name:TToken = lexer.Expect( "alpha" )
		Return collection.value + "." + name.value
	End Method
	
	' VarDeclarations = VarDecl *[ "," VarDecl ]
	Method Parse_VarDeclarations( scope:String, token:TToken )
		Local tok:TToken
'DebugStop
		Repeat
			Parse_VarDecl( token, scope )
			tok = lexer.peek()
		Until tok.class = "EOF" Or tok.class<>"comma"		
	End Method

	' VarDecl = Name ":" VarType [ "=" Expression ]
	Method Parse_VarDecl( definition:TToken, scope:String )
'DebugStop
		' Parse Variable defintion
		Local name:TToken = lexer.Expect( "alpha" )
		lexer.expect( "colon" )
		Local varType:String = Parse_VarType()
		' Parse optional declaration
		If lexer.peek( "equals" )
			Local sym:TToken
			' Throw away the expression. NOT IMPLEMENTED YET
			Repeat
				sym = lexer.getNext()
				'Print sym.class
			Until sym.in( [TK_EOF,TK_EOL,TK_comma,TK_Comment] )
		End If
		' Create Defintion Table
		symbolTable.add( definition, scope, name.value, vartype )
	End Method

	' VarType = "byte" / "int" / "string" / "double" / "float" / "size_t"
	Method Parse_VarType:String()
		Local sym:TToken = lexer.getNext()
		Return sym.value
	End Method
End Rem

	
End Type

'Type AST_strictmode Extends TAbSynTree
'	Field comment:String
'	Field strictmode:Int
'	Method New( strictmode:TToken, comment:TToken )
'		Self.strictmode = strictmode.id
'		If comment Self.comment = comment.value
'	End Method
'End Type

Type TCodeBlock
	Field start:TToken
	Field finish:TToken
	Method New( start:TToken, finish:TToken )
		Self.start = start
		Self.finish = finish
	End Method
End Type
