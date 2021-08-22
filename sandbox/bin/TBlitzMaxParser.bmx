
'	BlitzMax Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version
'	V1.1	16 AUG 21	Removed BNF generic parsing due to limitations
'	V1.2	21 AUG 21	Re-organised program parsing, added parseHeader() ParseBlock()

Rem
PROGRAM
	COMMENT
	COMMENT
	STRICTMODE=Strict
	FRAMEWORK=brl.retro
	MODULE=its.btree
		MODULEINFO
		MODULEINFO
		MODULEINFO
	IMPORTS
		IMPORT brl.linkedlist
		IMPORT brl.retro
	INCLUDE=abc.bmx
	
End Rem


Global SYM_HEADER:Int[] = [ TK_STRICT, TK_SUPERSTRICT, TK_FRAMEWORK, TK_MODULE, TK_IMPORT, TK_MODULEINFO ]

Global SYM_PROGRAMBODY:Int[] = [ TK_INCLUDE, TK_LOCAL, TK_GLOBAL, TK_FUNCTION, TK_TYPE ]
Global SYM_METHODBODY:Int[] = [ TK_INCLUDE, TK_LOCAL, TK_GLOBAL ]
Global SYM_TYPEBODY:Int[] = [ TK_INCLUDE, TK_FIELD, TK_GLOBAL, TK_METHOD, TK_FUNCTION ]
Global SYM_MODULEBODY:Int[] = [ TK_INCLUDE, TK_MODULEINFO, TK_LOCAL, TK_GLOBAL, TK_FUNCTION, TK_TYPE ]

Type TBlitzMaxParser Extends TParser
	
	Field strictmode:Int = 0
	Field symbolTable:TSymbolTable = New TSymbolTable()	
	'
	'Field prev:TToken, save:TToken	' Used for lookback (Specifically for END XXX statements)
	'Field definition:TToken			' Used to identify a block definition comment
	
	Method New( lexer:TLexer )
		Super.New(lexer )
	End Method

	' We do not need to over-ride the parser entry point
	' because it will call parse_program to begin
	
	Private

	' Every story starts, as they say, with a beginning...
	Method parse_program:TASTNode()
		
		' Scan the tokens, creating children
		lexer.reset()	' Starting position
		Local token:TToken = lexer.getnext()
		
		' FIRST WE DEAL WITH THE PROGRAM HEADER
		Local ast:TASTCompound = parseHeader( token )
		'ast.name = "PROGRAM"
		
		' NEXT WE DEAL WITH PROGRAM BODY
		Local allow:Int[] = SYM_PROGRAMBODY
		Local body:TASTCompound = parseBlock( token, allow, error_to_eol )
		
		' INSERT BODY INTO PROGRAM
		For Local child:TASTNode = EachIn body.children
			ast.add( child )
		Next
	
		If token.id <> TK_EOF
			ThrowParseError( "Unexpected characters past end of program", token.line, token.pos )
		End If
		
		Return ast
	End Method

Rem
	' Parses Comments and EOL
	Method parseCEOL:Int( ast:TASTCompound, token:TToken Var )
		Select token.id
		Case TK_EOL
'DebugStop
			' Empty lines mark the end of a block comment and not a defintion
			'If prev And prev.id=TK_EOL And definition
			'	ast.add( New TAST_Comment( definition ) )
			'	definition = Null
			'End If
			token = lexer.getnext()
			Return True
		Case TK_COMMENT
'DebugStop
			' No definition for this identifier
			'If definition
			'	ast.add( New TAST_Comment( definition ) )
			'	definition = Null					
			'End If
			ast.add( New TASTNode( "COMMENT", token ) )
			token = lexer.expect(TK_EOL)
			token = lexer.getNext()			' Skip EOL
			Return True
		End Select
		' Not a Comment or EOL
		Return False
	End Method


EndRem
	
	' Parses a block
	Method parseBlock:TASTCompound( token:TToken Var, allowed:Int[], syntaxfn( lexer:TLexer, start:Int,finish:Int) )	
		Local ast:TASTCompound = New TASTCompound( "BLOCK" )

		allowed = [TK_EOL,TK_EOL,TK_COMMENT,TK_REM]+allowed

		Repeat
			Try
				If Not token Throw( "Unexpected end of token stream (STRICTMODE)" )
				If token.id = TK_EOF Return ast
				If token.notin( allowed ) ThrowParseError( "'"+token.value+"' is unexpected", token.line, token.pos )
'DebugStop								
				' Parse this token
				Select token.id
				Case TK_EOL
					ast.add( New TASTNode( "EOL" ) )
					token = lexer.getNext()
				Case TK_COMMENT
					ast.add( Parse_Comment( token ) )
				Case TK_REM
					ast.add( Parse_Rem( token ) )
'				
'
				Case TK_FUNCTION
					ast.add( Parse_Function( token ) )
				Case TK_INCLUDE
					ast.add( Parse_Include( token ) )			
				Case TK_METHOD
					ast.add( Parse_Method( token ) )
				Case TK_TYPE
					ast.add( Parse_Type( token ) )

				Default
Local debug:String = token.class
DebugStop			
					'Reflection doesn;t seem to work with "pass by reference"
					'reflect( token.class, Byte Ptr token )
DebugStop
					'ThrowParseError( "'"+token.value+"' is unknown at this time", token.line, token.pos )
				End Select
		
			Catch e:Object
DebugStop						
				Local parseerror:TParseError = TParseError(e)
				Local exception:TException = TException( e )
				Local runtime:TRuntimeException = TRuntimeException( e )
				Local text:String = String( e )
				Local typ:TTypeId = TTypeId.ForObject( e )
			'DebugStop
				If parseerror
					publish( "syntax-error", parseerror.text + " at "+parseerror.line + ","+ parseerror.pos )
					token = lexer.fastFwd( TK_EOL )	' Skip to end of line
				End If
				If exception Print "## Exception: "+exception.toString()+" ##"
				If runtime Print "## Runtime: "+runtime.toString()+" ##"
				If text Print "## Exception: '"+text+"' ##"
				Print "TYPE: "+typ.name
			EndTry
		Forever

		Return ast
	End Method
		
	' Parses the application header
	Method parseHeader:TASTCompound( token:TToken Var )	
		Const FSM_STRICTMODE:Int = 0
		Const FSM_FRAMEWORK:Int = 1
		Const FSM_MODULE:Int = 2
		Const FSM_MODULEINFO:Int = 3
		Const FSM_IMPORT:Int = 4
		
		Local ast:TASTCompound = New TASTCompound( "PROGRAM" )
		Local ast_module:TASTCompound, ast_imports:TASTCompound
		Local fsm:Int = FSM_STRICTMODE
'DebugStop	
		Repeat		
			Try
				If Not token Throw( "Unexpected end of token stream (STRICTMODE)" )
				
				' Parse Comments and EOL
				'If parseCEOL( ast, token ) Continue
				'If parseREM( ast, token ) Continue
				'If token.id = TK_EOF Return ast		' Source finished

'DebugStop				
				' Parse this token
				Select token.id			
				Case TK_EOF
					Return ast
				Case TK_EOL
					ast.add( New TASTNode( "EOL" ) )
					token = lexer.getNext()
				Case TK_COMMENT
					ast.add( Parse_Comment( token ) )
				Case TK_REM
					ast.add( Parse_Rem( token ) )			
				Case TK_STRICT, TK_SUPERSTRICT
					If fsm > FSM_STRICTMODE
						Publish( "syntax-error", "'"+token.value+"' was unexpected at this time", token )
						Continue
					End If
					fsm = FSM_FRAMEWORK
					'
					ast.add( Parse_Strictmode( token ) )
				Case TK_FRAMEWORK
					If fsm > FSM_FRAMEWORK
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time", token )
						Continue
					End If
					fsm = FSM_IMPORT
					'
					ast.add( Parse_Framework( token ) )
				Case TK_MODULE
					If fsm > FSM_FRAMEWORK
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time", token )
						Continue
					End If
					fsm = FSM_MODULE
					'
					ast_module = Parse_Module( token )
					ast.add( ast_module )
				Case TK_MODULEINFO
					If fsm <> FSM_MODULE
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time", token )
						Continue
					End If
					'
					ast_module.add( Parse_Moduleinfo( token ) )
				Case TK_IMPORT
'DebugStop
					If fsm > FSM_IMPORT
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time", token )
						Continue
					End If

					' Create an imports section if none exists
					If Not ast_imports
						ast_imports = New TASTCompound( "IMPORTS" )
						ast.add( ast_imports )
					End If
					
					' Add import 
					ast_imports.add( Parse_Import( token ) )
				Case TK_INCLUDE
					ast.add( Parse_Include( token ) )
				Default
					' If we encounter anything else; the header is complete
'DebugStop			
					Return ast
				End Select
		
			Catch e:TParseError
DebugStop
				If e 
					token = lexer.fastFwd( TK_EOL )	' Skip to end of line
				End If

			EndTry
		Forever

		Return ast
	End Method
	
	'	Looks for trailing comments
	'	These will become descriptions in the ast node
	Method ParseDescription:String( token:TToken Var )
		Local description:String
		' Trailing comment is a description
		token = lexer.expect( [TK_COMMENT,TK_EOL] )
		If token.id = TK_COMMENT
			' Inline comment becomes the node description
			description = token.value
			token = lexer.Expect( TK_EOL )
		End If
		Return description
	End Method	

	Method Parse_Comment:TASTNode( token:TToken Var )
		Local ast:TASTNode = New TASTNode( "COMMENT", token )
		token = lexer.expect(TK_EOL)
		token = lexer.getNext()			' Skip EOL
		Return ast
	End Method
	
	'	framework = framework ALPHA PERIOD ALPHA [COMMENT] EOL
	Method Parse_Framework:TASTNode( token:TToken Var )
		Local ast:TASTNode = New TASTNode( "FRAMEWORK", token )
		'
		' Get module name
		token = lexer.expect( TK_ALPHA )
		ast.value = token.value
		token = lexer.expect( TK_PERIOD )
		token = lexer.expect( TK_ALPHA )
		ast.value :+ "."+token.value
'DebugStop		'
		' Trailing comment is a description
		'token = lexer.expect( [TK_COMMENT,TK_EOL] )
		'If token.id = TK_COMMENT
		'	' Inline comment becomes the node description
		'	ast.descr = token.value
		'	token = lexer.Expect( TK_EOL )
		'End If
		ast.descr = ParseDescription( token )
		token = lexer.getNext()
		Return ast
	End Method

	'	function = function [ ":" <vartype> ] "(" [<args>] ")" [COMMENT] EOL
	Method Parse_Function:TASTNode( token:TToken Var )
		Local ast:TAST_Function = New TAST_Function( token )
		
'DebugStop
		' Get function name
		token = lexer.expect( TK_ALPHA )
		ast.value = token.value
		
		' Get function Type
		Local peek:TToken = lexer.peek()
		If peek.id = TK_COLON
			token = lexer.getnext()	' Skip the colon
			token = lexer.getNext() ' Get the return type
			ast.returntype = token
		End If

		' For the sake of simplicity at the moment, this will not parse the body
		' ast.add( ParseBlock( [ TK_LOCAL, TK_GLOBAL, TK_REPEAT, etc] )
		
		Local finished:Int = False
		Repeat
			token = lexer.getNext()
			If token.id = TK_END
				token = lexer.getNext()
				If token.id = TK_FUNCTION ; finished = True
			End If
		Until token.id = TK_ENDFUNCTION Or finished
		'
		' Trailing comment is a description
		ast.descr = ParseDescription( token )
		token = lexer.getNext()
		Return ast
	End Method
	
	'	Create an AST Node for Import containing all imported modules as children
	'	import = import ALPHA PERIOD ALPHA [COMMENT] EOL
	Method Parse_Import:TASTNode( token:TToken Var )
		Local ast:TASTNode = New TASTNode( "IMPORT", token )
'DebugStop
		'
		' Get module name
		token = lexer.expect( TK_ALPHA )
		ast.value = token.value
		token = lexer.expect( TK_PERIOD )
		token = lexer.expect( TK_ALPHA )
		ast.value :+ "."+token.value
		'
		' Trailing comment is a description
		ast.descr = ParseDescription( token )
		token = lexer.getNext()
		Return ast		
	End Method

	'	Create an AST Node for Import containing all imported modules as children
	'	import = import ALPHA PERIOD ALPHA [COMMENT] EOL
	Method Parse_Include:TASTNode( token:TToken Var )
		Local ast:TASTNode = New TASTNode( "INCLUDE", token )
		'
		' Get module name
		token = lexer.expect( TK_QSTRING )
		ast.value = token.value
		'
		' Trailing comment is a description
		ast.descr = ParseDescription( token )
		token = lexer.getNext()
		Return ast		
	End Method

	'	method = method [ ":" <vartype> ] "(" [<args>] ")" [COMMENT] EOL
	Method Parse_Method:TASTNode( token:TToken Var )
DebugStop
Throw( "PARSE_METHOD IS NOT IMPLEMENTED" )
	End Method
		
	Method Parse_Module:TASTCompound( token:TToken Var )
		Local ast:TASTCompound = New TASTCompound( "MODULE" )
		'
		' Get module name
		token = lexer.expect( TK_ALPHA )
		ast.value = token.value
		token = lexer.expect( TK_PERIOD )
		token = lexer.expect( TK_ALPHA )
		ast.value :+ "."+token.value
		'
		' Trailing comment is a description
		ast.descr :+ ParseDescription( token )
		token = lexer.getNext()		
		Return ast
	End Method

	Method Parse_ModuleInfo:TASTNode( token:TToken Var )
		' Get moduleinfo
		token = lexer.expect( TK_QSTRING )
		Local ast:TASTNode = New TASTNode( "MODULEINFO", token )
'DebugStop		'
		' Trailing comment is a description
		ast.descr = ParseDescription( token )
		token = lexer.getNext()
		Return ast
	End Method
	
	' Parses REM
	Method Parse_Rem:TASTNode( token:TToken Var )
		Local ast:TASTNode = New TASTNode( "REMARK", token )
'DebugStop
		' Now look for ENDREM or END REM
		token = lexer.expect( [TK_ENDREM, TK_END] )
		If token.id = TK_END lexer.expect( TK_REM )
		
		' Next we look for a weird trailing comment
		' If it exists, we treat it as a newline
		Local peek:TToken = lexer.peek()
		If peek.id = TK_COMMENT 
			token = lexer.getNext()
			Return ast
		End If
		
		token = lexer.expect( TK_EOL )
		token = lexer.getNext()
		Return ast
	End Method

	'	strictmode = (strict|superstrict) [COMMENT] EOL
	Method Parse_Strictmode:TASTNode( token:TToken Var )
		Local ast:TASTNode = New TASTNode( "STRICTMODE", token )
		'
		' Trailing comment is a description
		ast.descr = ParseDescription( token )
		token = lexer.getNext()
		Return ast
	End Method

	'	type = type ALPHA [ extends ALPHA ] [COMMENT] EOL
	Method Parse_Type:TASTNode( token:TToken Var )
		Local ast:TAST_Type = New TAST_Type( token )
'DebugStop
		' Get name
		token = lexer.expect( TK_ALPHA )
		ast.value = token.value
		
		' Get extend Type
		Local peek:TToken = lexer.peek()
		If peek.id = TK_EXTENDS
			token = lexer.getnext()	' Skip "EXTENDS"
			token = lexer.getNext() ' Get the super type
			ast.supertype = token
		End If

		' For the sake of simplicity at the moment, this will not parse the body
		' ast.add( ParseBlock( [ TK_LOCAL, TK_GLOBAL, TK_REPEAT, etc] )
		
		Local finished:Int = False
		Repeat
			token = lexer.getNext()
			If token.id = TK_END
				token = lexer.getNext()
				If token.id = TK_TYPE ; finished = True
			End If
		Until token.id = TK_ENDTYPE Or finished
		'
		' Trailing comment is a description
		ast.descr = ParseDescription( token )
		token = lexer.getNext()
		Return ast
	End Method

	' Obtain closing token(s) for a given token if
Rem
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
End Rem

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

	'	ERROR RECOVERY FUNCTIONS
	
	Function error_to_eol( lexer:TLexer, ignore1:Int, ignore2:Int )
DebugStop
	End Function

	Function error_until_end( lexer:TLexer, starttag:Int, endtag:Int )
DebugStop
	End Function
	
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
