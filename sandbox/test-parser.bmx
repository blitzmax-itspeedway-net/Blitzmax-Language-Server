SuperStrict

Import bmx.json

Include "../bin/language-server-protocol.bmx"
'Include "../bin/constants.bmx"
Include "../bin/TGift.bmx"				' Gift brought by a Visitor ;)
Include "../bin/TURI.bmx"					' URI Support

' SANDBOX PARSER
Include "../sandbox/bmx.parser/TParser.bmx"
Include "../sandbox/bmx.parser/TASTNode.bmx"
Include "../sandbox/bmx.parser/TASTBinary.bmx"
Include "../sandbox/bmx.parser/TASTUnary.bmx"
Include "../sandbox/bmx.parser/TASTGroup.bmx"
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

Local filename:String = "/home/si/dev/example/test-message.bmx"

DebugStop
Local source:String = loadFile( filename )
Local start:Int, finish:Int

Local lexer:TLexer = New TBlitzMaxLexer( source )
start  = MilliSecs()
lexer.run()
finish = MilliSecs()

debugstop
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


