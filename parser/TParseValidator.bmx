
'	BLITZMAX LANGUAGE SERVER
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved
'	Parser validation

Type TParseValidator Extends TVisitor
	Field ast:TASTNode
	Field valid:Int = False

	Method New( ast:TASTNode )
		Self.ast = ast
	End Method
	
	Method run:Int()
		If Not ast Return False
		Return (ast.errors<>Null)
	End Method
	
End Type