
'   BLITZMAX LANGUAGE SERVER
'   (c) Copyright Si Dunford, October 2021, All Right Reserved

' A Gift is an Argument brought by a Visitor... ;) ha ha... 
Type TGift
	Field node:TASTNode
	Field data:Object
	Field prefix:String
	Method New( node:TASTNode, data:Object, prefix:String )
		Self.node = node
		Self.data = data
		Self.prefix = prefix
	End Method
EndType

Type TJSONGift Extends TGift
	Field node:TASTNode
	Field data:JSON
	Field prefix:String
	Method New( node:TASTNode, data:JSON, prefix:String )
		Self.node = node
		Self.data = data
		Self.prefix = prefix
	End Method
EndType