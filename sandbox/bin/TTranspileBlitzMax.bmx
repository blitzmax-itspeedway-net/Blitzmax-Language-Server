
'	BLITZMAX TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspileBlitzMax Extends TTranspiler

	Method header:String()
		Return "~n'~n'~tTranspiled from BlitzMaxNG by Scaremongers Transpiler~n'~n~n"
	End Method

	Method visit_comment:String( node:TASTNode, indent:String="" )
		Return "' "+node.value+"~n"
	End Method

	Method visit_framework:String( node:TASTNode, indent:String="" )
		Local text:String = "Framework "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_function:String( node:TAST_Function, indent:String="" )
'DebugStop
		If Not node ThrowException( "Invalid node in visit_function" ) 
		Local text:String = "Function "+node.value
		If node.returntype
			text :+ ":"+node.returntype.value
		EndIf
		text :+ "()"
		If node.descr text :+ " ' "+node.descr
		text :+ "~nEndFunction~n"
		Return text
	End Method

	Method visit_import:String( node:TASTNode, indent:String="" )
		Local text:String = "Import "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_imports:String( node:TASTCompound, indent:String="" )
		Return visitChildren( node )
	End Method

	Method visit_include:String( node:TASTNode, indent:String="" )
		Local text:String = "Include "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_remark:String( node:TASTNode, indent:String="" )
		Return "REM"+node.value+"ENDREM~n"
	End Method

	Method visit_strictmode:String( node:TASTNode, indent:String="" )
'DebugStop
		If Not node ThrowException( "Invalid node in visit_strictmode" ) 
		Local text:String = node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method

	Method visit_type:String( node:TAST_Type, indent:String="" )
		Local text:String = "Type "+node.value
		If node.supertype
			text :+ " extends "+node.supertype.value
		EndIf
		If node.descr text :+ " ' "+node.descr
		text :+ visitChildren( node )
		text :+ "~nEndType~n"
		Return text
	End Method

Rem	Method visit_binop node:TAbSynTree )
		If Not node ThrowException( "Invalid node in binaryoperator" ) 
		Print "BINARY OPERATION"
	
		Select node.token.value
		Case "+"	; 'Local x:Int = visit( node.L ) + visit( node.R )
		Case "-"	
		Case "*"
		Case "/"
		End Select
		
	End Method
	End Rem
End Type
