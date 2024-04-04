
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
	Field filter:String[]	' Filters the nodes that are allowed

Rem	Method visit:String( node:TASTNode, prefix:String="visit", indent:String="" )
'DebugStop
		If Not node ThrowException( "Cannot visit null node" ) 
		'If node.name = "" invalid()	' Leave this to use "visit_" method
		
		' Use Reflection to call the visitor method (or an error)
'DebugStop
		Local this:TTypeId = TTypeId.ForObject( Self )
		' The visitor function is defined in metadata 
		Local class:String = this.metadata( "class" )
		If class = "" 
			If node.classname = "" ; Return ""
			class = node.classname
		End If
		Local methd:TMethod = this.FindMethod( prefix+"_"+class )
		If methd
			Local Text:String = String( methd.invoke( Self, [New TVisitorArg(node,indent)] ))
			Return Text
		EndIf
		If exception_on_missing_method ; exception( prefix+"_"+class )
		Return ""
	End Method
End Rem

	Method in:Int( needle:String, haystack:String[] )
		For Local i:Int = 0 Until haystack.length
			If haystack[i]=needle ; Return True
		Next
		Return False
	End Method

	Method visit( node:TASTNode, mother:Object, prefix:String = "visitor" )
		If Not node ; Return
		
		' Use Reflection to call the visitor method (or an error)
		Local nodeid:TTypeId = TTypeId.ForObject( node )
		' The visitor function is defined in metadata
		Local class:String = nodeid.metadata( "class" )
		If class = "" 
			If node.classname = "" ; Return
			class = node.classname
		End If
'DebugStop	
		' Filter nodes
		If filter.length>0 And Not in( Lower(class), filter ) 
'DebugLog( "Filtered '"+class+"'")
			Return
		End If

		' Use Reflection to call the visitor method (or an error)
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( prefix+"_"+class )
		If methd
			'DebugLog( "Visiting "+prefix+"_"+class+"()" )
			methd.invoke( Self, [New TGift(node,mother,prefix)] )
		Else		
			DebugLog( "Visitor "+prefix+"_"+class+"() is not defined" )
		EndIf

	End Method

	'Method visitChildren:String( node:TASTNode, prefix:String, indent:String="" )
	'	Local Text:String
	'	Local compound:TASTCompound = TASTCompound( node )
'DebugStop
	'	For Local child:TASTNode = EachIn compound.children
	'		Text :+ visit( child, prefix, indent )
	'	Next
	'	Return Text
	'End Method
	
	Method visitChildren( node:TASTNode, mother:Object, prefix:String )
		Local family:TASTCompound = TASTCompound( node )
		If Not family ; Return
		If family.children.isEmpty() ; Return

		For Local child:TASTNode = EachIn family.children
			visit( child, mother, prefix )
		Next
	End Method
	
	' This is called when node doesn't have metadata or a name...
	Method visit_:String( node:TASTNode, indent:String="" )
		ThrowException( "Node '"+node.value+"' has no name!" )
	End Method
	
	Method exception( nodename:String )
		ThrowException( "Method "+nodename+"() does not exist" )
	End Method
	
End Type
