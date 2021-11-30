SuperStrict

Import Text.Regex
'Import bmx.lexer

'Include "../bin/language-server-protocol.bmx"
Include "../bin/TURI.bmx"
'Include "../lexer/TToken.bmx"

'# Test file for TURI

Function show( path:String )
DebugStop
	Local uri:TURI = New TURI( path )
	Print path
	Print "  Scheme:     "+uri.scheme
	Print "  Authority:  "+uri.authority
	Print "  Path:       "+uri.path
	Print "  Query:      "+uri.query
	Print "  Fragment:   "+uri.fragment
	Print "  toString(): "+uri.toString()
	Print "  folder():   "+uri.folder()
	Print "  filename(): "+uri.filename()
End Function

' THESE PATHS SHOULD BE EQUAL
'Linux
show( "file:///home/si/dev/sandbox/loadfile/loadfile.bmx" )
show( "/home/si/dev/sandbox/loadfile/loadfile.bmx" )
'Windows
show( "file://d:/dev/sandbox/loadfile/loadfile.bmx" )
show( "D:\dev\sandbox\loadfile\loadfile.bmx" )



