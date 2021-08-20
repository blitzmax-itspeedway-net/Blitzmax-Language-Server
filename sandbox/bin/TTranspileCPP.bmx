
'	C++ TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspileCPP Extends TTranspiler

	Method header:String()
		Return "~n//~n//~tTranspiled from BlitzMaxNG by Scaremongers Transpiler~n//~n~n"
	End Method

	Method visit_strictmode:String( node:TASTNode )
'DebugStop
		'If Not node ThrowException( "Invalid node in strictmode" ) 
		'Local text:String = node.value
		'If node.descr text :+ " ' "+node.descr
		Return ""	'text + "~n"
	End Method

	Method visit_comment:String( node:TASTNode )
'DebugStop
		If node.tokenid = TK_REM
			Return "/*"+node.value+"*/~n"
		Else	' TK_COMMENT
			Return "// "+node.value+"~n"
		End If
	End Method

End Type
