SuperStrict

Import Text.Regex
Include "../bin/language-server-protocol.bmx"
Include "../lexer/TToken.bmx"

'# Test file for TURI

Function show( uri:TURI )
'DebugStop
	Print uri.tostring()
	Print "Scheme:    "+uri.scheme
	Print "Authority: "+uri.authority
	Print "Path:      "+uri.path
	Print "Query:     "+uri.query
	Print "Fragment:  "+uri.fragment
End Function

Local path: String = "file:///home/si/dev/sandbox/loadfile/loadfile.bmx"

'DebugStop
Local uri:TURI

uri = New TURI( path )
show( uri )

Print ""
debugstop
uri = New TURI( path, True )
show( uri )
