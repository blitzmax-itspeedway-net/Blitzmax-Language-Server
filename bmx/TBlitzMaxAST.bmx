
'	BlitzMax Abstract Syntax Tree
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	17 AUG 21	Initial version
'	V1.1	22 AUG 21	Added TAST_Function(), TAST_Method() and TAST_Type()

' Diagnostics node used when an optional token is missing
Type TASTMissingOptional Extends TASTNode { class="missingoptional" }
	
	' descr field should hold some detail used by the language server to
	' help user recreate this, or force it
	' default value needs to be included so it can be "fixed"

	Method New( name:String, value:String )
'DebugStop
		Self.name   = name
		Self.value  = value
		'Self.errors = New TList()
		Self.status = AST_NODE_WARNING
		'Local range:TRange = New TRange( 0,0,0,0 )
		'errors :+ [ New TDiagnostic( "'"+name+"' is recommended", DiagnosticSeverity.Hint, range ) ]
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
	Method New( name:String, value:String )
		Self.name  = name
		Self.value = value
	End Method
End Type

' Diagnostics node used when an error has been found and a node has been skipped
Type TAST_Skipped Extends TASTError { class="skipped" }
	
	' descr field should hold some detail used by the language server to
	' help user recreate this, or force it
	' default value needs to be included so it can be "fixed"

	Method New( name:String, value:String )
		Self.name  = name
		Self.value = value
		'Self.valid = False
	End Method

	Method New( token:TToken, error:String )
		consume( token )
		errors :+ [ New TDiagnostic( error, DiagnosticSeverity.Warning ) ]
		'Self.valid = False
	End Method	
		
End Type

' This AST Node is used for LOCAL, GLOBAL and FIELD definitions
'Type TAST_VariableDeclaration Extends TASTBinary { class="VariableDeclaration" }
'End Type

Type TAST_Comment Extends TASTNode { class="COMMENT" }
'	Method validate() ; valid = True ; error = [] ; End Method
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

Type TAST_Function Extends TASTNode { class="FUNCTION" }
	Field fnname:TToken
	Field colon:TTOken
	Field returntype:TToken
	Field lparen:TToken
	Field def:TASTCompound
	Field rparen:TToken
	Field ending:TToken
	Field body:TASTCompound

	' Used for debugging tree structure
	Method showLeafText:String()
		Return fnname.value
	End Method
	
	'Method validate()
		'Super.validate()
'DebugStop
		
		
		'	Report back worst state
		'Return Min( status, valid )
	'End Method
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

Type TAST_Method Extends TASTCompound { class="METHOD" }
	Field methodname:TToken
	Field colon:TTOken
	Field returntype:TToken
	Field lparen:TToken
	Field def:TASTCompound
	Field rparen:TToken
	Field ending:TToken

	' Used for debugging tree structure
	Method showLeafText:String()
		Return methodname.value
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

Type TAST_StrictMode Extends TASTNode { class="STRICTMODE" }

	'Method validate() ; valid = True ; error = [] ; End Method

End Type

Type TAST_Type Extends TASTCompound { class="TYPE" }
	Field typename:TToken
	Field extend:TToken
	Field supertype:TToken
	Field ending:TToken
		
	' Used for debugging tree structure
	Method showLeafText:String()
		Local name:String = typename.value
		If extend name :+ "("+supertype.value+")"
		Return name
	End Method
	
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
