SuperStrict

' Test add/get capabilities to allow handlers to register themselves

'DebugStop

Framework brl.retro

local abc:string = "Quoted string"

Global capabilities:String[]

Function addCapability( capability:String )
	capabilities :+ [capability]
End Function

Function getCapabilities:String[][]()
	Local result:String[][]
	DebugStop
	For Local capability:String = EachIn capabilities
		result :+ [[capability,"true"]]
	Next
	Return result
End Function

addCapability( "textDocumentSync" )
addCapability( "hoverProvider" )

'Local example:String[][] = [["hoverProvider","true"],["textDocumentSync","true"]]

Local values:String[][] = getcapabilities()

For Local value:String[] = EachIn values
	If value.length=2
		Print( value[0]+"="+value[1] )
	End If
Next

' Test stuff

local test:float = 34.4
if test>= 10.6 print "YES"

' TEST
<> .. <= >= :+ :- :* :/ :& :| :~
