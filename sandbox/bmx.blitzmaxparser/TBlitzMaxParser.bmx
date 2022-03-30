
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
	
EXPRESSION SYNTAX:

	EXPRESSION	:= EQUALITY
	EQUALITY	:= COMPARISON ( ( "!=" | "==" ) COMPARISON )*
	COMPARISON	:= TERM ( ( ">" | ">=" | "<" | "<=" ) TERM )*
	TERM		:= FACTOR ( ( "-" | "+" ) FACTOR )*
	FACTOR		:= UNARY ( ( "/" | "*" ) UNARY )*
	UNARY		:= ( "NOT" | "-" ) UNARY | PRIMARY
	PRIMARY		:= NUMBER | STRING | BOOLEAN | "nul" | "(" EXPRESSION ")"
	BOOLEAN		:= "True" | "False"
	
End Rem

Rem THINGS TO DO
* Move sequence caller into a reflection caller instead of large select-case
* Parse_Local(), Parse_Global() and ParseField() are all similar, combine them
End Rem

Global SYM_HEADER:Int[] = [ TK_STRICT, TK_SUPERSTRICT, TK_FRAMEWORK, TK_MODULE, TK_IMPORT, TK_MODULEINFO ]

Global SYM_BLOCK_KEYWORDS:Int[] = [ TK_CONST, TK_FOR, TK_REPEAT, TK_WHILE, TK_IF ]

Global SYM_PROGRAM_BODY:Int[] = [ TK_CONST, TK_INCLUDE, TK_ENUM, TK_LOCAL, TK_GLOBAL, TK_FUNCTION, TK_TYPE, TK_INTERFACE, TK_STRUCT ]+SYM_BLOCK_KEYWORDS
Global SYM_MODULE_BODY:Int[] = [ TK_CONST, TK_INCLUDE, TK_MODULEINFO, TK_LOCAL, TK_GLOBAL, TK_FUNCTION, TK_TYPE ]

Global SYM_TYPE_BODY:Int[] = [ TK_FIELD, TK_CONST, TK_INCLUDE, TK_GLOBAL, TK_METHOD, TK_FUNCTION ]

Global SYM_FUNCTION_BODY:Int[] = [ TK_LOCAL, TK_CONST, TK_INCLUDE, TK_GLOBAL, TK_ALPHA, TK_FUNCTION, TK_RETURN ]+SYM_BLOCK_KEYWORDS
Global SYM_METHOD_BODY:Int[] = [ TK_LOCAL, TK_CONST, TK_INCLUDE, TK_GLOBAL, TK_ALPHA, TK_FUNCTION, TK_RETURN ]+SYM_BLOCK_KEYWORDS

Global SYM_ENUM_BODY:Int[] = [ TK_INCLUDE ]
Global SYM_INTERFACE_BODY:Int[] = [ TK_FIELD, TK_GLOBAL, TK_INCLUDE, TK_METHOD ]
Global SYM_STRUCT_BODY:Int[] = [ TK_FIELD, TK_GLOBAL, TK_INCLUDE ]

Global SYM_FOR_BODY:Int[] = [ TK_INCLUDE ]+SYM_BLOCK_KEYWORDS
Global SYM_REPEAT_BODY:Int[] = [ TK_INCLUDE ]+SYM_BLOCK_KEYWORDS
Global SYM_WHILE_BODY:Int[] = [ TK_INCLUDE ]+SYM_BLOCK_KEYWORDS
Global SYM_IF_BODY:Int[] = [ TK_INCLUDE ]+SYM_BLOCK_KEYWORDS

Global SYM_DATATYPES:Int[] = [ TK_BYTE, TK_DOUBLE, TK_FLOAT, TK_INT, TK_LONG, TK_SHORT, TK_STRING ]

Type TBlitzMaxParser Extends TParser
	
	Field strictmode:Int = 0
	'Field symbolTable:TSymbolTable = New TSymbolTable()	
	'
	'Field prev:TToken, save:TToken	' Used for lookback (Specifically for END XXX statements)
	'Field definition:TToken			' Used to identify a block definition comment
		
	Method New( lexer:TLexer )
		Super.New(lexer )
	End Method		

	' We do not need to over-ride the parser entry point
	' because it will call parse_program to begin

	' Every story starts, as they say, with a beginning...
	Method parse_program:TASTNode()
		Local fsm:Int = 0
'DebugStop	
		' Scan the tokens, creating children
		token = lexer.reset()	' Starting position
		'advance()
		'Local token:TToken = lexer.getToken()
		'token2 = token
		
		' FIRST WE DEAL WITH THE PROGRAM HEADER
		'Local ast:TASTCompound = New TASTCompound( "PROGRAM" )
		'ast = parseHeader( ast, token )

'DebugStop		
		'Local ast:TASTCompound = New TASTCompound( "PROGRAM" )
		'ast = parseHeader( ast )
		
		' Program block contains HEADER, PROGRAMBODY and APLNUMERIC TOKENS (Function names etc)
		ast = parseSequence( "PROGRAM", SYM_HEADER+SYM_PROGRAM_BODY+[TK_ALPHA] )	
		' Mop up trailing Comments and EOL
		'ParseCEOL( ast )
		
		' Capture Comments and EOL
		'If parseCEOL( ast ) Return ast
		'ast.add( Parse_Strictmode() )	' STRICTMODE
		
		' Capture Comments and EOL
		'If parseCEOL( ast ) Return ast
		'Local exists:TASTNode = Parse_FrameworkTEST()
		'If Not exists
		'	exists = Parse_ModuleTEST()
		'End If
		'ast.add( Parse_ImportTEST() )		' IMPORT

'		Return ast
		
		' NEXT WE DEAL WITH PROGRAM BODY
		'Local allow:Int[] = SYM_PROGRAMBODY
		'ast = parseBlock( 0, ast, token, allow, error_to_eol )
		
		' INSERT BODY INTO PROGRAM
		'For Local child:TASTNode = EachIn body.children
		'	ast.add( child )
		'Next
	
		'If token.id <> TK_EOF
		'	ThrowParseError( "Unexpected characters past end of program", token.line, token.pos )
		'End If
		
		' Validate the parsed AST
		ast.validate()
		
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
	
	' Parses a block into an EXISTING ast compound node
	'	BlockType	- The type of block we are parsing (Used to tally-up END <BLOCKTYPE>)
	'	ast			- The AST Node we are building
	'	Token		- The Current Token
	'	Allowed		- List of allowed tokens...
Rem	Method parseBlock:TASTCompound( BlockType:Int, ast:TASTCompound, token:TToken Var, allowed:Int[], syntaxfn( lexer:TLexer, start:Int,finish:Int) )	
		
		' Identify token that would close this block type
		Local blockClose:Int = ClosingToken( BlockType )

		' Extend allowed list for generic tokens
		allowed :+ [ TK_EOL, TK_REM, TK_COMMENT, TK_END, BlockClose ]

		Repeat
			Try
				If Not token Throw( "Unexpected end of token stream (STRICTMODE)" )
				If token.id = TK_EOF Return ast
				If token.notin( allowed ) ThrowParseError( "'"+token.value+"' is unexpected", token.line, token.pos )
'DebugStop								
				' Parse this token
				Select token.id
				'Case TK_EOL
				'	ast.add( New TASTNode( "EOL" ) )
				'	token = lexer.getNext()
				'Case TK_COMMENT
				'	ast.add( Parse_Comment( token ) )
				'Case TK_REM
				'	ast.add( Parse_Rem( token ) )
'
				Case TK_END
'DebugStop
					' Identify if this is "END" or "END <BLOCK>"
					'Local peek:TToken = lexer.peek()
					'If peek.id = BlockType
					'	' THIS IS END OF THE BLOCK
					'	token = lexer.getnext() ' Consume END
					'	'token = lexer.getnext() ' Consume BlockType
					'	Return ast
					'Else
						' THIS IS AN END OF APPLICATION TOKEN
					ast.add( Parse_End() )
					'End If
				Case BlockClose
'DebugStop
					'token = lexer.getnext()
					Return ast
				Case TK_FUNCTION
					'ast.add( Parse_Function( token ) )
				Case TK_INCLUDE
					'ast.add( Parse_Include( token ) )			
				Case TK_METHOD
					'ast.add( Parse_Method( token ) )
				Case TK_TYPE
					'ast.add( Parse_Type( token ) )

				Default

					' If we encounter anything else; the block (SHOULD BE) complete
					Return ast
				End Select
		
			Catch e:Object
				Local parseerror:TParseError = TParseError(e)
				Local exception:TException = TException( e )
				Local runtime:TRuntimeException = TRuntimeException( e )
				Local text:String = String( e )
				Local typ:TTypeId = TTypeId.ForObject( e )
				'
				If parseerror
					publish( "syntax-error", parseerror.text + " at "+parseerror.line + ","+ parseerror.pos )
					token = lexer.fastFwd( TK_EOL )	' Skip to end of line
				End If
				If exception Print "## Exception: "+exception.toString()+" ##"
				If runtime Print "## Runtime: "+runtime.toString()+" ##"
				If text Print "## Exception: '"+text+"' ##"
				Print "TYPE: "+typ.name
DebugStop
			EndTry
		Forever

		'Return ast
	End Method
EndRem	
	
'	Method ParseContext:TASTNode( contains:Int[], optional:Int[], parent:TASTNode = Null )
	
		' Check identifier in "contains" or "optional"
		' if expected identifier, call its geenrator function 
		' if unexpected identifier, ask parent if they expect it?
		'	if parent doesn't know, generate UNEXPECTED symbol
		'		if error flag set
		'			Weve hit soemthign we cannot process.. 
		'			FAST FORWARD Until we find a token we DO understand
		'			Everythign else becomes "SKIPPED" tokens
		'		set error flag
		'	if parent does know
		'		Return back to parent for further processing
		
		
	
'	End Method

	' Passes arguments sent to a FUNCTION or METHOD
	Method parseArguments:TASTCompound()
'DebugStop
		Local ast:TASTCompound = New TASTCompound( "Arguments" )
		
		'THIS NEEDS To BE FIXED For SIGNATURE To WORK
		'ast.def = eatUntil( [TK_rparen,TK_EOL], token)
'DebugStop
		'Local token:TToken = lexer.token
		While token And Not token.in( [TK_rparen,TK_EOL] )
' function xyz( abc( something:int )
	
			Local varname:TToken = eat( TK_ALPHA )
			Local tok:TToken = eatOptional( [TK_Colon,TK_LParen] )	' ":" or "(" fuction variable
			Select tok.id
			Case TK_Colon
				Local vartype:TToken = eat( SYM_DATATYPES+[TK_ALPHA] )
				' Optional parenthesis for function variable
				Local paren:TToken = eatOptional( TK_LParen, Null )
				If paren
				'DebugStop
					' Function variable WITH return value
					Local func:TAST_Function = New TAST_Function()
					'advance()
					func.name = varname
					func.colon = tok
					func.returntype = vartype
					func.rparen = eatOptional( TK_RParen,Null )
					If Not func.rparen
						func.arguments = parseArguments()
						func.rparen = eat( TK_RParen )
					End If
					ast.add( func )					
				Else
					' Normal variable declaration
					Local vardef:TASTBinary = New TASTBinary( New TASTNode(varname), tok, New TASTNode(vartype) )
					vardef.classname = "ARGUMENT"
					ast.add( vardef )
				End If
			Case TK_LParen
				' Function variable without return value
				Local func:TAST_Function = New TAST_Function()
				'advance()
				func.name = varname
				'func.colon = eatOptional( TK_Colon, Null )
				'If func.colon ; func.returntype = eat( SYM_DATATYPES+[TK_ALPHA] )
				func.rparen = eatOptional( TK_RParen,Null )
				If Not func.rparen
					func.arguments = parseArguments()
					func.rparen = eat( TK_RParen )
				End If
				ast.add( func )
			Default
			
			End Select
			
			Local comma:TToken = eatOptional( TK_COMMA, Null )
		Wend
		Return ast
		
		Function parseFunctionArg:TASTNode()
			
		End Function
		
	End Method

	' Parse a sequence.
	' The tokens MUST exist in order or not be present (Creating a missing token)
	Method parseSequence:TASTCompound( classname:String, options:Int[], closing:Int[]=Null, parent:Int[]=Null )
		Local ast:TASTCompound = New TASTCompound( classname )
		Return parseSequence( ast, options, closing, parent )
	End Method
		
	' The tokens MUST exist in order Or Not be present (Creating a missing token)
	Method parseSequence:TASTCompound( ast:TASTCompound, options:Int[], closing:Int[]=Null, parent:Int[]=Null )

		'If closing = Null

		' TRY HEADER
		If closing = Null
'DebugStop
			ParseCEOL( ast )
			ast.add( Parse_Strictmode() )
			ParseCEOL( ast )
			ast.add( Parse_Framework() )
			If token.id = TK_Module
				ParseCEOL( ast )
				ast.classname = "MODULE"
				ast.add( Parse_Module() )
				Repeat
					ParseCEOL( ast )
					If token.id <> TK_ModuleInfo Exit
					ast.add( Parse_Moduleinfo() )
				Forever
			End If
			' Imports
			Repeat
				ParseCEOL( ast )
				If token.id <> TK_Import Exit
				ast.add( Parse_Import() )
			Forever
		End If
		
		' PARSE BODY
		Repeat	

			Try
				' Failsafe!
				If Not token Or token.id=TK_EOF ; Return ast
				
				' Process EOL/Comments and Return at EOF
				'If Not token Or parseCEOL( ast ) Return ast
'DebugStop				
				If closing And token.in(closing)
					' WE HAVE HIT A CLOSING TOKEN
					Return ast
				ElseIf token.in( [TK_EOL,TK_Comment,TK_Rem] )
					If parseCEOL( ast ) Return ast
				ElseIf token.in( options )
					' Parse this token
					Select token.id			
					Case TK_Alpha		' Expression
						Local skip:TToken = token
						advance()
						Local error:TASTCompound = eatUntil( [TK_EOL,TK_EOF], skip )
						error.consume( skip )
						error.classname = "TODO"
						error.errors :+ [ New TDiagnostic( "Expression is not implemented", DiagnosticSeverity.Information ) ]
						ast.add( error )				
					Case TK_Const
						ast.add( Parse_Const() )
					Case TK_Enum
						ast.add( Parse_Enum() )
					Case TK_Field
						ast.add( Parse_Field() )
					Case TK_For
'DebugStop
						ast.add( Parse_For() )
					Case TK_Function
						ast.add( Parse_Function() )
					Case TK_Global
						ast.add( Parse_Global() )
					Case TK_If
						ast.add( Parse_If() )
					Case TK_Import
						ast.add( Parse_Import() )
					Case TK_Include
						ast.add( Parse_Include() )
					Case TK_Interface
						ast.add( Parse_Interface() )
					Case TK_Local
						ast.add( Parse_Local() )
					Case TK_Method
						ast.add( Parse_Method() )
					Case TK_Repeat
						ast.add( Parse_Repeat() )
					Case TK_Return
						ast.add( Parse_Return() )
					Case TK_Struct
						ast.add( Parse_Struct() )
					Case TK_Type
						ast.add( Parse_Type() )
					Case TK_While
						ast.add( Parse_While() )
					Default
'DebugStop
						' ALL OPTIONS SHOULD BE ACCOUNTED FOR IN SELECT CASE
						' IF WE GET HERE, WE HAVE A BUG
						' SKIP UNTIL END OF LINE TO TRY TO RECOVER
						
						'Local skip:TAST_Skipped = New TAST_Skipped( token,  )
						'advance()
						'ast.add( skip )
						Local skip:TToken = token
						advance()
						Local error:TASTCompound = eatUntil( [TK_EOL,TK_EOF], skip )
						'Local error:TASTIgnored = TASTIgnored( eatUntil( [TK_EOL,TK_EOF], skip ))
						error.consume( skip )
						error.classname = "ERROR"
						'skip.value = token.value
						error.errors :+ [ New TDiagnostic( "'"+skip.value+"' was unexpected", DiagnosticSeverity.Error ) ]
						'error.status = AST_NODE_ERROR
						ast.add( error )
						
					End Select
				
				Else	' TOKEN IS NOT IN THE OPTION LIST!
'DebugStop
					' Ask parent if they know about it
					'If parent.knows( token ) Return ast
					' Mark token as ERROR and skip until we find a token we do understand.
					'ast.add( New TAST_Skipped( "ERROR", token, "unexpected token" ) )
					'ast.add( eatUntil( options+[closing] ) )
					
					'DebugStop
					If parent And token.in(parent) Return ast

					Local skip:TToken = token
					advance()
					Local error:TASTCompound = eatUntil( options+closing, skip )
					'Local error:TASTUnexpected = TASTUnexpected( eatUntil( options+closing, skip ) )
					error.consume( skip )
					error.classname = "SKIPPED"
					'skip.value = token.value
					error.errors :+ [ New TDiagnostic( "~q"+skip.value + "~q was unexpected!", DiagnosticSeverity.Warning ) ]
					ast.add( error )
				
				End If
		
			Catch e:TParseError
'DebugStop
				If e 
					ast.add( eatUntil( [TK_EOL,TK_EOF], token ) )
				End If

			EndTry
		Forever

		Return ast		
		
	
	
	End Method
		
	' Parses the application header into an EXISTING ast compound node
Rem
	Method parseHeaderTEST:TASTCompound( ast:TASTCompound )
		'Local ast:TASTCompound = New TASTCompound( "PROGRAM" )
		'Local ast_module:TASTCompound, ast_imports:TASTCompound
		
		' Parse out Whitespace, Comments, EOL and EOF
		If parseCEOL( ast ) Return ast
		' Parse Optional
Local debug:TToken = token
DebugStop
		ast.add( Parse_StrictmodeTEST() )
		
		Return ast
	End Method
End Rem

	' Parses Whitespace, Comments, EOL and EOF
	Method parseCEOL:Int( ast:TASTCompound )
'DebugStop
		Repeat
			Select token.id			
			Case TK_EOF
				Return True	
			Case TK_EOL
				ast.add( New TAST_EOL( token ) )
				advance()
			Case TK_COMMENT
				ast.add( New TAST_Comment( token ) )
				advance()
				'Local temp:TToken = eat(TK_EOL)	' SKIP REQUIRED "EOL"
			Case TK_REM
				Local node:TAST_Rem = New TAST_Rem( token ) 
				advance()
				node.closing = eat( TK_ENDREM )
				ast.add( node ) 
			Default
				' Finished with Comments and EOL!
				Return False
			End Select
		Forever
	End Method

	Method ParseComparison:TASTNode()
		Local ast:TASTNode = ParseTerm()
		While token.in( [TK_greaterthan,TK_lessthan,TK_GT_OR_EQUAL,TK_LT_OR_EQUAL] )
			Local operation:TToken = eat( [TK_greaterthan,TK_lessthan,TK_GT_OR_EQUAL,TK_LT_OR_EQUAL] )
			ast = New TASTBinary( ast, operation, ParseTerm() )				
		Wend
		Return ast
	End Method

	' A condition is simply an Expression, so call that instead
	Method ParseCondition:TASTNode()
		Return ParseEquality()
	
		' A Condition is just an expression...
		' A condition can be unary or binary in operation.	
		' This is an implementation of Resursive Descent	

'		Function comparison:TASTNode()
'			Local expr:TASTNode = term()
'			advance()
'			
'			While token.in( [TK_GT,TK_LT,TK_GTE,TK_LTE] )
'				Local op:TToken = token
'				advance()
'				Local rnode:TASTNode = term()
'				expr = New TASTBinary( expr, op, rnode )				
'			Wend
'			
'			Return expr
'		End Function

'		Function equality:TASTNode()
'			Local expr:TASTNode = comparison()
'			advance()
'			
'			While token.in( [TK_Equal,TK_NotEqual] )
'				Local op:TToken = token
'				advance()
'				Local rnode:TASTNode = comparison()
'				expr = New TASTBinary( expr, op, rnode )
'			Wend 
'			
'			Return expr
'		End Function
		
'		Function expression:TASTNode() 
'			Return equality()
'		End Function

'		Function unary:TASTNode() 
'			If token.in( [TK_Not,TK_Hyphen] )
'				Local op:TToken = token
'				advance()
'				Local node:TASTNode = unary()
'				Return New TASTUnary( op, node )
'			End If
'			Return primary()
'		End Function

'		Function primary:TASTNode()
'			Select token
'			Case TK_True, TK_False, TK_Null
'				Return New TASTNode( token )
'			Case TK_Number,TK_Alpha
'				Return New TASTNode( token )
'			Case TK_LPAREN
'				Local expr:TASTNode = expression()
'				Local rparen:TToken = eat( TK_RParen )
'				Return New TASTGroup( expr )
'			End Select
'			Return Null
'		End Function
		
		' Order of precedence - Addition and Subtraction FIRST
'		Function term:TASTNode()
'			Local expr:TASTNode = factor()
'			advance()
'			
'			While token.in( [TK_Plus,TK_Minus] )
'				Local op:TToken = token
'				advance()
'				Local rnode:TASTNode = factor()
'				expr = New TASTBinary( expr, op, rnode )
'			Wend 
'			
'			Return expr			
'		End Function

		' Order of precedence - Multiplication and Division LAST
'		Function factor:TASTNode()
'			Local expr:TASTNode = unary()
'			advance()
'			
'			While token.in( [TK_Solidus,TK_Asterisk] )
'				Local op:TToken = token
'				advance()
'				Local rnode:TASTNode = unary()
'				expr = New TASTBinary( expr, op, rnode )
'			Wend 
'			
'			Return expr			
'		End Function

	End Method
	
	' EQUALITY := COMPARISON ( ( "=" | "<>" ) comparison )*
	Method ParseEquality:TASTNode()
		Local ast:TASTNode = ParseComparison()
		While token.in( [TK_equals,TK_NOT_EQUAL] )
			Local operation:TToken = eat( [TK_equals,TK_NOT_EQUAL] )
			ast = New TASTBinary( ast, operation, ParseComparison() )
		Wend 
		Return ast
	End Method
		
	' An expression is now simply an equality rule, so call that instead
	Method ParseExpression:TASTNode()
		Return ParseEquality()
	End Method

	' Order of precedence - Multiplication and Division LAST
	Method ParseFactor:TASTNode()
		Local ast:TASTNode = ParseUnary()
		While token.in( [TK_Asterisk, TK_Solidus] )					' MULTIPLY, DIVIDE
			Local operation:TToken = eat( [TK_Asterisk, TK_Solidus] )
			ast = New TASTBinary( ast, operation, ParseUnary() )
		Wend
		Return ast	
	End Method 

	Method ParsePrimary:TASTNode()
		Select token.id
		Case TK_True, TK_False, TK_Null
			Local ast:TASTVariable = New TASTVariable( token )
			advance()
			Return ast
		Case TK_Number
			Local ast:TASTNumber = New TASTNumber( token )
			advance()
			Return ast
		Case TK_Alpha
			Local ast:TASTVariable = New TASTVariable( token )
			advance()
			Return ast
		Case TK_LPAREN
			Local lparen:TToken = eat( TK_LParen )
			Local ast:TASTNode = ParseExpression()
			Local rparen:TToken = eat( TK_RParen )
			Return New TASTGroup( ast )
		End Select
		Return Null
	End Method
		
	' Order of precedence - Multiplication and Division LAST
	Method ParseTerm:TASTNode()
		Local ast:TASTNode = ParseFactor()
		While token.in( [TK_Plus,TK_Hyphen] )					' ADDITION, SUBTRACTION
			Local operation:TToken = eat( [TK_Plus,TK_Hyphen] )
			ast = New TASTBinary( ast, operation, ParseFactor() )
		Wend
		Return ast	
		
'		Select token.id
'		Case TK_Number
'			Local ast:TASTNumber = New TASTNumber( token )
'			advance()
'			Return ast
'		Case TK_Alpha
'			Local ast:TASTVariable = New TASTVariable( token )
'			advance()
'			Return ast
'		Case TK_LParen
'DebugStop
'			advance()
'			Local ast:TASTNode = ParseExpression()
'			Local rparen:TToken = eat( TK_RParen )
'			Return ast
'		EndSelect
Rem
       """factor : INTEGER | LPAREN expr RPAREN"""
        token = self.current_token
        if token.type == INTEGER:
            self.eat(INTEGER)
            return Num(token)
        elif token.type == LPAREN:
            self.eat(LPAREN)
            node = self.expr()
            self.eat(RPAREN)
            return node
EndRem		

	
	End Method
			
	' Unary operation
	Method ParseUnary:TASTNode() 
		If token.in( [TK_Not,TK_Hyphen] )
			Local operation:TToken = eat( [TK_Not,TK_Hyphen] )
			Return New TASTUnary( operation, ParseUnary() )
		End If
		Return ParsePrimary()
	End Method


	' Parses the application header into an EXISTING ast compound node
	
Rem	Method parseHeader:TASTCompound( ast:TASTCompound )	
		Const FSM_STRICTMODE:Int = 0
		Const FSM_FRAMEWORK:Int = 1
		Const FSM_MODULE:Int = 2
		Const FSM_MODULEINFO:Int = 3
		Const FSM_IMPORT:Int = 4
		Const FSM_INCLUDE:Int = 5
		
		'Local ast:TASTCompound = New TASTCompound( "PROGRAM" )
		Local ast_module:TAST_Module, ast_imports:TASTCompound
		Local fsm:Int = FSM_STRICTMODE
'DebugStop	
		Repeat		
			Try
				If Not token Throw( "Unexpected end of token stream (STRICTMODE)" )
				
				' Parse Comments and EOL
				'If parseCEOL( ast, token ) Continue
				'If parseREM( ast, token ) Continue
				'If token.id = TK_EOF Return ast		' Source finished
				
				' Parse comments/eol and return as if at EOF
				If parseCEOL( ast ) Return ast

'DebugStop				
				' Parse this token
				Select token.id			
				'Case TK_EOF
				'	Return ast
				'Case TK_EOL
				'	ast.add( New TASTNode( "EOL" ) )
				'	token = lexer.getNext()
				'Case TK_COMMENT
				'	ast.add( Parse_Comment( token ) )
				'Case TK_REM
				'	ast.add( Parse_Rem( token ) )			
				Case TK_STRICT, TK_SUPERSTRICT
					If fsm > FSM_STRICTMODE
						ast.add( New TAST_Skipped( token )) ' MUST BE FIRST STATEMENT
					Else
						ast.add( Parse_Strictmode() )		' STRICTMODE
					End If
					fsm = FSM_FRAMEWORK
					
				Case TK_FRAMEWORK
					If fsm > FSM_FRAMEWORK
						ast.add( New TAST_Skipped( token ))  ' MUST BE BEFORE IMPORT
					Else
						ast.add( Parse_Framework() )
					End If
					fsm = FSM_IMPORT

				Case TK_MODULE
					If fsm > FSM_FRAMEWORK
						ast.add( New TAST_Skipped( token ) ) ' MUST BE BEFORE IMPORT
					Else
						' Change parent from "PROGRAM" to "MODULE"
						ast.name = "MODULE"
						ast_module = Parse_Module()
						ast.add( ast_module )
					End If
					fsm = FSM_MODULE
					'
				Case TK_MODULEINFO
					If fsm <> FSM_MODULE
						ast.add( New TAST_Skipped( token ) ) ' MUST BE AFTER MODULE
					Else
						ast_module.add( Parse_Moduleinfo() )
					End If
					'
				Case TK_IMPORT
'DebugStop
					If fsm > FSM_IMPORT
						ast.add( New TAST_SKIPPED( token ))  ' MUST BE BEFORE INCLUDE
					Else
						' Create an imports section if none exists
						If Not ast_imports
							ast_imports = New TASTCompound( "IMPORTS" )
							ast.add( ast_imports )
						End If
						
						' Add import 
						ast_imports.add( Parse_Import() )					
					End If

				Case TK_INCLUDE
					ast.add( Parse_Include() )
					fsm = FSM_INCLUDE
				Default
					' If we encounter anything else; the header is complete
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
EndRem

Rem
	Method parseHeader:TASTCompound( ast:TASTCompound, token:TToken Var )	
		Const FSM_STRICTMODE:Int = 0
		Const FSM_FRAMEWORK:Int = 1
		Const FSM_MODULE:Int = 2
		Const FSM_MODULEINFO:Int = 3
		Const FSM_IMPORT:Int = 4
		
		'Local ast:TASTCompound = New TASTCompound( "PROGRAM" )
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
						Publish( "syntax-error", "'"+token.value+"' was unexpected at this time" )
						Continue
					End If
					fsm = FSM_FRAMEWORK
					'
					ast.add( Parse_Strictmode( token ) )
				Case TK_FRAMEWORK
					If fsm > FSM_FRAMEWORK
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time" )
						Continue
					End If
					fsm = FSM_IMPORT
					'
					ast.add( Parse_Framework( token ) )
				Case TK_MODULE
					If fsm > FSM_FRAMEWORK
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time" )
						Continue
					End If
					fsm = FSM_MODULE
					'
					ast_module = Parse_Module( token )
					ast.add( ast_module )
				Case TK_MODULEINFO
					If fsm <> FSM_MODULE
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time" )
						Continue
					End If
					'
					ast_module.add( Parse_Moduleinfo( token ) )
				Case TK_IMPORT
'DebugStop
					If fsm > FSM_IMPORT
						publish( "syntax-error", "'"+token.value+"' was unexpected at this time" )
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
End Rem	

	'	Looks for trailing comments
	'	These will become descriptions in the ast node
'	Method ParseDescription:String( token:TToken Var )
'		Local description:String
'		' Trailing comment is a description
'		token = lexer.expect( [TK_COMMENT,TK_EOL] )
'		If token.id = TK_COMMENT
'			' Inline comment becomes the node description
'			description = token.value
'			token = lexer.Expect( TK_EOL )
'		End If
'		Return description
'	End Method	

Rem
	Method Parse_CommentTEST:TASTNode()
		Local ast:TASTNode = New TASTNode( "COMMENT", token )
'DebugStop
		advance()
		Local temp:TToken = eat(TK_EOL)	' SKIP REQUIRED "EOL"
		'token2 = lexer.getNext()			' Skip EOL
		Return ast
	End Method
End Rem	

	'Method Parse_Comment:TASTNode( token:TToken Var )
	'	Local ast:TASTNode = New TASTNode( "COMMENT", token )
	'	token = lexer.expect(TK_EOL)
	'	token = lexer.getNext()			' Skip EOL
	'	Return ast
	'End Method

Rem

		    CONST:TASTAssignment
		____________|_____________
		|                        |
		LNODE: TAST_VARDEF          RNODE: TASTNODE
		NAME:TToken
		COLON:TToken
		VARTYPE:TToken
		
EndRem

	Method Parse_Const:TASTNode()
		Local ast:TAST_Assignment = New TAST_Assignment( token )	' LOCAL, GLOBAL or FIELD
		ast.lnode = Parse_VarDef()	
		' Do we have an assignment operator
		Local equals:TToken = eatOptional( TK_Equals, Null )
		If equals
			eat( TK_Equals )	' Throw that away
'TODO: Implement variable definition
			ast.rnode = eatUntil( [TK_EOL], token )
		End If
		Return ast
	End Method

	Method Parse_ElseIf:TASTNode()
		Return Parse_If_Block( New TAST_ElseIf( token ) )
	End Method
		
	Method Parse_End:TASTNode()
		Local ast:TASTKeyword = New TASTKeyword( token )
		advance()
		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		Return ast
	End Method

	Method Parse_Enum:TASTNode()
'DebugStop
		Local ast:TAST_Enum = New TAST_Enum( token )
		advance()

		' Get properties
		ast.name = eat( TK_ALPHA )
		parseSequence( ast, SYM_ENUM_BODY+[TK_ALPHA], [TK_EndEnum] )
		
		' End of block
		ast.ending = eat( TK_EndEnum )
		Return ast
	End Method
	
	Method Parse_Field:TASTNode()
		Local ast:TAST_Assignment = New TAST_Assignment( token )	' LOCAL, GLOBAL or FIELD
		ast.lnode = Parse_VarDef()	
		' Do we have an assignment operator
		Local equals:TToken = eatOptional( TK_Equals, Null )
		If equals
			eat( TK_Equals )	' Throw that away
'TODO: Implement variable definition
			ast.rnode = eatUntil( [TK_EOL], token )
		End If
		Return ast
	End Method

	' FOR..NEXT LOOP
	Method Parse_For:TASTNode()
'DebugStop
		Local ast:TAST_For = New TAST_For( token )
		advance()

		' Get properties
		'ast.name = eat( TK_ALPHA )
		'ast.extend = eatOptional( TK_Extends, Null )
		'If ast.extend ast.supertype = eat( TK_ALPHA )

		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		
		parseSequence( ast, SYM_FOR_BODY+[TK_ALPHA], [TK_Next] )
		
		' End of block
		ast.ending = eat( TK_Next )
		Return ast
	End Method
	
	'	framework = framework ALPHA PERIOD ALPHA [COMMENT] EOL
	Method Parse_Framework:TASTNode()
'DebugStop
		Local fwork:TToken = eatOptional( TK_FRAMEWORK, Null )
		'If Not token Return New TASTMissingOptional( "FRAMEWORK", "Framework" )
		If Not fwork 
			Local starts:TPosition = New TPosition( token )
			Local ends:TPosition =  New TPosition( token )
			ends.character :+ token.value.length
			Local ast:TASTMissingOptional = New TASTMissingOptional( "FRAMEWORK", "Framework", token.line )
			ast.errors :+ [ New TDiagnostic( "'Framework' is recommended", DiagnosticSeverity.Hint, New TRange( starts, ends ) ) ]
			Return ast
		End If
		'
		Local ast:TAST_Framework = New TAST_Framework( token )
		'advance()
		' Get properties
		ast.major = eat( TK_ALPHA )
		ast.dot = eat( TK_PERIOD )
		ast.minor = eat( TK_ALPHA )
		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		Return ast
	End Method

	'	function = function [ ":" <vartype> ] "(" [<args>] ")" [COMMENT] EOL
	Method Parse_Function:TASTNode(  )
		Local ast:TAST_Function = New TAST_Function( token )
		advance()

		' PROPERTIES
		
		ast.name = eat( TK_ALPHA, Null )
		ast.colon = eatOptional( TK_COLON, Null )
		If ast.colon ast.returntype = eat( SYM_DATATYPES+[TK_ALPHA], Null )
		ast.lparen = eat( TK_lparen, Null )
		ast.rparen = eatOptional( TK_rparen, Null )
		If Not ast.rparen
			ast.arguments = ParseArguments()
			ast.rparen = eat( TK_rparen, Null )
		End If

		'	READ BODY
		
		parseSequence( ast, SYM_FUNCTION_BODY+[TK_ALPHA], [TK_EndFunction] )
		
		' CLOSING KEYWORD
		
		ast.ending = eat( TK_EndFunction )
		Return ast
	End Method

	Method Parse_Global:TASTNode()
		Local ast:TAST_Assignment = New TAST_Assignment( token )	' LOCAL, GLOBAL or FIELD
		ast.lnode = Parse_VarDef()	
		' Do we have an assignment operator
		Local equals:TToken = eatOptional( TK_Equals, Null )
		If equals
			eat( TK_Equals )	' Throw that away
'TODO: Implement variable definition
			ast.rnode = eatUntil( [TK_EOL], token )
		End If
		Return ast
	End Method

	Method Parse_If:TASTNode()
		Return Parse_If_Block( New TAST_If( token ) )
	End Method
	
	' Processes IF and ELSEIF, but requires the correct Node to work on.
	Method Parse_If_Block:TASTNode( ast:TAST_If )
		Local class:Int = 0		' Identify single line or multiline IF statements
		
'DebugLog( String(token.line)[..4]+"IF..." )
'DebugStop
		'	"IF" ["("] expression [")"] [";"|"THEN"] statement
		'	"IF" ["("] expression [")"] [";"|"THEN"] CRLF statement ["ELSE" <IFTHEN>] "END"["IF"]
		
		advance()
		
		' Parse the condition
		ast.condition = ParseCondition()
		
'Local debug:TToken = token
'DebugStop

		' Eat optional Semicolon or THEN statements
		Local optionalthen:TToken = eatOptional( [TK_Then,TK_Semicolon], False )	' Returns NULL if missing

		' Identify comments and EOL
		If token.in( [TK_EOL,TK_EOF,TK_COMMENT] )
			class = 2	' Multi line
'DebugLog( "- MULTI LINE IF" )
			If ParseCEOL( ast ) ; Return ast
			parseSequence( ast, SYM_IF_BODY+[TK_ALPHA], [TK_EndIf,TK_Else,TK_Elseif] )
		Else
			class = 1	' Single line
'DebugLog( "- SINGLE LINE IF" )
'DebugStop
			parseSequence( ast, SYM_IF_BODY+[TK_ALPHA], [TK_EndIf,TK_Else,TK_Elseif,TK_EOL] )
		End If

'DebugStop
		' Parse the IF body
		
		Select token.id
		Case TK_EndIf
			eat( TK_Endif )
		Case TK_Else
'DebugStop
			Local otherwise:TToken = eat( TK_Else )
			ast.otherwise = parseSequence( "ELSE", SYM_IF_BODY+[TK_ALPHA], [TK_Endif] )
			ast.otherwise.consume( otherwise )
			eat( TK_Endif )
		Case TK_Elseif
'DebugStop
			'eat( TK_ElseIf )	' Don't need this, it is consumed in Parse_ElseIf()
			ast.otherwise = Parse_ElseIf()
		EndSelect
		
'debug=token
'DebugStop

		Return ast

	End Method
	
	'	Create an AST Node for Import containing all imported modules as children
	'	import = import ALPHA PERIOD ALPHA [COMMENT] EOL
	Method Parse_Import:TASTNode()
		Local ast:TAST_Import = New TAST_Import( token )
		advance()
		' Get module name
		ast.major = eat( TK_ALPHA )
		ast.dot = eat( TK_PERIOD )
		ast.minor = eat( TK_ALPHA )
		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		Return ast
	End Method

	'	Create an AST Node for Import
	Method Parse_Include:TASTNode()
		Local ast:TAST_Include = New TAST_Include( token )
		advance()
		' Get module name
		ast.file = eat( TK_QSTRING )
'DebugStop		
		' Request document is opened (If it isn't already)
		If ast.file And ast.file.id=TK_QSTRING
			Local file:String = ast.file.value
			'Local included:TTextDocument = documents.getFile( file )
		End If
		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		Return ast
	End Method

	Method Parse_Interface:TASTNode()
'DebugStop
		Local ast:TAST_Interface = New TAST_Interface( token )
		advance()

		' Get properties
		ast.name = eat( TK_ALPHA )
		parseSequence( ast, SYM_INTERFACE_BODY+[TK_ALPHA], [TK_EndInterface] )
		
		' End of block
		ast.ending = eat( TK_EndInterface )
		Return ast
	End Method
	
	Method Parse_Local:TASTNode()
		Local ast:TAST_Assignment = New TAST_Assignment( token )	' LOCAL, GLOBAL or FIELD
		ast.lnode = Parse_VarDef()	
		' Do we have an assignment operator
		Local equals:TToken = eatOptional( TK_Equals, Null )
		If equals
			eat( TK_Equals )	' Throw that away
'TODO: Implement variable definition
			ast.rnode = eatUntil( [TK_EOL], token )
		End If
		Return ast
	End Method
	
	'	method = method [ ":" <vartype> ] "(" [<args>] ")" [COMMENT] EOL
	Method Parse_Method:TAST_Method()
		Local ast:TAST_Method = New TAST_Method( token )
		advance()
'Print "PASSING METHOD"
'DebugStop
		' PROPERTIES
		
		ast.name = eat( [TK_New,TK_ALPHA], Null )
		ast.colon = eatOptional( TK_COLON, Null )
		If ast.colon ast.returntype = eat( SYM_DATATYPES+[TK_ALPHA], Null )
		ast.lparen = eat( TK_lparen, Null )
		ast.rparen = eatOptional( TK_rparen, Null )
		If ast.name And ast.lparen And Not ast.rparen
			ast.arguments = ParseArguments()
			ast.rparen = eat( TK_rparen, Null )
		End If

		'	READ BODY
		
		If Not ast.name Or Not ast.lparen Or Not ast.rparen
			' Do not parse body of a badly formed definition
			ast.add( eatUntil( [TK_EndMethod], token ) )
		Else
			parseSequence( ast, SYM_METHOD_BODY+[TK_ALPHA], [TK_EndMethod] )
		End If
		
		' CLOSING KEYWORD
		
		ast.ending = eat( TK_EndMethod )
		Return ast
	End Method
		
	Method Parse_Module:TAST_Module()
		Local token:TToken = eatOptional( TK_MODULE, Null )
		If Not token Return Null
		'
		Local ast:TAST_Module = New TAST_Module( token )
		advance()
		' Get module name
		ast.major = eat( TK_ALPHA )
		ast.dot = eat( TK_PERIOD )
		ast.minor = eat( TK_ALPHA )
		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		Return ast
	End Method

	Method Parse_ModuleInfo:TASTNode()
		Local token:TToken = eatOptional( TK_MODULEINFO, Null )
		If Not token Return Null
		'
		Local ast:TAST_ModuleInfo = New TAST_ModuleInfo( token )
		advance()
		' Get module name
		ast.value = eat( TK_QSTRING )
		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		Return ast
	End Method
	
Rem	Method Parse_Rem:TASTNode()
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
EndRem

	' REPEAT .. UNTIL|FOREVER
	Method Parse_Repeat:TASTNode()
'DebugStop
		Local ast:TAST_Repeat = New TAST_Repeat( token )
		advance()

		' Get properties
		'ast.name = eat( TK_ALPHA )
		'ast.extend = eatOptional( TK_Extends, Null )
		'If ast.extend ast.supertype = eat( TK_ALPHA )

		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		
		parseSequence( ast, SYM_REPEAT_BODY+[TK_ALPHA], [TK_Until,TK_Forever] )
		
		' End of block
		ast.ending = eat( [TK_Until,TK_Forever] )
		Return ast
	End Method

	Method Parse_Return:TASTNode()
		'Print( "Parse_Return() is not implemented" )
'DebugStop
		Local ast:TAST_Return = New TAST_Return( token )
		advance()
		
		ast.expr = ParseExpression()
		Return ast
	End Method
	
	'	strictmode = (strict|superstrict) [COMMENT] EOL
'	Method Parse_Strictmode:TASTNode( token:TToken Var )
'		Local ast:TASTNode = New TASTNode( "STRICTMODE", token )
'		'
'		' Trailing comment is a description
'		ast.descr = ParseDescription( token )
'		token = lexer.getNext()
'		Return ast
'	End Method



	'	strictmode = (strict|superstrict) [COMMENT] EOL
	Method Parse_Strictmode:TASTNode()
		Local Strictmode:TToken = eatOptional( [TK_STRICT, TK_SUPERSTRICT], Null )
		If Not Strictmode 
			Local starts:TPosition = New TPosition( token )
			Local ends:TPosition =  New TPosition( token )
			ends.character :+ token.value.length
			Local ast:TASTMissingOptional = New TASTMissingOptional( "STRICTMODE", "superstrict~n", token.line )
			ast.errors :+ [ New TDiagnostic( "'SuperStrict' is recommended", DiagnosticSeverity.Hint, New TRange( starts, ends ) ) ]
			Return ast
		End If
'DebugStop
		Local ast:TAST_Strictmode = New TAST_Strictmode( token )
		'advance()
		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		Return ast
	End Method
	
	'	type = type ALPHA [ extends ALPHA ] [COMMENT] EOL
Rem	Method Parse_Type:TASTNode( token:TToken Var )
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
			'token = lexer.getNext()	' Skip supertype
		End If
		
		' Trailing comment is a description
		ast.descr = ParseDescription( token )
		token = lexer.getNext()

		' Parse TYPE into ast
'DebugStop
		ast = TAST_Type( ParseBlock( TK_TYPE, ast, token, SYM_TYPEBODY, Null ) )

		'Rem
		'Local finished:Int = False
		'Repeat
		'	token = lexer.getNext()
		'	If token.id = TK_END
		'		token = lexer.getNext()
		'		If token.id = TK_TYPE ; finished = True
		'	End If
		'Until token.id = TK_ENDTYPE Or finished
		'End Rem
		
		'
		' Trailing comment is a description
		Local descr:String = ParseDescription( token )
		If descr ast.descr :+ " "+descr
		token = lexer.getNext()
		Return ast
	End Method
End Rem

	Method Parse_Struct:TASTNode()
'DebugStop
		Local ast:TAST_Struct = New TAST_Struct( token )
		advance()

		' Get properties
		ast.name = eat( TK_ALPHA )
		parseSequence( ast, SYM_STRUCT_BODY+[TK_ALPHA], [TK_EndStruct] )
		
		' End of block
		ast.ending = eat( TK_EndStruct )
		Return ast
	End Method
	
	Method Parse_Type:TASTNode()
'DebugStop
		Local ast:TAST_Type = New TAST_Type( token )
		advance()

		' Get properties
		ast.name = eat( TK_ALPHA )
		ast.extend = eatOptional( TK_Extends, Null )
		If ast.extend ast.supertype = eat( TK_ALPHA )

		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		
		' BODY OF THE TYPE
		
		' For the sake of simplicity at the moment, this will not parse the body
		' ast.add( ParseBlock( [ TK_LOCAL, TK_GLOBAL, TK_REPEAT, etc] )
		'ast.add( eatUntil( [TK_EndType], token ) )
		'ListAddLast( ast.children, New TASTNode("ERROR" ) )
		parseSequence( ast, SYM_TYPE_BODY+[TK_ALPHA], [TK_EndType] )
		
		' End of block
		ast.ending = eat( TK_EndType )
		Return ast
	End Method

	' Variable Declaration using Const, Field, Global or Local
	Method Parse_VarDef:TASTNode()
'DebugStop
		Local ast:TAST_VARDEF = New TAST_VARDEF( token )	' Variable Defintion (Const, Field, Global, Local )
		advance()
		ast.name = eat( TK_ALPHA )
		ast.colon = eatOptional( TK_Colon, Null )
		If ast.colon ; ast.vartype = eat( SYM_DATATYPES+[TK_ALPHA] )
		
		' Check for Function Variables:
		Local paren:TToken = eatOptional( TK_LParen, Null )
		If paren
			ast.func = New TAST_Function()
			advance()
			ast.func.name = eat( TK_ALPHA )
			ast.func.colon = eatOptional( TK_Colon, Null )
			If ast.func.colon ; ast.func.returntype = eat( SYM_DATATYPES+[TK_ALPHA] )
			ast.func.lparen = eat( TK_LParen )
			ast.func.arguments = eatUntil( [TK_RParen], token)
			ast.func.rparen = eat( TK_RParen )		
			Return ast
		End If

		' Standard Variable declaration
		Return ast
	End Method
	
	
	
	Rem VARDECL
	Local X:Int = 25
	Local X:Int = 10*a
	Local X( y:Int ) = something
	Local X:Int( y:Int ) = something
	End Rem
Rem	Method Parse_VarDecl:TASTNode()
'DebugStop
		Local ltoken:TTOken = eat( TK_ALPHA )
		Local colon:TToken = eatOptional( TK_Colon, Null )
		Local vartype:TTOken
		If colon vartype = eat( SYM_DATATYPES+[TK_ALPHA] )
		Local paren:TToken = eatOptional( TK_LParen, Null )
		
		' Identify Function variable declaration
		If paren
			Local ast:TAST_Function = New TAST_Function()
			advance()
			ast.name = ltoken
			ast.colon = colon
			ast.returntype = vartype
			ast.lparen = paren
			ast.def = eatUntil( [TK_rparen], token)
			ast.rparen = eat( TK_rparen )		
			Return ast
		End If

		' Standard Variable declaration
		Local ast:TAST_VARDEF = New TAST_VARDEF( token )	' Variable Defintion
		ast.lnode = New TASTNode( ltoken )
		ast.operation = colon
		ast.rnode = New TASTNode( vartype )
		Return ast
	End Method
EndRem

	' WHILE...WEND
	Method Parse_While:TASTNode()
'DebugStop
		Local ast:TAST_While = New TAST_While( token )
		advance()

		' Get properties
		'ast.name = eat( TK_ALPHA )
		'ast.extend = eatOptional( TK_Extends, Null )
		'If ast.extend ast.supertype = eat( TK_ALPHA )

		' Trailing comment is a description
		'ast.comment = eatOptional( [TK_COMMENT], Null )
		
		parseSequence( ast, SYM_WHILE_BODY+[TK_ALPHA], [TK_Wend] )
		
		' End of block
		ast.ending = eat( TK_Wend )
		Return ast
	End Method
		
	' Obtain closing token for a given blocktype
	Method closingToken:Int( tokenid:Int )
		Select tokenid
		Case TK_ENUM		;	Return TK_ENDENUM
		Case TK_EXTERN		;	Return TK_ENDEXTERN
		Case TK_FUNCTION	;	Return TK_ENDFUNCTION
		Case TK_IF			;	Return TK_ENDIF
		Case TK_INTERFACE	;	Return TK_ENDINTERFACE
		Case TK_METHOD		;	Return TK_ENDMETHOD
		Case TK_REM			;	Return TK_ENDREM
		Case TK_REPEAT		;	Return Null	'[ TK_FOREVER, TK_UNTIL ]
		Case TK_SELECT		;	Return TK_ENDSELECT
		Case TK_STRUCT		;	Return TK_ENDSTRUCT
		Case TK_TRY			;	Return TK_ENDTRY
		Case TK_TYPE		;	Return TK_ENDTYPE
		Case TK_WHILE		;	Return Null 'TK_ENDWHILE, TK_WEND]
		End Select
	End Method

	' Dump the symbol table into a string
	'Method reveal:String()
	'	Local report:String = "POSITION  SCOPE     NAME      TYPE~n"
	'	For Local row:TSymbolTableRow = EachIn symbolTable.list
	'		report :+ (row.line+","+row.pos)[..8]+"  "+row.scope[..8]+"  "+row.name[..8]+"  "+row.class[..8]+"~n"
	'	Next
	'	Return report
	'End Method
	
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
