
'	TRANSPILER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TTranspiler Extends TVisitor

	Field ast:TASTNode
	Field TAB:String = "~t"
	
	Method New( ast:TASTNode, tab:String="~t" )
		Self.ast = ast
		Self.TAB = tab
	End Method
	
	' Create source code from the AST
	Method run:String()
'DebugStop
		Local text:String = visit( ast )
		Return text
	End Method
	
	Method reveal:String()
	End Method
	
	Method header:String() Abstract
	
	' STATIC METHODS
		
	Method visitChildren:String( node:TASTNode, indent:String="" )
		Local text:String
		Local compound:TASTCompound = TASTCompound( node )
'DebugStop
		For Local child:TASTNode = EachIn compound.children
			text :+ visit( child, indent )
		Next
		Return text
	End Method

	' ABSTRACT METHODS

	Method visit_program:String( arg:TVisitorArg ) 'node:TASTCompound, indent:String="" )
'DebugStop
		Local text:String = header()
		text :+ visitChildren( arg.node, "" )
		Return text
	End Method

	Method visit_EOL:String( arg:TVisitorArg ) 'node:TASTNode, indent:String="" )
		Return "~n"
	End Method
	
End Type
