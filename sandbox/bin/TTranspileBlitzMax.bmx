
'	BLITZMAX TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspileBlitzMax Extends TTranspiler

	Method header:String()
		Return "~n'~n'~tTranspiled from BlitzMaxNG by Scaremongers Transpiler~n'~n~n"
	End Method

	Method visit_strictmode:String( node:TASTNode )
'DebugStop
		If Not node ThrowException( "Invalid node in strictmode" ) 
		Local text:String = node.value
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method

	Method visit_comment:String( node:TASTNode )
'DebugStop
		If node.tokenid = TK_REM
			Return "REM"+node.value+"ENDREM~n"
		Else	' TK_COMMENT
			Return "' "+node.value+"~n"
		End If
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
