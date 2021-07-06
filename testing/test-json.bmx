SuperStrict

'	JSON TYPE TESTING
'	(c) Copyright Si Dunford, June 2021

Include "../bin/json.bmx"

'DUMMY LOGFILE SO WE CAN STILL TEST JSON LIBRARY
Type TDummyLog
    Method write(nul:String, reserv:String="")
    End Method
End Type
Global logfile:TDummyLog = New TDummyLog
'DUMMY END


Function LoadFile:String( filename:String )
	Local file:TStream = ReadFile( filename )
	If Not file Return ""
	Local content:String content = ReadString( file, Int(file.size()) )
	CloseStream file
	Return content
End Function 

Function Validate( filename:String, text:String, failtest:Int=False )
	Local file:String = LoadFile( filename )
	Local j:JNode = JSON.Parse( file )
	If j.isInvalid()
		Print "FAILURE: "+ filename
		Print "  ERROR: "+ JSON.errtext + " {"+ JSON.errline+","+JSON.errpos+"}"
		Print "  FILE:  "+ file
		Return
	End Iftail
	
	Local str:String = JSON.Stringify( j )
	If text = str And Not failtest
		Print "SUCCESS: "+filename
		Return
	End If
	Print "FAILURE: "+filename
	Print "  TEXT:   "+text
	Print "  FILE:   "+file
	Print "  RESULT: "+str
End Function

'	TEST KNOWN FAILURES

'Validate( "failure/char-past-eof.json", "{ ~qname~q:~qAlice~q,~qAge~q:31 }", True )
'Validate( "failure/missing-comma.json", "{ ~qname~q:~qAlice~q,~qAge~q:31 }", True )
'Validate( "failure/non-quoted-key.json", "{ ~qname~q:~qAlice~q,~qAge~q:31 }", True )

'	TEST KNOWN SUCCESS

'Validate( "success/empty-file.json", "{ ~qname~q:~qAlice~q,~qAge~q:31 }" )
'Validate( "success/empty-object.json", "{ ~qname~q:~qAlice~q,~qAge~q:31 }" )
'Validate( "success/basic.json", "{ ~qname~q:~qAlice~q,~qAge~q:31 }" )
Validate( "initialise.txt", "{ ~qname~q:~qAlice~q,~qAge~q:31 }" )
