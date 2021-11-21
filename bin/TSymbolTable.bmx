
'	SYMBOL TABLE
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Rem NOTES

	We need to include an AST visitor that extracts a symbol table from the AST
	Probably use the "short visitor" (paperboy)
	
	Variable scopes.
	Scopes are created by different type, for example a function creates a new scope.
	Include adds variable to a top level scope, under "program".
	Import creates a new scope under filename, or pehaps module.
	The scope should probably be the AST node itself, although the AST will not exist when the 
	scope is saved and the file is not open, so we need to reference it anotehr way.
	We could use a string of token ID's, (100|123|111) or a string of token values (Program|Function|xyz)
	Alternativey we could generate GUID's for each scope in the parser and use that.
	
	The issue occurs when we want to lookup a symbol. How do we find the scope....
	textDocument will have an AST at this point (Or we have to geenrate one).
	Using the cursor, we identify the current symbol in the AST tree and generate a scope from it.
	(Instead of identifying the symbol in the source text as we do now).
	Scanning the AST for a position should be simple. Basically we search the node children until we 
	find the range, and continue to a leaf.
	
End Rem

Type TSymbolTable
	
	Field fileuri:String 
	Field valid:Int = False
	'Field db:TDBConnection
	
'	Field list:TList = New TList()
'
'	Method Add( token:TToken, scope:String, name:String, vartype:String="" )
'		list.addlast( New TSymbolTableRow( token, scope, name, vartype ) )
'	End Method
'	
'	Method Search:TToken( name:String )
'	End Method
'	
'	Method GetTokenAt:TToken( line:Int, pos:Int )
'	End Method

	Method New( fileuri:String )
		'Self.fileuri = fileuri
		'db = LoadDatabase( "SQLITE", fileuri )
		'If db And db.isOpen()
		'	CreateIfRequired()
		'End If
	End Method
	
	Method CreateIfRequired()
		Local SQL:String
		
		SQL =	"CREATE TABLE IF NOT EXISTS symtable(" +..
				"id INTEGER PRIMARY KEY AUTOINCREMENT," +..
				");"
		'db.executeQuery( SQL )
		
		SQL =	"CREATE TABLE IF NOT EXISTS properties(" +..
				"key INTEGER PRIMARY KEY," +..
				"value VARCHAR(50) NOT NULL DEFAULT ''" +..
				");"
		'db.executeQuery( SQL )
		
		' Default properties
		'SQL =	"INSERT OR IGNORE INTO properties( 0, '' );"	' FILEDATE
		'db.executeQuery( SQL )
		
	End Method
	
End Type

'Type TSymbolTableRow
'	Field line:Int, pos:Int		' Where this is within the source file
'	Field name:String			' Name of type, function, variable etc
'	'Field symtype:String		' function, method, type, int, string, double etc.
'	Field scope:String			' extern, function:name, method:name, global
'	Field class:String			' function, method, type, field, local, global, include 
'	Field description:String	' Taken directly from pre-defintion comment or line comment
'	Field defintion:String		' The definition taken from the source code
'	'
'	Method New( token:TToken, scope:String, name:String, class:String="" )
'		Self.line = token.line
'		Self.pos = token.pos
'		Self.scope = scope
'		Self.name = name
'		Self.class = class
'	End Method
'End Type

Rem



End Rem
