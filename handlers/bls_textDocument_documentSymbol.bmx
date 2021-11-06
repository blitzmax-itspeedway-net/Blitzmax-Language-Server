
'   LANGUAGE SERVER MESSAGE HANDLER
'   (c) Copyright Si Dunford, October 2021, All Right Reserved
'
'   https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol
'   REQUEST:    textDocument/documentSymbol

Rem EXAMPLE
{
  "id": 2,
  "jsonrpc": "2.0",
  "method": "textDocument/documentSymbol",
  "params": {
    "textDocument": {
      "uri": "file: ///home/si/dev/sandbox/loadfile/loadfile3.bmx"
    }
  }
}
End Rem

' CLIENT HAS REQUESTED DOCUMENT SYMBOLS
Function bls_textDocument_documentSymbol:JSON( message:TMessage )

    Local id:String = message.getid()
    Local params:JSON = message.params
	
	If config.istrue("experimental|docsym")
		logfile.warning( "EXPERIMENTAL FEATURE ENABLED: textDocument/documentSymbol~n"+message.J.prettify() )
	Else
		logfile.warning( "EXPERIMENTAL FEATURE DISABLED: textDocument/documentSymbol" )
		Return Response_OK( id )
	End If
	
logfile.debug( "Getting document" )

	' Get the document
	Local doc_uri:String = message.J.find( "params|textDocument|uri" ).toString()

logfile.debug( "Got doc_uri: "+doc_uri )

	Local workspace:TWorkspace = workspaces.get( doc_uri )

logfile.debug( "Got Workspace" )
If workspace 
	logfile.debug( "Workspace IS NOT NULL" )
Else
	logfile.debug( "Workspace IS NULL" )
EndIf

	Local document:TFullTextDocument = TFullTextDocument( workspace.get( doc_uri ) )

logfile.debug( "Got document" )

	' Can only work with FULL TEXT DOCUMENTS at present
	' Later we may be able to load an AST from file

	If Not document Or Not document.ast
		logfile.debug( "# NOT A FILL TEXT DOCUMENT" )
		Return Response_OK( id )
	End If
	
	' Decide if we are sending DocumentSymbol[], or SymbolInformation[]

	' Send outline view to VSCODE
			
	' Identify capabilities of the client:
	'logfile.debug( "CLIENT CAPABILITIES:~n"+client.capabilities.prettify() )
	
	'Local documentsymbols:JSON = client.capabilities.find( "textDocument|documentSymbol" )
	'Local symbols:JSON = documentsymbols.find( "symbolKind|valueset" )
	
	' Default symbol-set if client does not specify
	
	'If client.has( "textd
	
	' Calls ast.inorder() which runs the given function against each
	' ast node in order. The argument is an object that will be updated 
	' by the given function (In this case JSON)
	
	' OPTIONS IS A BITMAP
	'	00000000	SymbolInformation[]
	'	00000001	DocumentSymbol[]
	'	00000010	Show AST
	
logfile.debug( "Getting Options" )

	Local options:Int = TDocumentSymbolVisitor.OPT_FLAT
	If client.has( "textDocument|documentSymbol|hierarchicalDocumentSymbolSupport" )
		logfile.debug( "# Client HAS textDocument|documentSymbol|hierarchicalDocumentSymbolSupport" )
		options = TDocumentSymbolVisitor.OPT_TREE
	Else
		logfile.debug( "# Client only supports SymbolInformation" )	
	End If

	' An AST can only be shown in Tree (Hierarchial) symbol information
	Local showAST:Int = config.find("experimental|ast").toint()
	If showAST And options = TDocumentSymbolVisitor.OPT_TREE ; options :| TDocumentSymbolVisitor.OPT_AST
	
	'OPTIONS DEBUGGING
	' 00 = Show Flat Symbol Information
	' 01 = Show Hierarchical Symbol Information
	' 10 = Not valid. Hierarchical is required to display AST
	' 11 = Show AST INSTEAD of heirachical
	'options = TDocumentSymbolVisitor.OPT_FLAT
	'options = TDocumentSymbolVisitor.OPT_TREE
	'options = TDocumentSymbolVisitor.OPT_TREE | TDocumentSymbolVisitor.OPT_AST

	' Generate DocumentSymbol Information
logfile.debug( "RUNNING VISITOR" )
	Local visitor:TDocumentSymbolVisitor = New TDocumentSymbolVisitor( document.ast, options )
	Local data:JSON = visitor.run()
	
	'Local documentSymbol:JSON = New JSON()
	'documentSymbol.set( "name", "SCAREMONGER.TEST" )
	'documentSymbol.set( "detail", "" )
	'documentSymbol.set( "kind", SymbolKind._File.ordinal() )
	'documentSymbol.set( "tags", "" )
	'documentSymbol.set( "depreciated", "false" )
	'documentSymbol.set( "range|start|line", 0 )
	'documentSymbol.set( "range|start|character", 0 )
	'documentSymbol.set( "range|end|line", 0 )
	'documentSymbol.set( "range|end|character", 11 )
	'documentSymbol.set( "selectionRange|start|line", 0 )
	'documentSymbol.set( "selectionRange|start|character", 0 )
	'documentSymbol.set( "selectionRange|end|line", 0 )
	'documentSymbol.set( "selectionRange|end|character", 11 )
	'data = New JSON( JSON_ARRAY )
	'data.addLast( documentSymbol )	

	'data = JSON( document.ast.preorder( SymbolInformation, data, options ) )
	'If data ; logfile.debug( "SYMBOLINFORMATION~n"+data.prettify() )
	'data = JSON( ast.inorder( DocumentSymbol, data ) )
	'If data ; logfile.debug( "DOCUMENTSYMBOL~n"+data.prettify() )		

logfile.debug( "CREATED DATA" )
'logfile.debug( "SYMBOLINFORMATION~n"+data.prettify() )
	Local response:JSON = Response_OK( id )
		
	response.set( "result", data )

	Return response
	
	
End Function

' A Gift is an Argument brought by a Visitor... ;) ha ha... 
Type TGift
	Field node:TASTNode
	Field data:JSON
	Field prefix:String
	Method New( node:TASTNode, data:JSON, prefix:String )
		Self.node = node
		Self.data = data
		Self.prefix = prefix
	End Method
End Type

Type TDocumentSymbolVisitor Extends TVisitor

	Field ast:TASTNode
	Field options:Int
	
	Const OPT_FLAT:Int = $0000
	Const OPT_TREE:Int = $0001
	Const OPT_AST:Int  = $0010
	Const OPT_SHOW:Int = $0011
	
	Global VALID_SYMBOLS:String[] = ["program","function","type","method","struct","include"]

	Method New( ast:TASTNode, options:Int )
		Self.ast = ast
		Self.options = options
	End Method

	' Create source code from the AST
	Method run:JSON()
		Local J:JSON = New JSON( JSON_ARRAY )	' DocumentSymbol[]
		visit( ast, J, "outline" )
		Return J
	End Method
	
	Method visit( node:TASTNode, mother:JSON, prefix:String = "outline" )
		If Not node ; Return
		
		' Use Reflection to call the visitor method (or an error)
		Local nodeid:TTypeId = TTypeId.ForObject( node )
		
		' Use Reflection to call the visitor method (or an error)
		Local this:TTypeId = TTypeId.ForObject( Self )
		' The visitor function is either defined in metadata or as node.name
		Local class:String = nodeid.metadata( "class" )
		If class = "" class = node.name
'DebugStop

		' Only show selective nodes unless in AST mode
		If options <> OPT_SHOW 
Local within:Int = in( class, VALID_SYMBOLS )
logfile.debug( "OPT:"+options+", '"+class+"', "+within )
			If Not in( Lower(class), VALID_SYMBOLS ) ; Return
		End If

		Local methd:TMethod = this.FindMethod( prefix+"_"+class )
		If methd
			
			methd.invoke( Self, [New TGift(node,mother,prefix)] )
		Else
			' We only show these errors in AST View
			If options <> OPT_SHOW ; Return
		
			Local documentSymbol:JSON = New JSON()
			documentSymbol.set( "name", "## MISSING: '"+prefix+"_"+class+"()'" )
			'documentSymbol.set( "detail", "" )
			documentSymbol.set( "kind", SymbolKind._Namespace.ordinal() )
			'documentSymbol.set( "tags", "" )
			'documentSymbol.set( "depreciated", "false" )
			documentSymbol.set( "range", JRange( node ) )
			documentSymbol.set( "selectionRange", JRange( node ) )
			
			'documentSymbol.set( "range|start|line", 0 )
			'documentSymbol.set( "range|start|character", 0 )
			'documentSymbol.set( "range|end|line", 0 )
			'documentSymbol.set( "range|end|character", 11 )
			'documentSymbol.set( "selectionRange|start|line", 0 )
			'documentSymbol.set( "selectionRange|start|character", 0 )
			'documentSymbol.set( "selectionRange|end|line", 0 )
			'documentSymbol.set( "selectionRange|end|character", 11 )
	
			' Add to mother node
			mother.addLast( documentSymbol )
		
		EndIf

	End Method

	Method visitChildren( node:TASTNode, mother:JSON, prefix:String )
		Local family:TASTCompound = TASTCompound( node )
		If family
			For Local child:TASTNode = EachIn family.children
				visit( child, mother, prefix )
			Next
		EndIf
	End Method
	
	' DEFAULT NODE - CALLED WHEN THERE IS NO METHOD FOR THE CURRENT NODE
Rem - 6/11/21, Removed because we do this in visit()
	Method outline_( arg:TGift )
'DebugStop
		Local node:TASTNode = arg.node
		Local mother:JSON   = arg.data

		'Local name:String = "'"+node.name+"' ("+node.value+") is Not defined in visualiser"
		'Local mother:TGadget = AddTreeViewNode( name, arg.gadget, ICON_RED )

		Local documentSymbol:JSON = New JSON()
		documentSymbol.set( "name", "## UNDEF: '"+node.name+"' ("+node.value+")'" )
		'documentSymbol.set( "detail", "" )
		documentSymbol.set( "kind", SymbolKind._Namespace.ordinal() )
		'documentSymbol.set( "tags", "" )
		'documentSymbol.set( "depreciated", "false" )
	documentSymbol.set( "range|start|line", 0 )
	documentSymbol.set( "range|start|character", 0 )
	documentSymbol.set( "range|end|line", 0 )
	documentSymbol.set( "range|end|character", 11 )
	documentSymbol.set( "selectionRange|start|line", 0 )
	documentSymbol.set( "selectionRange|start|character", 0 )
	documentSymbol.set( "selectionRange|end|line", 0 )
	documentSymbol.set( "selectionRange|end|character", 11 )

		' Add to mother node
		mother.addLast( documentSymbol )

		'visitChildren( arg.node, mother )
	End Method
End Rem

	' A missing optional compoment doesn't have a
	'Method outline_missingoptional( arg:TGift )
	'End Method

	' This is the entry point of our appliciation
	Method outline_PROGRAM( arg:TGift )
		visitChildren( arg.node, arg.data, arg.prefix )
	End Method

	' This is the entry point of our appliciation
	Method outline_FUNCTION( arg:TGift )
	
		Local node:TAST_Function = TAST_Function( arg.node )
		If Not node.fnname Return
		
		Local documentSymbol:JSON = New JSON()
		documentSymbol.set( "name", "Function "+node.fnname.value+"()" )
		'documentSymbol.set( "detail", "" )
		documentSymbol.set( "kind", SymbolKind._Function.ordinal() )
		'documentSymbol.set( "tags", "" )
		'documentSymbol.set( "depreciated", "false" )
		documentSymbol.set( "range", JRange( node ) )
		documentSymbol.set( "selectionRange", JRange( node ) )

		Local children:JSON = New JSON( JSON_ARRAY )
		documentSymbol.set( "children", children )
		
		' Add to mother node
		arg.data.addLast( documentSymbol )	

		visitChildren( node.body, children, arg.prefix )
	End Method
	
	' This is the entry point of our appliciation
	Method outline_METHOD( arg:TGift )
	
		Local node:TAST_Method = TAST_Method( arg.node )
		If Not node.methodname Return
		
		Local documentSymbol:JSON = New JSON()
		documentSymbol.set( "name", "Method "+node.methodname.value+"()" )
		'documentSymbol.set( "detail", "" )
		documentSymbol.set( "kind", SymbolKind._Method.ordinal() )
		'documentSymbol.set( "tags", "" )
		'documentSymbol.set( "depreciated", "false" )
		documentSymbol.set( "range", JRange( node ) )
		documentSymbol.set( "selectionRange", JRange( node ) )

		Local children:JSON = New JSON( JSON_ARRAY )
		documentSymbol.set( "children", children )
		
		' Add to mother node
		arg.data.addLast( documentSymbol )	

		visitChildren( node, children, arg.prefix )
	End Method

	' This is the entry point of our appliciation
	Method outline_TYPE( arg:TGift )
	
		Local node:TAST_Type = TAST_Type( arg.node )
		If Not node.typename Return
		
		Local documentSymbol:JSON = New JSON()
		Local name:String = "Type "+node.typename.value
		If node.extend And node.supertype ; name :+ " Extends "+node.supertype.value		
		documentSymbol.set( "name", name )
		'documentSymbol.set( "detail", "" )
		documentSymbol.set( "kind", SymbolKind._Class.ordinal() )
		'documentSymbol.set( "tags", "" )
		'documentSymbol.set( "depreciated", "false" )
		documentSymbol.set( "range", JRange( node ) )
		documentSymbol.set( "selectionRange", JRange( node ) )

		Local children:JSON = New JSON( JSON_ARRAY )
		documentSymbol.set( "children", children )
		
		' Add to mother node
		arg.data.addLast( documentSymbol )	

		visitChildren( node, children, arg.prefix )
	End Method

End Type

