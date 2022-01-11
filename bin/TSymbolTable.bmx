
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

	Field data:TList
	Field filepath:String 		' The file containing this symbol
'	Field valid:Int = False
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

	' Extract symbols from AST for given uri
	Method New( ast:TAstNode )
	
		'DebugStop
		Local options:Int = 0
		Local visitor:TSymbolTableVistor = New TSymbolTableVistor( ast, options )
		data = visitor.run( "" )
	
	End Method

	Method reveal:String()
DebugStop
		Local results:String = "SCOPE"[..16] + "NAME"[..16] + "KIND"[..16] + "LOCATION"[..16] + "URI~n"
		For Local row:TSymbolTableRow = EachIn data
			results :+ row.reveal()+"~n"
		Next
		Return results
	End Method

End Type

Type TSymbolTableVistor Extends TVisitor

	' DATA contains the scope

	Field ast:TASTNode
	Field options:Int
	Field symTable:TList
	Field count:Int = 0
	Field uri:String		' File we are visiting
		
	Method New( ast:TASTNode, options:Int )
		Self.ast = ast
		Self.filter = ["assignment","enum","fornext","function","interface","method","program","repeat","struct","type","vardecl","whilewend"]
		DebugLog( "## VISITOR OPTIONS: "+options )
		Self.options = options
	End Method

	Method run:TList( uri:String )
		Self.uri = uri
		'Local J:JSON = New JSON( JSON_ARRAY )	' DocumentSymbol[]
		symTable = New TList()
		visit( ast, ".", "symtable" )
		'DebugLog( "SYMTABLE:~n"+J.prettify() )
		Return symTable
	End Method

	Method counter:String()
		count :+ 1
		Return ("00000"+count)[..5]
	End Method
Rem
	Method visit( node:TASTNode, mother:Object, prefix:String = "symtable" )
		If Not node ; Return
		
		' Use Reflection to call the visitor method (or an error)
		Local nodeid:TTypeId = TTypeId.ForObject( node )
'DebugStop	
		' The visitor function is defined in metadata
		Local class:String = nodeid.metadata( "class" )
		If class = "" 
			If node.classname = "" ; Return
			class = node.classname
		End If
'DebugStop
		' Filter nodes
		If Not in( Lower(class), FILTER ) 
'DebugLog( "Filtered '"+class+"'")
			Return
		End If

		' Use Reflection to call the visitor method (or an error)
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( prefix+"_"+class )
		If methd
			methd.invoke( Self, [New TGift(node,mother,prefix)] )
		Else
		
DebugLog( "TSymboltable."+prefix+"_"+class+"() is not defined" )
			' Add to mother node
			'mother.addLast( documentSymbol )
		EndIf

	End Method

	Method visitChildren( node:TASTNode, mother:Object, prefix:String )
		Local family:TASTCompound = TASTCompound( node )
		If Not family ; Return
		If family.children.isEmpty() ; Return

		For Local child:TASTNode = EachIn family.children
			visit( child, mother, prefix )
		Next
	End Method
End Rem

	Method symtable_ASSIGNMENT( arg:TGift )
		Local node:TAST_Assignment = TAST_Assignment( arg.node )
'DebugStop
		If Not node Or Not node.lnode ; Return
		Local lnode:TAST_VarDef = TAST_VarDef( node.lnode )
		If Not lnode Or Not lnode.name Or Not lnode.vartype ; Return
		Local scope:String = String( arg.data )
'DebugStop
		Select node.tokenId
		Case TK_Const
			Local location:TLocation = New TLocation( uri, lnode.name )
			symTable.addlast( New TSymbolTableRow( lnode.name.value, SymbolKind._Constant.ordinal(), location, scope ) )
		Case TK_Field
			Local location:TLocation = New TLocation( uri, lnode.name )
			symTable.addlast( New TSymbolTableRow( lnode.name.value, SymbolKind._Field.ordinal(), location, scope ) )
		Case TK_Global
			Local location:TLocation = New TLocation( uri, lnode.name )
			symTable.addlast( New TSymbolTableRow( lnode.name.value, SymbolKind._Variable.ordinal(), location, scope ) )
		Case TK_Local
			Local location:TLocation = New TLocation( uri, lnode.name )
			symTable.addlast( New TSymbolTableRow( lnode.name.value, SymbolKind._Variable.ordinal(), location, scope ) )
		End Select
	End Method

	Method symtable_ENUM()( arg:TGift )
		Local node:TAST_Enum = TAST_Enum( arg.node )
		If node And node.name 
			Local scope:String = String( arg.data )
			Local location:TLocation = New TLocation( uri, node.name )
			symTable.addlast( New TSymbolTableRow( node.name.value, SymbolKind._Enum.ordinal(), location, scope ) )
			visitChildren( arg.node, scope+node.name.value+"." , arg.prefix )
		End If
	End Method

	Method symtable_FORNEXT( arg:TGift )
		Local node:TAST_For = TAST_For( arg.node )
DebugLog( "FORNEXT is not fully implemented" )
		visitChildren( arg.node, arg.data, arg.prefix )
	End Method

	Method symtable_FUNCTION()( arg:TGift )
		Local node:TAST_Function = TAST_Function( arg.node )
		If node And node.name 
			Local scope:String = String( arg.data )
			Local location:TLocation = New TLocation( uri, node.name )
			symTable.addlast( New TSymbolTableRow( node.name.value, SymbolKind._Function.ordinal(), location, scope ) )
			visitChildren( arg.node, scope+node.name.value+"." , arg.prefix )
		End If
	End Method

	Method symtable_INTERFACE()( arg:TGift )
		Local node:TAST_Interface = TAST_Interface( arg.node )
		If node And node.name 
			Local scope:String = String( arg.data )
			Local location:TLocation = New TLocation( uri, node.name )
			symTable.addlast( New TSymbolTableRow( node.name.value, SymbolKind._Interface.ordinal(), location, scope ) )
			visitChildren( arg.node, scope+node.name.value+"." , arg.prefix )
		End If
	End Method

	Method symtable_METHOD()( arg:TGift )
		Local node:TAST_Method = TAST_Method( arg.node )
		If node And node.name 
			Local scope:String = String( arg.data )
			Local location:TLocation = New TLocation( uri, node.name )
			symTable.addlast( New TSymbolTableRow( node.name.value, SymbolKind._Method.ordinal(), location, scope ) )
			visitChildren( arg.node, scope+node.name.value+"." , arg.prefix )
		End If
	End Method

	' This is the entry point of our appliciation
	Method symtable_PROGRAM( arg:TGift )
		visitChildren( arg.node, arg.data, arg.prefix )
	End Method

	' Repeat will be ignored, we are only interested in descendents
	Method symtable_REPEAT( arg:TGift )
		Local scope:String = String( arg.data )
		visitChildren( arg.node, scope+counter()+".", arg.prefix )
	End Method

	Method symtable_STRUCT()( arg:TGift )
		Local node:TAST_Struct = TAST_Struct( arg.node )
		If node And node.name 
			Local scope:String = String( arg.data )
			Local location:TLocation = New TLocation( uri, node.name )
			symTable.addlast( New TSymbolTableRow( node.name.value, SymbolKind._Struct.ordinal(), location, scope ) )
			visitChildren( arg.node, scope+node.name.value+"." , arg.prefix )
		End If
	End Method

	Method symtable_TYPE()( arg:TGift )
		Local node:TAST_Type = TAST_Type( arg.node )
		If node And node.name 
			Local scope:String = String( arg.data )
			Local location:TLocation = New TLocation( uri, node.name )
			symTable.addlast( New TSymbolTableRow( node.name.value, SymbolKind._Class.ordinal(), location, scope ) )
			visitChildren( arg.node, scope+node.name.value+"." , arg.prefix )
		End If
	End Method
	
	' This is the entry point of our appliciation
	'
	'			LOCAL|GLOBAL|FIELD
	'			\_______=________/	    
	'             |            |
	'          TK_Colon       DEF
	'          |       |
	'          SYMBOL  TYPE
	
	Method symtable_VARDECL( arg:TGift )
		Local equal:TASTBinary = TASTBinary( arg.node )
		Local scope:Int = equal.tokenid		'TK_Local, TK_Field, TK_Global
		
		Select scope
		Case TK_Local, TK_Global, TK_Field
			Local colon:TASTBinary = TASTBinary( equal.lnode )
			'DebugStop
			' Validate the node
			If colon
				If colon.tokenid = TK_Colon
					DebugStop
					Local symbol:TASTNode = colon.lnode
					Local datatype:TASTNode = colon.rnode
					DebugStop
					DebugLog( "Symbol: "+scope+", "+symbol.value+":"+datatype.value )

					DebugStop
				Else
	DebugLog( "INVALID VARDECL - RNODE is not a colon" )
				End If
			Else
	DebugLog( "MISSING COLON NODE" )
			End If
		Default
DebugLog( "INVALID VARDECL TYPE" )
		'visitChildren( arg.node, arg.data, arg.prefix )
		End Select
	End Method

	Method symtable_WHILEWEND( arg:TGift )
		visitChildren( arg.node, arg.data, arg.prefix )
	End Method
	
End Type


Type TSymbolTableRow

	Global SYMBOLS:String[] = ["","File", "Module", "Namespace", "Package", "Class", "Method", "Property", "Field", ..
		"Constructor", "Enum", "Interface", "Function", "Variable", "Constant", "String", "Number", "Boolean", ..
		"Array", "Object", "Key", "Null", "EnumMember", "Struct", "Event", "Operator", "TypeParameter" ]

	Field filepath:String
	Field scope:String
	Field name:String
	Field kind:Int
	Field location:TLocation
	
'	Field line:Int, pos:Int		' Where this is within the source file
'	Field name:String			' Name of type, function, variable etc
'	'Field symtype:String		' function, method, type, int, string, double etc.
'	Field scope:String			' extern, function:name, method:name, global
'	Field class:String			' function, method, type, field, local, global, include 
'	Field description:String	' Taken directly from pre-defintion comment or line comment
'	Field defintion:String		' The definition taken from the source code
'	'

	Method New( name:String, kind:Int, location:TLocation, scope:String )
		Self.name = name
		Self.kind = kind
		Self.location = location
		Self.scope = scope
	End Method

	Method reveal:String()
		Local uri:String = ""
		Local loc:String = "[]"
		If location 
			uri = location.uri
			loc = location.reveal()
		End If
		Return scope[..16] + (kind+"="+SYMBOLS[kind])[..16] + name[..16] + loc[..16] + uri
	End Method
	
End Type

Rem



End Rem
