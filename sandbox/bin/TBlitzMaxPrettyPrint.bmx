
'	BLITZMAX PRETTY PRINTER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TLangServ Extends TVisitor

	Field parser:TParser
	Field tree:TAbSynTree
	
	Method New( parser:TParser )
		Self.parser = parser
	End Method
	
	Method run()
		' Perform the actual Parsing here
		parser.parse()
		tree = parser.ast
		' Now call the visitor to process the tree
		visit( tree )
	End Method
	
	' Not sure how to debug this yet...!
	' Maybe dump the syntax tree and definition table?
	Method reveal:String()
	End Method
	
	' ABSTRACT METHODS
	' Not all of them are required by the Language server, but "bcc" will need them
	
	Method visit_strictmode:String( node:TAST_strictmode )
		'If Not node ThrowException( "Invalid node in strictmode" ) 
		Local line:String = node.token.class
		If node.comment line :+ "' "+comment
		Return line
	End Method

	Method visit_comment:String( node:TAbSynTree )
		'If Not node ThrowException( "Invalid node in strictmode" ) 
		Print "' "+node.token.value
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
