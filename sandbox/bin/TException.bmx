
'	Exception handling
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TException
	Field line:Int
	Field pos:Int
	Field text:String
	Method New( text:String, line:Int=-1, pos:Int=-1 )
		Self.text = text
		Self.line = line
		Self.pos = pos
	End Method
	Method toString:String()
		Local msg:String = text
		If line>-1 And pos>-1 msg :+ " at ("+line+","+pos +")"
		Return msg
	End Method
End Type

Function ThrowException( message:String, line:Int=-1, pos:Int=-1 )
	Throw( New TException( message, line, pos ) )
End Function