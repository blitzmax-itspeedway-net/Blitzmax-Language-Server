
' Load a file into a contiguous string
Function LoadFile:String( filename:String )
	Local file:TStream = ReadFile( filename )
	If Not file Return ""
	Local text:String
	While Not Eof(file)
		text :+ ReadLine(file)+"~r~n"
	Wend
	CloseStream file
	Return text
End Function 

