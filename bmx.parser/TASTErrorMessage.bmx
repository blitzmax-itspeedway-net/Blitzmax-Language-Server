
'	ERROR MESSAGE FOR AST NODES
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TASTErrorMessage
	Field message : String				' The diagnostic's message

    Method reveal:string()
        return message
    End Method
End Type
