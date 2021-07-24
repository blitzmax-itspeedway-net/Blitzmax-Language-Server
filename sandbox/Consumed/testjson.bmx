SuperStrict

Include "../bin/json.bmx"
Include "loadfile().bmx"

' 	DUMMY FUNCTION
Function publish( event:String, data:String="", extra:String="" )
Print event+", "+data+", "+extra
End Function
'	END DUMMY FUNCTION

Local J:JSON = JSON.parse( loadfile( "example.json" ) )

If J.isInvalid() 
	Print J.error()
Else
	Print "JSON is valid:"
End if

Print J.stringify()
