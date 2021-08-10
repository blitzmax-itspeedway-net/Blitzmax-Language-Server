
'	BlitzMax Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	A LANGUAGE SYNTAX IS CURRENTLY UNAVAILABLE
'	THIS IS THEREFORE HARDCODED AT THE MOMENT
'	IT WILL BE RE-WRITTEN WHEN SYNTAX IS DONE

Type TBlitzMaxParser Extends TParser

	Field strictmode:Int = 0
	Field symbolTable:TSymbolTable = New TSymbolTable()	
	
	Method New( lexer:TLexer, abnf:TABNF = Null )
		Super.New(lexer, abnf)

Rem
		'	We need to follow a grammar rule so until we have a way to
		'	parse one from a file, we have to create it manually here

		'	RULE:
		'	program = Application / Module
		'	application = [Strictmode] [Framework] [*Import] [*Include] Block
		'	module = [Strictmode] ModuleDef [*Import] [*Include] Block
		'	strictmode = "strict" / "superstrict"
'DebugStop		
		'	Create "PROGRAM" rule
		Local _application:TGNode = New TGnode()
		Local _module:TGNode = New TGnode()
		
		' Application has no successor and "Module" as alternative
		_application.terminal = False
		_application.alt = _module
		_application.suc = Null
		_application.sym = New TSymbol( 0, "application", "" )
		
		' Module has no successor and no alternative
		_module.terminal = False
		_module.alt = Null
		_module.suc = Null
		_module.sym = New TSymbol( 0, "module", "" )
		
		' Create rule
		abnf.add( "program", _application )		
		
		'	Create "STRICTMODE" rule
		Local _strict:TGNode = New TGnode()
		Local _superstrict:TGNode = New TGnode()
		Local _strictnull:TGNode = New TGnode()

		' Strictmode can be either "strict" or "superstrict" or null
		_strict.terminal = True
		_strict.alt = _superstrict
		_strict.suc = Null
		_strict.sym = New TSymbol( 0, "strict", "" )
		
		_superstrict.terminal = True
		_superstrict.alt = _strictnull
		_superstrict.suc = Null
		_superstrict.sym = New TSymbol( 0, "superstrict", "" )	
			
		_strictnull.terminal = True
		_strictnull.alt = Null
		_strictnull.suc = Null
		_strictnull.sym = New TSymbol( 0, "", "" )		
		
		' Create rule
		abnf.add( "strictmode", _strict )
		
		'	Create "Application" rule
		Local _strictmode:TGNode = New TGnode()
		Local _framework:TGNode = New TGnode()

		_strictmode.terminal = False
		_strictmode.alt = Null
		_strictmode.suc = _framework
		_strictmode.sym = New TSymbol( 0, "strictmode", "" )

		_framework.terminal = False
		_framework.alt = Null
		_framework.suc = Null
		_framework.sym = New TSymbol( 0, "framework", "" )
		
		' Create rule
		abnf.add( "application", _strictmode )		
End Rem	

	End Method

Rem	
	' The story starts, as they say, with a beginning...
	Method parse_OLD:AST()
		
		' 	ABNF
		'		Program = [Strictmode] | [ Application | Module ]
		'		Application = [Strictmode] [Framework] [*Import] [*Include] Block
		'		Module = [Strictmode] ModuleDef [*Import] [*Include] Block
		'
DebugStop


		
		
		
		
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
	
	Method rule_strictmode:TAbSynTree( syntax:TToken[] )
		' strictmode = (strict | superstrict) [comment] EOL
		Print "RULE STRICTMODE"
		Assert syntax.length=3, "rule_strictmode() FAILED"

		' SET PARSER STATE TO SELECTED STRICT MODE
		strictmode = syntax[0].id

		' CREATE AST
		Return New TAbSynTree( "strictmode", syntax[0] )
	End Method
	
	
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

Type AST_strictmode Extends TAbSynTree
	Field comment:String
	Field strictmode:Int
	Method New( strictmode:TToken, comment:TToken )
		Self.strictmode = strictmode.id
		If comment Self.comment = comment.value
	End Method
End Type
