
'	DEFINITION TREE
'	BlitzMax Language Server
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	This file contains the root node for all source file defintions

Type TDefinition
	Global root:TMap = New TMap()

	Function addSourceFile( index:String )
	End Function

	Function RemoveFile( index:String )
	End Function

	Function addImports( index:String, tree:TDefinition )
	End Function

	Function search:TDefinition( criteria:String )
	End Function

	Method New()
	End Method

End type