SuperStrict

Import bmx.json
'Import bmx.lexer

' SANDBOX PARSER
Include "bmx.parser/TParser.bmx"
Include "bmx.parser/TASTNode.bmx"
Include "bmx.parser/TASTBinary.bmx"
Include "bmx.parser/TASTCompound.bmx"
Include "bmx.parser/TVisitor.bmx"
Include "bmx.parser/TParseValidator.bmx"
Include "bmx.parser/TASTErrorMessage.bmx"

' SANDBOX BLITZMAX LEXER/PARSER
' Included here until stable release pushed back into module
Include "bmx.blitzmaxparser/lexer-const-bmx.bmx"
Include "bmx.blitzmaxparser/TBlitzMaxAST.bmx"
Include "bmx.blitzmaxparser/TBlitzMaxLexer.bmx"
Include "bmx.blitzmaxparser/TBlitzMaxParser.bmx"

'	SUPPORTING ROLES
Include "../bin/language-server-protocol.bmx"

Function LoadFile:String(filename:String)
	Local file:TStream = ReadStream( filename )
	If Not file Return ""
	Print "- File Size: "+file.size()+" bytes"
	Local content:String = ReadString( file, file.size() )
	CloseStream file
	Return content
End Function

Local filename:String = "/home/si/dev/example/test-message.bmx"

DebugStop
Local source:String = loadFile( filename )
Local start:Int, finish:Int

Local lexer:TLexer = New TBlitzMaxLexer( source )
start  = MilliSecs()
lexer.run()
finish = MilliSecs()

Print( "LEXER.TIME: "+(finish-start)+"ms" )
Print( lexer.reveal() )

Local parser:TParser = New TBlitzMaxParser( lexer )
Local ast:TASTNode
start  = MilliSecs()
ast    = parser.parse_ast()
finish = MilliSecs()

Print( "PARSE TIME: "+(finish-start)+"ms" )

' SHOW AST STRUCTURE
Print "~nAST STRUCTURE:"
Print "------------------------------------------------------------"
DebugStop
Print ast.reveal()
Print "------------------------------------------------------------"


