
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

?Win32
	Const DIR_SEPARATOR:String = "\"
?Not Win32
	Const DIR_SEPARATOR:String = "/"
?

Type TPath
	Field path:String[]

	Method New( path:String )
		Self.path = NormalSeparator( path ).split( DIR_SEPARATOR )
	End Method

	Method normal:String()
		Return DIR_SEPARATOR.join( path )
	End Method

	Method join( Addition:String )
		Addition = NormalSeparator( Addition )
		join( Addition.split( DIR_SEPARATOR ) )
	End Method
	
	Method join( Addition:String[] )
		For Local item:String = EachIn addition
			If item = ".."
				path = path[..(path.length-1)]
			Else
				path :+ [ item ]
			End If
		Next
	End Method
	
	Function NormalSeparator:String( source:String )
?Win32
		Return source.Replace( "/", DIR_SEPARATOR )
?Not Win32
		Return source.Replace( "\", DIR_SEPARATOR )
?
	End Function
	
End Type

Function joinPaths:String( leftpath:String, rightpath:String )

	Local path:TPath = New TPath( leftpath )
	path.join( rightpath )
	Return path.normal()
	
	' Normalise directory separator
?Win32
	leftpath = leftpath.Replace( leftpath, "\", DIR_SEPARATOR )
	rightpath = leftpath.Replace( leftpath, "\", DIR_SEPARATOR )
?Not Win32
	leftpath = leftpath.Replace( "/", DIR_SEPARATOR )
	rightpath = leftpath.Replace( "/", DIR_SEPARATOR )
?
	Local lpath:String[] = leftpath.split( DIR_SEPARATOR )
	Local rpath:String[] = leftpath.split( DIR_SEPARATOR )
	
	For Local path:String = EachIn rpath
		If path=".."
			lpath = lpath[..(lpath.length-1)]
		Else
		lpath :+ [ path ]
		End If
	Next
	Return DIR_SEPARATOR.join(lpath)
End Function
