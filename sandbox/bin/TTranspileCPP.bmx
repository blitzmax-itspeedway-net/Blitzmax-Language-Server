
'	C++ TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspileCPP Extends TTranspiler

	Method header:String()
		Return "~n//~n//~tTranspiled from BlitzMaxNG by Scaremongers Transpiler~n//~n~n"
	End Method

	Method visit_comment:String( node:TASTNode )
		Return "// "+node.value+"~n"
	End Method

	Method visit_framework:String( node:TASTNode )
		Local text:String = "// Framework "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_function:String( node:TAST_Function )
'DebugStop
		If Not node ThrowException( "Invalid node in visit_function" ) 
		Local text:String
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
	
	Method visit_import:String( node:TASTNode )
		Local text:String = "// Import "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
	
	Method visit_imports:String( node:TASTCompound )
		Local text:String
		For Local child:TASTNode = EachIn node.children
			text :+ visit_import( child )
		Next
		Return text
	End Method

	Method visit_include:String( node:TASTNode )
		Local text:String = "// Include "+node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method
		
	Method visit_remark:String( node:TASTNode )
		Return "/*"+node.value+"*/~n"
	End Method

	Method visit_strictmode:String( node:TASTNode )
'DebugStop
		'If Not node ThrowException( "Invalid node in strictmode" ) 
		'Local text:String = node.value
		'If node.descr text :+ " ' "+node.descr
		Return ""	'text + "~n"
	End Method

End Type
