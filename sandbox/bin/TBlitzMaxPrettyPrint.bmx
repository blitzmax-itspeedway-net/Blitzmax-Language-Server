
'	BLITZMAX PRETTY PRINTER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TBlitzMaxPrettyPrint Extends TVisitor

	Field ast:TASTNode
	
	Method New( ast:TASTNode )
		Self.ast = ast
	End Method
	
	' Create source code from the AST
	Method run:String()
		'Local start:TASTNode = ast.walkfirst()
'DebugStop
		'Local code:String
		Local text:String = visit( ast )
		Return text
	End Method
	
	'Method walk:String( node:TASTNode )
	
	' Not sure how to debug this yet...!
	' Maybe dump the syntax tree and definition table?
	Method reveal:String()
	End Method
	
	' ABSTRACT METHODS
	' Not all of them are required by the Language server, but "bcc" will need them

	Method visit_program:String( node:TASTCompound )
'DebugStop
		Local text:String
		For Local child:TASTNode = EachIn node.children
			text :+ visit( child )
		Next
		Return text
	End Method
	
	Method visit_strictmode:String( node:TASTNode )
'DebugStop
		If Not node ThrowException( "Invalid node in strictmode" ) 
		Local text:String = node.token.class
		If node.descr text :+ " ' "+node.descr
		Return text + "~n"
	End Method

	Method visit_linecomment:String( node:TASTNode )
'DebugStop
		Return "' "+node.descr+"~n"
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
