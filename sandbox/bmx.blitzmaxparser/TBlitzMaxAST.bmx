
'	BlitzMax Abstract Syntax Tree
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	17 AUG 21	Initial version
'	V1.1	22 AUG 21	Added TAST_Function(), TAST_Method() and TAST_Type()

' Diagnostics node used when an optional token is missing
Type TASTMissingOptional Extends TASTNode { class="missingoptional" }
	Field name: String
	
	Method New( name:String, value:String, line:Int )
'DebugStop
		Self.name   = name
		Self.value  = value
		'Self.errors = New TList()
		'Self.status = AST_NODE_WARNING
		'Local range:TRange = New TRange( 0,0,0,0 )
		Self.start_line = line
		Self.start_char = 0
		Self.end_line = line+1
		Self.end_char = 0
		'errors :+ [ New TDiagnostic( "'"+name+"' is recommended", DiagnosticSeverity.Hint, range ) ]
	End Method
		
End Type

' Diagnostics node used when a token is ignored by the Parser
'Type TASTIgnored Extends TASTCompound { class="IGNORED" }			
'	Method New( token:TTOken )
'		consume( token )
'	End Method
'End Type

' Diagnostics node used when a token is unexpected.
'Type TASTUnexpected Extends TASTCompound { class="UNEXPECTED" }			
'End Type

' Diagnostics node used when a token is skipped by the Parser
Type TASTSkipped Extends TASTError { class="SKIPPED" }
	Method New( token:TTOken )
		consume( token )
	End Method
	
	Method New( token:TToken, error:String )
		consume( token )
		errors :+ [ New TDiagnostic( error, DiagnosticSeverity.Warning ) ]
		'Self.valid = False
	End Method	
End Type

Type TASTKeyWord Extends TASTNode { class="KEYWORD" }
	Method New( token:TTOken )
		consume( token )
	End Method
End Type

Type TASTNumber Extends TASTNode	{ class="number" }
	Method New( token:TTOken )
		consume( token )
	End Method
End Type

Type TASTVariable Extends TASTNode	{ class="variable" }
	Method New( token:TTOken )
		consume( token )
	End Method
End Type

' Node for END OF LINE marker
Type TAST_EOL Extends TASTNode { class="EOL" }
	'Method New( name:String, value:String )
	'	Self.name  = name
	'	Self.value = value
	'End Method
	
	' We don't need to see EOL in the AST during DEBUG!
	Method reveal:String( indent:String = "" )
		Return ""
	End Method
End Type

' Diagnostics node used when an error has been found and a node has been skipped
'Type TAST_Skipped Extends TASTError { class="skipped" }
'	
'	' descr field should hold some detail used by the language server to
'	' help user recreate this, or force it
'	' default value needs to be included so it can be "fixed"
'
'	Method New( name:String, value:String )
'		Self.name  = name
'		Self.value = value
'		'Self.valid = False
'	End Method
'
'	Method New( token:TToken, error:String )
'		consume( token )
'		errors :+ [ New TDiagnostic( error, DiagnosticSeverity.Warning ) ]
''		'Self.valid = False
'	End Method	
'		
'End Type

' This AST Node is used for LOCAL, GLOBAL and FIELD definitions
'Type TAST_VariableDeclaration Extends TASTBinary { class="VariableDeclaration" }
'End Type

Type TAST_Comment Extends TASTNode { class="COMMENT" }
'	Method validate() ; valid = True ; error = [] ; End Method
End Type

Type TAST_Enum Extends TASTCompound { class="ENUM" }
	Field name:TToken
	Field ending:TToken
			
	' Used for debugging tree structure
	Method showLeafText:String()
		Return name.value
	End Method
	
	Method validate()
		If children.isempty() ; errors :+ [ New TDiagnostic( "Empty Construct", DiagnosticSeverity.Error ) ]
	End Method
	
End Type

Type TAST_For Extends TASTCompound { class="FORNEXT" }
	Field ending:TToken	
End Type

Type TAST_Framework Extends TASTNode { class="FRAMEWORK" }
	Field major:TToken
	Field dot:TToken
	Field minor:TToken
	
	Method validate()
'DebugStop
		'Local status:Int = Super.validate()
		Local valid:Int = True
		If Not major Or major.id <> TK_Alpha ; valid = False
		If Not dot Or dot.id <> TK_PERIOD ; valid = False
		If Not minor Or minor.id <> TK_Alpha ; valid = False
		If Not valid ; errors :+ [ New TDiagnostic( "Invalid module", DiagnosticSeverity.Error ) ]
		
		'	Report back worst state
		'Return Min( status, valid )
	End Method
End Type

Type TAST_Function Extends TASTCompound { class="FUNCTION" }
	Field name:TToken
	Field colon:TTOken
	Field returntype:TToken
	Field lparen:TToken
	Field def:TASTCompound
	Field rparen:TToken
	Field ending:TToken
	'Field body:TASTCompound

	' Used for debugging tree structure
	Method showLeafText:String()
		Return name.value
	End Method
	
	Method validate()
		If children.isempty() ; errors :+ [ New TDiagnostic( "Empty Construct", DiagnosticSeverity.Error ) ]
		
		'	VALIDATE RETURN TYPE

		If returntype And returntype.notin( [TK_Int,TK_String,TK_Double,TK_Float] )

'TODO: Need to check return type against SYMBOL TABLE

			Local starts:TPosition = New TPosition( returntype )
			Local ends:TPosition = New TPosition( returntype )
			ends.character :+ returntype.value.length	' Add length of token
			Local range:TRange = New TRange( starts, ends )
			errors :+ [ New TDiagnostic( "Invalid return type", DiagnosticSeverity.Warning, range ) ]
		End If

		'	VALIDATE PARENTHESIS
		'Local start:TPosition = New TPosition( fnname )
		Local range:TRange = New TRange( Self )
		If Not lparen 
			errors :+ [ New TDiagnostic( "Missing parenthesis", DiagnosticSeverity.Warning, range ) ]
		ElseIf Not rparen 
			errors :+ [ New TDiagnostic( "Missing parenthesis", DiagnosticSeverity.Warning, range ) ]
		ElseIf lparen<>rparen	' Mismatch "(" and NULL or Null and ")"
			errors :+ [ New TDiagnostic( "Mismatching parenthesis", DiagnosticSeverity.Warning, range ) ]
		End If
		
	End Method

End Type

Type TAST_Import Extends TASTNode { class="IMPORT" }
	Field major:TToken
	Field dot:TToken
	Field minor:TToken

	' Used for debugging tree structure
	Method showLeafText:String()
		Return major.value +"." + minor.value
	End Method
	
End Type

Type TAST_Include Extends TASTNode { class="INCLUDE" }
	Field file:TToken
	
	' Used for debugging tree structure
	Method showLeafText:String()
		Return file.value
	End Method
	
End Type

Type TAST_Interface Extends TASTCompound { class="INTERFACE" }
	Field name:TToken
	Field ending:TToken
			
	' Used for debugging tree structure
	Method showLeafText:String()
		Return name.value
	End Method

	Method validate()
		If children.isempty() ; errors :+ [ New TDiagnostic( "Empty Construct", DiagnosticSeverity.Error ) ]
	End Method
	
End Type

Type TAST_Method Extends TASTCompound { class="METHOD" }
	Field name:TToken
	Field colon:TTOken
	Field returntype:TToken
	Field lparen:TToken
	Field def:TASTCompound
	Field rparen:TToken
	Field ending:TToken

	' Used for debugging tree structure
	Method showLeafText:String()
		Return name.value
	End Method
	
	Method validate()
		If children.isempty() ; errors :+ [ New TDiagnostic( "Empty Construct", DiagnosticSeverity.Error ) ]
	End Method

End Type

Type TAST_Module Extends TASTCompound { class="MODULE" }
	Field major:TToken
	Field dot:TToken
	Field minor:TToken
End Type

Type TAST_ModuleInfo Extends TASTNode { class="MODULEINFO" }
	Field value:TToken
End Type

Type TAST_Rem Extends TASTNode { class="REMARK" }
	Field closing:TToken
	'Method validate() ; valid = True ; error = [] ; End Method
End Type

Type TAST_Repeat Extends TASTCompound { class="REPEAT" }
	Field ending:TToken	
End Type

Type TAST_StrictMode Extends TASTNode { class="STRICTMODE" }

	'Method validate() ; valid = True ; error = [] ; End Method

End Type

Type TAST_Struct Extends TASTCompound { class="STRUCT" }
	Field name:TToken
	Field ending:TToken
			
	' Used for debugging tree structure
	Method showLeafText:String()
		'Local name:String = structname.value
		Return name.value
	End Method
	
	Method validate()
		If children.isempty() ; errors :+ [ New TDiagnostic( "Empty Construct", DiagnosticSeverity.Error ) ]
	End Method
	
End Type

Type TAST_Type Extends TASTCompound { class="TYPE" }
	Field name:TToken
	Field extend:TToken
	Field supertype:TToken
	Field ending:TToken
		
	' Used for debugging tree structure
	Method showLeafText:String()
		Local descr:String = name.value
		If extend descr :+ "("+supertype.value+")"
		Return descr
	End Method
	
	Method validate()
		If children.isempty() ; errors :+ [ New TDiagnostic( "Empty Construct", DiagnosticSeverity.Error ) ]
	End Method
	
End Type

' A Variable Declaration
Type TAST_VARDECL Extends TASTBinary { class="VARDECL" }
End Type

' A Variable Definition
Type TAST_VARDEF Extends TASTBinary { class="VARDEF" }
End Type

Type TAST_While Extends TASTCompound { class="WHILEWEND" }
	Field ending:TToken	
End Type

Rem Type TAST_Comment Extends TASTNode

	Method New( token:TToken )
		name = "COMMENT"
		consume( token )
	End Method
	
End Type
EndRem
Rem
Type TAST_Strictmode Extends TASTNode

	'	(STRICT|SUPERSTRICT) [COMMENT] EOL
	Method New( lexer:TLexer, token:TToken Var )
		name = "STRICTMODE"
		consume( token )
		'
		' Trailing comment is a description
		token = lexer.expect( [TK_COMMENT,TK_EOL] )
		If token.id = TK_COMMENT
			' Inline comment becomes the node description
			descr = token.value
			token = lexer.Expect( TK_EOL )
		End If
		token = lexer.getNext()
	End Method
	
End Type
		
Type TAST_Framework Extends TASTNode

	'	FRAMEWORK ALPHA PERIOD ALPHA [COMMENT] EOL
	Method New( lexer:TLexer, token:TToken Var )
		name = "FRAMEWORK"
		consume( token )
		'
		' Get module name
		token = lexer.expect( TK_ALPHA )
		value = token.value
		token = lexer.expect( TK_PERIOD )
		token = lexer.expect( TK_ALPHA )
		value :+ "."+token.value
		'
		' Trailing comment is a description
		token = lexer.expect( [TK_COMMENT,TK_EOL] )
		If token.id = TK_COMMENT
			' Inline comment becomes the node description
			descr = token.value
			token = lexer.Expect( TK_EOL )
		End If
		token = lexer.getNext()
	End Method
	
End Type

EndRem
Rem
Type TAST_Module Extends TASTCompound

	'	FRAMEWORK ALPHA PERIOD ALPHA [COMMENT] EOL
	Method New( lexer:TLexer, token:TToken Var )
		name = "MODULE"
		consume( token )
		'
		' Get module name
		token = lexer.expect( TK_ALPHA )
		value = token.value
		token = lexer.expect( TK_PERIOD )
		token = lexer.expect( TK_ALPHA )
		value :+ "."+token.value
		'
		' Trailing comment is a description
		token = lexer.expect( [TK_COMMENT,TK_EOL] )
		If token.id = TK_COMMENT
			' Inline comment becomes the node description
			descr = token.value
			token = lexer.Expect( TK_EOL )
		End If
		token = lexer.getNext()
		
	End Method
	
End Type
End Rem
