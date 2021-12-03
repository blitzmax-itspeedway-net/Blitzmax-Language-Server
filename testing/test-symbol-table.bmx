SuperStrict

Rem THINGS TO DO
* Fix VARDECL - The lnode should be a colon, not an equals.
* Sort out scope and include/import
	- Think I can do this using "mother" variable
* "FOR LOCAL:type =... NEXT" is not working
* Fix Parser for the following
	For
	
* Need to send back the following:

	JSON Array of SymbolInformation
	SymbolInformation
		name: string
		kind: SymbolKind (INT)
		?tags: Optional SymbolTag[]
		location: Location
			uri
			range: TRange
				start{ line: 6, character: 0 }
				end:{ line: 6, character: 0 }
		?containerName: string
End Rem

Import bmx.json
Import bmx.lexer
'Import bmx.parser

'	TEST BUILDING OF A SYMBOL TABLE
Include "../bin/language-server-protocol.bmx"
Include "../bin/TSymbolTable.bmx"
Include "../bin/TGift.bmx"

' SANDBOX PARSER
Include "../sandbox/bmx.parser/TParser.bmx"
Include "../sandbox/bmx.parser/TASTNode.bmx"
Include "../sandbox/bmx.parser/TASTBinary.bmx"
Include "../sandbox/bmx.parser/TASTCompound.bmx"
Include "../sandbox/bmx.parser/TVisitor.bmx"
Include "../sandbox/bmx.parser/TParseValidator.bmx"
Include "../sandbox/bmx.parser/TASTErrorMessage.bmx"

' SANDBOX BLITZMAX LEXER/PARSER
' Included here until stable release pushed back into module
Include "../sandbox/bmx.blitzmaxparser/lexer-const-bmx.bmx"
Include "../sandbox/bmx.blitzmaxparser/TBlitzMaxAST.bmx"
Include "../sandbox/bmx.blitzmaxparser/TBlitzMaxLexer.bmx"
Include "../sandbox/bmx.blitzmaxparser/TBlitzMaxParser.bmx"


Function LoadFile:String(filename:String)
	Local file:TStream = ReadStream( filename )
	If Not file Return ""
	Print "- File Size: "+file.size()+" bytes"
	Local content:String = ReadString( file, file.size() )
	CloseStream file
	Return content
End Function


Function in:Int( needle:Int, haystack:Int[] )
	For Local i:Int = 0 Until haystack.length
		If haystack[i]=needle ; Return True
	Next
	Return False
End Function

Function in:Int( needle:String, haystack:String[] )
	For Local i:Int = 0 Until haystack.length
		If haystack[i]=needle ; Return True
	Next
	Return False
End Function

' Load a sample file...
'Local filename:String = "/home/si/dev/example/test-digest.bmx"
Local filename:String = "/home/si/dev/example/test-message.bmx"
Local content:String = loadfile( filename )

Local start:Int, finish:Int

start = MilliSecs()
Local lexer:TLexer = New TBlitzMaxLexer( content )
Local parser:TParser = New TBlitzMaxParser( lexer )
Local ast:TASTNode = parser.parse_ast()
finish = MilliSecs()

Print "PARSE: "+(finish-start)+"ms"
Print lexer.reveal()
Print parser.reveal()
'DebugStop
Print ast.reveal()

' Parse the AST into a symbol table
start = MilliSecs()
DebugStop
Local symTable:TSymbolTable = New TSymbolTable()
symtable.extract( ast, filename )
finish = MilliSecs()

Print "EXTRACT: "+(finish-start)+"ms"

Print symtable.reveal()

' TEST CARET POSITION
Rem PSUDOCODE

local cmd:string = ""
repeat
	cmd= input
	if cmd = "" ; exit
	local pos:int = int( cmd )
	if pos = 0 ; continue
	' Need to walk the tree to find the position
	local position:TPosition = ast.caretPosition( pos )
	position.reveal()
	
	showHover()
	showCodeCompletion()
	...
forever

End Rem

' TEST CODE COMPLETION

Rem PSUDOCODE
Local suggestions:Tlist = symtable.getSuggestions( position )
local result:JSON = Response( id )
for suggestion in suggestions
	select suggestion.token
	case TK_function, TK_Method, TK_...
		suggestion.kind = symtable.getKindFromTokenId( sugegstion.tokenid )
		result["param|symbols"].append( suggestion )
	end select
next
End Rem

' TEST HOVER

' local hover:JSON = symtable.getSymbolAt( position )



