
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

' A Variable Arguments
Rem
	FUNCTION/METHOD
		.name
		.arguments:TAST_Arguments		<---
			":"...
				lnode	-> Name of the Argument
				rnode 	-> Argument type or TAST_Function for function variables.
	See also TAST_VarDef and TAST_Assignment
End Rem
Type TAST_Argument Extends TASTCompound { class="ARGUMENTS" }
	Field name:TToken 
	Field colon:TToken
	Field vartype:TToken
	Field func:TAST_Function	' Function variables
End Type

' A Variable Assigment
'	NODE WILL BE ONE OF THE FOLLOWING:
'		TK_Local, TK_Global, TK_Field, TK_COnst
'		lnode will be of type TAST_VARDEF - BEFORE the equals sign
'		rnode will be the expression AFTER the equals sign (or null if undefined)
Type TAST_Assignment Extends TASTBinary { class="ASSIGNMENT" }

	Method New( token:TToken )
		consume( token )
		' Need to do this here or they are initialised with $000000000 and null detection fails!
		lnode = Null
		rnode = Null
	End Method

	Method validate()
Rem
	* Const must have an EQUALS and an expression
	* Const canot be a funnction type
End Rem
	End Method
	
End Type

' Node used to represent a condition
'	Node itself will usually be an "EQUAL", but could be a NULL in a "IF TRUE" scenario
'	lnode and rnode are the two expressions to be evaluated
Type TAST_Condition Extends TASTBinary { class="CONDITION" }
End Type

Type TAST_Comment Extends TASTNode { class="COMMENT" }
'	Method validate() ; valid = True ; error = [] ; End Method
End Type

' IF has a condition, body (children) and an ELSE (otherwise)
' The Else (otherwise), could be another IF node
Type TAST_ElseIf Extends TAST_If { class="ELSEIF" }
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
	Field arguments:TASTCompound		' Arguments
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

' IF has a condition, body (children) and an ELSE (otherwise)
' The Else (otherwise), could be another IF node
Type TAST_If Extends TASTCompound { class="IF" }
	Field condition:TASTNode
	Field otherwise:TASTNode	' ELSE (TAST_Compound) / ELSEIF (TAST_If)
	Field ending:TToken	
	
	' Used for debugging tree structure
	'Method showLeafText:String()
	'	Return "(CONDITION)"
	'End Method

	' Used for debugging tree structure
	Method reveal:String( indent:String = "" )
'DebugStop
		Local block:String = ["!","."][errors.length>0]
		block :+ " " + pos()[..9] + " " + indent.length + indent+getname() + "~n"
		'block :+ " " + Trim(showLeafText()) + "~n"
		'If value<>"" block :+ " "+Replace(value,"~n","\n")
		'block :+ "~n"
		If condition
			block :+ condition.reveal( indent+" " )
		End If
		block :+ "  " + pos()[..9] + " " + indent.length + indent+"THEN~n"
		For Local child:TASTNode = EachIn children
'Print( child.classname +":"+child.tokenid+"="+child.value )
'If child.tokenid=645 DebugStop
			block :+ child.reveal( indent+" " )
		Next
		If otherwise
'DebugStop
			block :+ otherwise.reveal( indent )
		End If
		Return block
	End Method
		
	' Walk the tree to find left-most leaf
	Method walkfirst:TASTNode()
		If condition Return condition.walkFirst()
		Return Self
	End Method
	
	Method inorder:Object( eval:Object( node:TASTNode, data:Object, options:Int ), data:Object, options:Int = 0 )
		If data ; data = eval( Self, data, options )
		If data And condition ; data = condition.inorder( eval, data, options )
		If children
			For Local child:TASTNode = EachIn children
				If data ; data = child.inorder( eval, data, options )
			Next
		End If
		If data And otherwise ; data = otherwise.inorder( eval, data, options )
		Return data
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
	Field arguments:TASTCompound
	Field rparen:TToken
	Field ending:TToken

	' Used for debugging tree structure
	Method showLeafText:String()
		If name ; Return name.value
		Return "Undefined"
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

Type TAST_Return Extends TASTNode { class="RETURN" }
	Field expr:TASTNode
	'Method validate() ; valid = True ; error = [] ; End Method
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

' A Variable Definition
'	NODE WILL BE TK_Colon
'		lnode = Variable Name (BEFORE COLON)
'		rnode = Variable Type (AFTER COLON)
Type TAST_VarDef Extends TASTNode { class="VARDEF" }
	Field name:TToken
	Field colon:TToken
	Field vartype:TToken
	Field func:TAST_Function	' Function variables
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
