
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Various ad-hock functions used throughout the application

'	Function to identify membership of an array
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

' Function to identify membership of an INT array
'Function notin:Int( needle:Int, haystack:Int[] )
'	For Local i:Int = 0 Until haystack.length
'		If haystack[i]=needle ; Return False
'	Next
'	Return True
'End Function