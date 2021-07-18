
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Document Manager (Added in V0.2)
' CURRENTLY DISABLED
'Definition MUST Return "undefined" by Default.

' Register this component
DebugLog( "TTextDocument_Handler" )
Publish( "log", "DEBG", "Initialise TTextDocument_Handler()" )
New TTextDocument_Handler()
Type TTextDocument_Handler Extends TMessageHandler

	Const TextDocumentSyncKind_None:Int=0
	Const TextDocumentSyncKind_Full:Int=1
	Const TextDocumentSyncKind_Incremental:Int=2

	Field documents:TMap = New TMap()

	Method New()
		Publish( "log", "DEBG", "TTextDocument_Handler.new()" )
		'DebugStop
		'lsp.register( Self )
		' Register Capabilities
		lsp.capabilities.set( "textDocumentSync", TextDocumentSyncKind_Incremental )
		lsp.capabilities.set( "definitionProvider", "true" )
		
'DebugStop		
'DebugLog( lsp.capabilities.stringify() )
Publish( "log", "DEBG", "TextDocument:Capabilities: "+lsp.capabilities.stringify() )

		'DebugLog( lsp.capabilities.stringify() )
		' "DID" Handlers
		lsp.addHandler( Self, ["textDocument/didOpen", "textDocument/didChange", "textDocument/didClose","textDocument/didSave"] )
		' "WILL" Handlers
		lsp.addHandler( Self, ["textDocument/willSave","textDocument/willSaveWaitUntil"] )
		' "WILL" Handlers
		lsp.addHandler( Self, ["textDocument/definition","textDocument/typeDefinition"] )
	End Method
	
	'Method Notify( message:String, data:Object, extra:Object )
	'End Method
	
	'Method Signal:Int( event:String, data:Object, extra:Object )
	'End Method
	
	' Called by Worker thread to process a message
	Method run:String( message:TMessage )
		Publish( "info", "TTextDocument_Handler received "+message.methd )
		Select message.methd
		Case "textDocument/didOpen"		; Return didOpen( message )
		Case "textDocument/didChange"	; Return didChange( message )
		Case "textDocument/didClose"	; Return didClose( message )
		Case "textDocument/didSave"		; Return didSave( message )

		Case "textDocument/definition"		; Return definition( message )
		Case "textDocument/typeDefinition"	; Return typeDefinition( message )

		Default
			Publish( "error", "## TTextDocument_Handler failed to handle "+message.methd )
		End Select
		Return ""
	End Method
	
	Method didOpen:String( message:TMessage )
		Rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didOpen",
		"params":
			{
			"textDocument":
				{
				"languageId":"blitzmax",
				"text":"<CONTENT OF FILE>",
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx",
				"version":1
				}
			}
		}
		end rem

		Publish( "log","debug",message.J.stringify() )

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )
		Local textNode:JSON = message.J.find( "params|textDocument|text" )
		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If document
			document.setContent( textnode.toString() )
		Else
			' New Document
			document = New TTextDocument( textNode.toString() )
		End If

	End Method
	
	Method didChange:String( message:TMessage )
		Rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didChange",
		"params":
			{
			"contentChanges":
				[
					{
					"range":
						{
						"end":{"character":48,"line":40},
						"start":{"character":48,"line":40}
						},
					"rangeLength":0,
					"text":"~r~n~t~t"
					}
				],
			"textDocument":
				{
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx",
				"version":2
				}
			}
		}
		end rem
		Publish( "log","debug",message.J.stringify() )

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If Not document Return ""
		
		Local contentChanges:JSON = message.J.find( "params|contentChanges" )
		Local changes:JSON[] = contentChanges.toArray()
		If Not changes Return ""
		
		' Loop through all the changes
		For Local n:Int = 0 Until changes.length
			Local range:TRange = New TRange( changes[n].find("range" ) )
			Local rangeLength:Int = changes[n].find("rangeLength").toInt()
			Local rangeText:String = changes[n].find("text").toString()
			document.change( range, rangeLength, rangeText )
		Next

	End Method

	Method didClose:String( message:TMessage )
		Rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didClose",
		"params":
			{
			"textDocument":
				{
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx"
				}
			}
		}
		end rem
		Publish( "log","debug",message.J.stringify() )

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If document
			document.Close()
		End If

	End Method

	Method didSave:String( message:TMessage )
		Rem
		{
		"jsonrpc":"2.0",
		"method":"textDocument/didSave",
		"params":
			{
			"textDocument":
				{
				"uri":"file:///home/si/dev/LSP/handlers/TTextDocument.bmx",
				"version":3
				}
			}
		}
		end rem
		Publish( "log","debug",message.J.stringify() )

		Local uriNode:JSON = message.J.find( "params|textDocument|uri" )		
		Local uri:String = uriNode.toString() 

		Local document:TTextDocument = TTextDocument( MapValueForKey( documents, uri ) )
		If document
			document.save()
		End If

	End Method

	Method definition:String( message:TMessage )
		Rem
		{	"id":11,
			"jsonrpc":"2.0",
			"method":"textDocument/definition",
			"params":{
				"position":{
					"character":10,
					"line":209
					},
				"textDocument":{
					"uri":
					"file:///home/si/dev/LSP/sandbox/documentSync.bmx"
					}
				}
			}
		End Rem
		Publish( "log","debug",message.J.stringify() )
		
		' Default response is "null"
        Local response:JSON = New JSON()
        response.set( "id", message.id )
        response.set( "jsonrpc", JSONRPC )
        response.set( "result", "null" )

        Return response.stringify()
	End Method

	Method typeDefinition:String( message:TMessage )
		Rem

		end rem
		Publish( "log","debug",message.J.stringify() )

		' Default response is "null"
        Local response:JSON = New JSON()
        response.set( "id", message.id )
        response.set( "jsonrpc", JSONRPC )
        response.set( "result", "null" )

        Return response.stringify()
	End Method
	
End Type

Type TTextDocument
	Field content:String		' Document text
	Field isopen:Int = False
	Field ismodified:Int = False

' *****************************
' ***** DEMO PARSER START *****
' *****************************

	Field sourcecode:String
	Field lines:String[]
	Field symbols:TSymbol[]
	
' *****************************
' ****** DEMO PARSER END ******
' *****************************

	Method New( text:String )
		isopen = True
		setContent( text )
	End Method

	Method setContent( text:String )
		content = text
		ismodified = False
		
' *****************************
' ***** DEMO PARSER START *****
' *****************************

		sourcecode = text
		lines = sourcecode.split( "~r~n" )

		' -> VERY INEFFICIENT CODE 
		' -> TO BE REVIEWED LATER
		PoorMansParser()
		' -^	
		
' *****************************
' ****** DEMO PARSER END ******
' *****************************

	End Method

	Method change( range:TRange, rangeLength:Int, rangeText:String )
		
		ismodified = True
		
' *****************************
' ***** DEMO PARSER START *****
' *****************************
		If Not range Or range.inValid() Return
		
		Local start_pos:Int = range.rangeStart.character
		Local start_line:Int = range.rangeStart.line
		Local end_pos:Int = range.rangeEnd.character
		Local end_line:Int = range.rangeEnd.line
		
		sourcecode = ""
		
		For Local line:Int = 0 Until lines.length
			If (line<start_line) Or (line>end_line)
				sourcecode :+ lines[line]+"~r~n"
				Continue
			End If
			If line=start_line sourcecode :+ lines[line][..start_pos] + rangeText
			If line=end_line sourcecode :+ lines[line][end_pos..]+"~r~n"
		Next
		' Trim additional CRLF from end
		sourcecode = sourcecode[..(sourcecode.length-2)]
		
		' Update self
		lines = sourcecode.split( "~r~n" )
		
		' -> VERY INEFFICIENT CODE 
		' -> TO BE REVIEWED LATER
		PoorMansParser()
		' -^	

' *****************************
' ****** DEMO PARSER END ******
' *****************************
		
	End Method

	Method Close()
		isopen = False
	End Method

	Method save()
	End Method

' *****************************
' ***** DEMO PARSER START *****
' *****************************

	' This is not really a parser, but I need something to start me off
	Method PoorMansParser()
DebugStop
		symbols = []
		
		'Local index:TIntMap = New TIntMap()
		Local match:TRegExMatch
		Local rxFunction:TRegEx = TRegEx.Create( "(?i)(\s*)(function\s*([[A-Za-z_][A-Za-z0-9_]*).*\(\s*(.*)\)).*" )
		Local rxType:TRegEx = TRegEx.Create( "(?i)(\s*)(type\s([A-Za-z][A-Za-z0-9_]*)).*" )
		Local rxMethod:TRegEx = TRegEx.Create( "(?i)(\s*)(method\s*([A-Za-z_][A-Za-z0-9_]*).*\(\s*(.*)\)).*" )
		Local rxGlobal:TRegEx = TRegEx.Create( "(?i)(\s*)(global\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z]*).*" )
		Local rxLocal:TRegEx = TRegEx.Create( "(?i)(\s*)(local\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z]*).*" )
		Local rxField:TRegEx = TRegEx.Create( "(?i)(\s*)(field\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z]*).*" )
		'
		For Local line:Int = 0 Until lines.length
			If Trim(lines[line])="" Continue
			match = rxType.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Type", match.subExp(3),match.subExp(0),line,match.subExp(1).length) ]
			match = rxMethod.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Method", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxFunction.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Function", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxGlobal.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Global", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxLocal.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Local", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxField.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Field", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
		Next
	
		' Debug the symbol table
		'For Local symbol:Int = 0 Until symbols.length
		'	Local sym:TSymbol=symbols[symbol]
		'	Print( (sym.line+","+sym.char)[..7]+"  "+sym.symbol[..10]+"  "+sym.value[..20]+" "+sym.definition )
		'Next
		
	End Method
	
' *****************************
' ****** DEMO PARSER END ******
' *****************************


End Type

Type TSymbol
	Field symbol:String
	Field value:String
	Field definition:String
	Field line:Int
	Field char:Int

	Method New( symbol:String, value:String, definition:String, line:Int, character:Int )
		Self.symbol = symbol
		Self.value = value
		Self.definition = definition
		Self.line = line
		Self.char = character
	End Method
	
End Type

Type TRange
	Field rangeStart:TPosition = New TPosition
	Field rangeEnd:TPosition = New TPosition
	Field _valid:Int = False
	
	Method New( range:JSON )
		rangeStart = New TPosition( range.find("start") )
		rangeEnd = New TPosition( range.find("end") )
		If rangeStart And rangeEnd _valid=True
	End Method
	
	Method invalid:Int()
		Return Not _valid
	End Method
	
	Method valid:Int()
		Return _valid
	End Method
	
End Type

Type TPosition
	Field character:Int
	Field line:Int
	
	Method New( position:JSON )
		character = position.find("character").toInt()
		line = position.find("line").toInt()
	End Method	
End Type
