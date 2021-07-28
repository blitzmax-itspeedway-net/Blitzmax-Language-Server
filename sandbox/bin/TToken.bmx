
'	Generic Symbol
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'
Type TToken
	Field id:Int		' Token type as an integer
	Field class:String	' Token type as a string (Depreciated)
	Field value:String	' Actual value of symbol or identifier
	Field line:Int		' Line number in original source file
	Field pos:Int		' Character position in original source file

    Method New( id:Int, value:String, line:Int, pos:Int, class:String )
        'Print( "## "+id+", "+value+", "+line+", "+pos )
		Self.id    = id		' Token ID
        Self.class = class	' The type of token
        Self.value = value	' Strign value from source
        Self.line  = line	' Line number in Source
        Self.pos   = pos 	' Position in line
    End Method

	Method reveal:String()
		Return RSet(line,4)+","+LSet(pos,4)+" " + String(id)[..6] + class[..12] + value
	End Method

	' Confirm if symbol is in a given set
	Method in:Int( set:Int[] )
		For Local element:Int = EachIn set
			If element=id Return True
		Next
		Return False
	End Method

	'Method in:Int( options:String[] )
	'	For Local option:String = EachIn options
	'		If option=class Return True
	'	Next
	'	Return False
	'End Method

	' Confirm if symbol is NOT in a given set
	Method notin:Int( set:Int[] )
		For Local element:Int = EachIn set
			If element=id Return False
		Next
		Return True
	End Method
	
	'Method notin:Int( options:String[] )
	'	For Local option:String = EachIn options
	'		If option=class Return False
	'	Next
	'	Return True
	'End Method
	
End Type