
'	BLITZMAX TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspileBlitzMax Extends TTranspiler

	Method header:String()
		Return "~n'~n'"+TAB+"Transpiled from BlitzMaxNG by Scaremongers Transpiler~n'~n~n"
	End Method

	Method visit_comment:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
		Return "' "+arg.node.value+"~n"
	End Method

	Method visit_framework:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
		Local text:String = "Framework "+arg.node.value
		If arg.node.descr text :+ " ' "+arg.node.descr
		Return text + "~n"
	End Method
	
	Method visit_function:String( arg:TVisitorArg ) 'node:TAST_Function, indent:String="" )
'DebugStop
		If Not arg.node ThrowException( "Invalid node in visit_function" ) 
		Local text:String = "Function "+arg.node.value
		Local compound:TAST_Function = TAST_Function( arg.node )
		If compound.returntype
			text :+ ":"+compound.returntype.value
		EndIf
		text :+ "()"
		If arg.node.descr text :+ " ' "+arg.node.descr
		text :+ "~nEndFunction~n"
		Return text
	End Method

	Method visit_import:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
		Local text:String = "Import "+arg.node.value
		If arg.node.descr text :+ " ' "+arg.node.descr
		Return text + "~n"
	End Method
	
	Method visit_imports:String( arg:TVisitorArg ) 'node:TASTCompound, indent:String="" )
		Return visitChildren( TASTCompound(arg.node), arg.indent+TAB  )
	End Method

	Method visit_include:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
		Local text:String = "Include "+arg.node.value
		If arg.node.descr text :+ " ' "+arg.node.descr
		Return text + "~n"
	End Method

	Method visit_method:String( arg:TVisitorArg ) 'node:TAST_Method, indent:String="" )
'DebugStop
		If Not arg.node ThrowException( "Invalid node in visit_method" ) 
		Local text:String = arg.indent+"Method "+arg.node.value
		Local compound:TAST_Method = TAST_Method( arg.node )
		If compound.returntype
			text :+ ":"+compound.returntype.value
		EndIf
		text :+ "()"
		If arg.node.descr text :+ " ' "+arg.node.descr
		text :+ "~n"+arg.indent+"EndMethod~n"
		Return text
	End Method
		
	Method visit_remark:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
		Return "REM"+arg.node.value+"ENDREM~n"
	End Method

	Method visit_strictmode:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
'DebugStop
		If Not arg.node ThrowException( "Invalid node in visit_strictmode" ) 
		Local text:String = arg.node.value
		If arg.node.descr text :+ " ' "+arg.node.descr
		Return text + "~n"
	End Method

	Method visit_type:String( arg:TVisitorArg ) 'node:TAST_Type, indent:String="" )
'DebugStop
		Local text:String = "Type "+arg.node.value
		Local compound:TAST_Type = TAST_Type( arg.node )
		If compound.supertype
			text :+ " extends "+compound.supertype.value
		EndIf
		If arg.node.descr text :+ " ' "+arg.node.descr
		text :+ "~n"+visitChildren( arg.node, arg.indent+TAB )
		text :+ "EndType~n"
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
