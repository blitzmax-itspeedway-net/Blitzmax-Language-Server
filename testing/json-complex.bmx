SuperStrict

'	JSON EXAMPLES
'	(c) Copyright Si Dunford, October 2021

Import brl.objectlist
Import Text.regex

' SANDBOX LEXER
Include "../lexer/TLexer.bmx"
Include "../lexer/TToken.bmx"
Include "../lexer/TException.bmx"

' SANDBOX PARSER
Include "../parser/TParser.bmx"
Include "../parser/TASTNode.bmx"
'Include "../parser/TASTBinary.bmx"
Include "../parser/TASTCompound.bmx"
Include "../parser/TVisitor.bmx"
Include "../parser/TParseValidator.bmx"

' SANDBOX JSON LEXER/PARSER
Include "../json/JSON.bmx"
Include "../json/TJSONLexer.bmx"
Include "../json/TJSONParser.bmx"

'	DUMMY FUNCTIONS
Function ThrowParseError( S:String, N1:Int, N2:Int ) ; End Function
Type TDiagnostic
	Method reveal:String() ; End Method
End Type

Local content:String = "{~qjsonrpc~q:~q2.0~q,~qmethod~q:~qtextDocument/didChange~q,~qparams~q:{~qtextDocument~q:{~quri~q:~qfile:///home/si/dev/sandbox/loadfile/loadfile3.bmx~q,~qversion~q:2},~qcontentChanges~q:[{~qrange~q:{~qstart~q:{~qline~q:16,~qcharacter~q:0},~qend~q:{~qline~q:16,~qcharacter~q:0}},~qrangeLength~q:0,~qtext~q:~q ~q}]}}"

DebugStop
Local J:JSON = JSON.Parse( content )
'Publish( "debug", "Parse finished" )
' Report an error to the Client using stdOut
If Not J Or J.isInvalid()
	Local errtext:String
	If J.isInvalid()
		Print "ERROR("+J.errNum+") "+J.errText+" at {"+J.errLine+","+J.errpos+"}"
	Else
		Print "ERROR: Parse returned null"
	End If
Else
	Print "PARSE: OK"
	Print J.prettify()
End If


