
'	Symbol Table
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TSymbolTable
	Field list:TList = New TList()

	Method Add( symbol:TSymbol, scope:String, name:String, vartype:String="" )
		list.addlast( New TSymbolTableRow( symbol, scope, name, vartype ) )
	End Method
	
	Method Search:TSymbol( name:String )
	End Method
	
	Method GetSymbolAt:TSymbol( line:Int, pos:Int )
	End Method

End Type

Type TSymbolTableRow
	Field line:Int, pos:Int		' Where this is within the source file
	Field name:String			' Name of type, function, variable etc
	Field symtype:String		' function, method, type, int, string, double etc.
	Field scope:String			' extern, function:name, method:name, global
	Field class:String			' function, method, type, field, local, global, include 
	Field description:String	' Taken directly from pre-defintion comment or line comment
	Field defintion:String		' The definition taken from the source code
	'
	Method New( symbol:TSymbol, scope:String, name:String, vartype:String="" )
		Self.line = symbol.line
		Self.pos = symbol.pos
		Self.scope = scope
		Self.name = name
		Self.symtype = vartype
	End Method
End Type

Rem



end REM