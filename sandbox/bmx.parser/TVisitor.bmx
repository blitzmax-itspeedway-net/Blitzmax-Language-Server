
'	ABSTRACT SYNTAX TREE / VISITOR
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved
'
'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version
'	V1.1	23 AUG 21	Exception on missing method is optional

' Argument passed to visitor nodes
Type TVisitorArg
	Field node:TASTNode
	Field indent:String
	
	Method New( node:TASTNode, indent:String )
		Self.node = node
		Self.indent = indent
	End Method
	
	'Method tab:TVisitorArg()
	'	Self.indent :+ "~t"
	'	Return Self
	'End Method
End Type

' A Visitor is a process that does something with the data
' A Compiler or Interpreter are the usual candidates, but
' you can use them to convert or process data in a natural way

' The Visitor uses reflection to process the Abstract Syntax Tree
Type TVisitor

	Field exception_on_missing_method:Int = True

	Method visit:String( node:TASTNode, prefix:String="visit", indent:String="" )
'DebugStop
		If Not node ThrowException( "Cannot visit null node" ) 
		'If node.name = "" invalid()	' Leave this to use "visit_" method
		
		' Use Reflection to call the visitor method (or an error)
'DebugStop
		Local this:TTypeId = TTypeId.ForObject( Self )
		' The visitor function is either defined in metadata or as node.name
		Local class:String = this.metadata( "class" )
		If class = "" class = node.name
		Local methd:TMethod = this.FindMethod( prefix+"_"+class )
		If methd
			Local text:String = String( methd.invoke( Self, [New TVisitorArg(node,indent)] ))
			Return text
		EndIf
		If exception_on_missing_method ; exception( prefix+"_"+class )
		Return ""
	End Method

	Method visitChildren:String( node:TASTNode, prefix:String, indent:String="" )
		Local text:String
		Local compound:TASTCompound = TASTCompound( node )
'DebugStop
		For Local child:TASTNode = EachIn compound.children
			text :+ visit( child, prefix, indent )
		Next
		Return text
	End Method
	
	' This is called when node doesn't have metadata or a name...
	Method visit_:String( node:TASTNode, indent:String="" )
		ThrowException( "Node '"+node.value+"' has no name!" )
	End Method
	
	Method exception( nodename:String )
		ThrowException( "Method "+nodename+"() does not exist" )
	End Method
	
End Type
