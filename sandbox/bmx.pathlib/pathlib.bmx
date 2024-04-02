' PATH LIBRARY
' (c) Copyright Si Dunford, March 2022, All rights reserved
' Concept born from muliple sources including similar Python and Node libraries
'
Rem USING THE PATHLIB

	import bmx.pathlib
	
	local path:string = Pathlib(".")

End Rem

?Win32
	Const DIR_SEPARATOR:String = "\"
?Not Win32
	Const DIR_SEPARATOR:String = "/"
?

Type TPath

	Function Normalise:String( path:String )
	End Function
	
	Function Parse:String[]( path:String )
	End Function
	
	Function Join:String( path:String[] )
	End Function

	Function Join:String( path1:String, path2:String )
	End Function
	
	Function extension:String( path:String )
	End Function
	
	Function basename:String( path:String )
	End Function
	
	' Functional
	Method join:String( piece:String )
	End Method
	
	Method join:String( path:String[] )
	End Method
	
	Method join:Path( path:TPath )
	End method 
	
	' PATH PARTS
	
	' Obtain the drive name
	Method drive:String()
		' UNC Paths shoudl also be considered as drives
		'	\\host\share
	End Method
	
	' Obtain the parent folder path
	Method parent:String()
	End Method
	
	' OBJECT ENUMERATORS
	
	Method files:PathlibFiles()
	End Method
	
	Method folders:PathlibFolders()
	End Method
	
End Type

Type PathlibFolder

	Method ObjectEnumerator:Object()
	End Method

	Method hasNext:Int()
	End Method
	
	Method nextObject:Object()
	End Method
	
End

Type PathlibFiles

	Method ObjectEnumerator:Object()
	End Method

	Method hasNext:Int()
	End Method
	
	Method nextObject:Object()
	End Method
	
End
