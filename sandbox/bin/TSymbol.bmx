
'	Generic Symbol
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TSymbol
	Field class:String, value:String, line:Int, pos:Int

    Method New( class:String, value:String, line:Int, pos:Int )
        'print( "## "+symbol+", "+value+", "+line+", "+pos )
        Self.class = class
        Self.value = value
        Self.line = line
        Self.pos = pos 
    End Method

	Method reveal:String()
		Return (line+","+pos)[..9] + class[..12] + value
	End Method
	
End Type