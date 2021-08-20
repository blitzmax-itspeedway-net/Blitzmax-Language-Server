SuperStrict

Framework Text.RegEx
Import brl.retro
Import brl.stream
Import brl.filesystem
Include "bin/loadfile().bmx"

Global source:String = loadFile( "samples/test.bmx" ) 
Global cursor:Int = Instr( source,"REM" )+2

Function findNext:TRegExMatch( text:String, regex:Int = False )
	Local re:TRegEx
	If Not regex text = "(?i)"+text
	re = TRegEx.Create( text )
DebugStop
	Try
		Local matches:TRegExMatch = re.find( source,cursor )
		If matches Return matches
	Catch e:TRegExException
		' Do nothing, its not important!
	End Try
	Return Null
End Function

Local match:TRegExMatch = findnext("(?im)^\s*(ENDREM|END REM)(?![a-zA-Z0-9_])", True)
' Have we found anything?
Local remark:String
DebugStop
If match

	For Local i:Int = 0 Until match.SubCount()
		Print i + ": " + match.SubExp(i)
	Next
	Local start:Int = match.substart(1)
	Local finish:Int = match.subEnd(1)+1
	remark = source[cursor..finish]

End If
Print "/*"+remark+"*/"
