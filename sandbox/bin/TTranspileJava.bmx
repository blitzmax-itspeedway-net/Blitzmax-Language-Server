
'	JAVA TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspileJava Extends TTranspiler

	Method header:String()
		Return "~n//~n//~tTranspiled from BlitzMaxNG by Scaremongers Transpiler~n//~n~n"
	End Method

	Method visit_comment:String( node:TASTNode, indent:String="" )
		Return "// "+node.value+"~n"
	End Method

	Method visit_framework:String( node:TASTNode, indent:String="" )
		Local text:String = "// Framework "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_function:String( node:TAST_Function, indent:String="" )
'DebugStop
		If Not node ThrowException( "Invalid node in visit_function" ) 
		Local text:String = "static "
		If node.returntype
			text = node.returntype.value + " "
		Else
			text = "void "
		EndIf
		text :+ node.value+"() {~n"
		If node.descr text :+ "~t// "+node.descr +"~n"
		text :+ "}~n"
		Return text
	End Method

	Method visit_import:String( node:TASTNode, indent:String="" )
		Local text:String = "// Import "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_imports:String( node:TASTCompound, indent:String="" )
		Return visitChildren( node )
	End Method

	Method visit_include:String( node:TASTNode, indent:String="" )
		Local text:String = "// Include "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_remark:String( node:TASTNode, indent:String="" )
		Return "/*"+node.value+"*/~n"
	End Method

	Method visit_strictmode:String( node:TASTNode, indent:String="" )
		Return ""
	End Method

	Method visit_type:String( node:TAST_Type, indent:String="" )
		Local text:String = "class "+node.value 
		If node.supertype
			text :+ " extends "+node.supertype.value
		EndIf
		text :+ " {~n"
		If node.descr text :+ "~t// "+node.descr +"~n"
		text :+ visitChildren( node, "\t" )
		text :+ "~n}~n"
		Return text
	End Method
		
End Type
