SuperStrict

Function LoadFile:String(filename:String)
	Local file:TStream = ReadStream( filename )
	If Not file Return ""
	Print "- File Size: "+file.size()+" bytes"
	Local content:String = ReadString( file, file.size() )
	CloseStream file
	Return content
End Function

Local text:String = loadFile( "initialize.txt" )


Print( "Loaded "+Len(text)+"bytes" )
Print text
DebugStop

