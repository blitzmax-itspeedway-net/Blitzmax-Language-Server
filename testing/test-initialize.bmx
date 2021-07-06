SuperStrict

'	JSON TESTING - INITIALIZE MESSAGE
'	(c) Copyright Si Dunford, June 2021

' 475 bytes - Works
' 476 bytes - Crashes MaxIDE

Include "../bin/json.bmx"

Const TESTFILE:String = "vscode/initialize.json"

Global Logfile:TLogger = New TLogger

Function LoadFile:String( filename:String )
	Local file:TStream = ReadFile( filename )
	If Not file Return ""
	Print "- File Size: "+file.size()+" bytes"
	Local fp:Int = file.size()
	Local content:String
	Repeat 
		'DebugStop
		Local block:Int = Min( fp,400 )
		Local text:String = ReadString( file, block )
		Print( block + "," + Len(text) + "," + fp + "," + Len(content) )
		content :+ text
		fp :- block
	Until fp<=0
	CloseStream file
	Return content
End Function 

'DebugStop
Local request:String = loadfile( TESTFILE )


Local j:JSON = JSON.Parse( request )

If j.error()
    Print "  ERROR: "+ j.errtext + " {"+ j.errline+","+j.errpos+"}"
End If

Local str:String = JSON.Stringify( j )
Print "STRINGIFY:"
Print str


' Because we need to to include "json"
Type TRequest
End Type

Type TLogger
Method write(msg:String)
	Print msg
End Method
End Type