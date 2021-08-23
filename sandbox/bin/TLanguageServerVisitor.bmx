
'	LANGUAGE SERVER AST VISITOR
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	22 AUG 21	Initial version

Type TLanguageServerVisitor Extends TVisitor

	Field ast:TASTNode
	Field filename:String
	
	Method New( ast:TASTNode )
		Self.ast = ast
	End Method
	
	Method run() ; End Method
	
	Method reveal:String() ; End Method
	
	Method getOutline:String( filename:String )
		Self.filename = filename
		' Walk the AST, returning only structural elements
		exception_on_missing_method = False
		Local text:String = visit( ast, "outline" )
		Return text
	End Method
	
	Method outline_program:String( arg:TVisitorArg )
		Local text:String = filename + "~n"
		text :+ visitChildren( arg.node, "outline", "  " )
		Return text
	End Method
	Method outline_function:String( arg:TVisitorArg )
		Local text:String = arg.indent+arg.node.value
		Local compound:TAST_Function = TAST_Function( arg.node )
		If compound.returntype ; text :+ ":"+compound.returntype.value
		Return text + "()~n"
	End Method	
	Method outline_method:String( arg:TVisitorArg ) 
		Local text:String = arg.indent+arg.node.value
		Local compound:TAST_Method = TAST_Method( arg.node )
		If compound.returntype ; text :+ ":"+compound.returntype.value
		Return text + "()~n"
	End Method
	Method outline_type:String( arg:TVisitorArg )
		Local text:String = arg.indent+arg.node.value 
		Local compound:TAST_Type = TAST_Type( arg.node )
		If compound.supertype ; text :+ " Extends "+compound.supertype.value
		Return text + "~n"+visitChildren( arg.node, "outline", arg.indent+"  " )
	End Method

End Type