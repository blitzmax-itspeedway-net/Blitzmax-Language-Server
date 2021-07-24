
' Load a file into a contiguous string
Function LoadFile:String( filename:String, eol:string="~r~n" )
	Local file:TStream = ReadFile( filename )
	If Not file Return ""
	Local text:String
	While Not Eof(file)
		text :+ ReadLine(file)+EOL
	Wend
	CloseStream file
	Return text
End Function 

