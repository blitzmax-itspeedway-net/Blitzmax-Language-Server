SuperStrict

'DUMMY LOGFILE SO WE CAN STILL TEST JSON LIBRARY
Type TDummyLog
    Method write(nul:String, reserv:String="")
    End Method
End Type
Global logfile:TDummyLog = New TDummyLog
'DUMMY END

Include "../bin/TConfig.bmx"

DebugStop
Local config:TConfig = New TConfig()

Print "LOGFILE: "+config["logfile"]



