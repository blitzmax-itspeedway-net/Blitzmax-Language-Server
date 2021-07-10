
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Include "TMethod_exit.bmx"
include "TMethod_initialize.bmx"
Include "TMethod_initialized.bmx"
Include "TMethod_shutdown.bmx"
Include "TMethod_dollar_cancelrequest.bmx"

const STATE_WAITING:int = 0
const STATE_RUNNING:int = 1
const STATE_COMPLETE:int = 2
'const STATE_CANCELLED:int = 3

' BASIC REQUEST TYPE
Type TMessage
    Field state:int = STATE_WAITING    ' State of the message
    Field cancelled:int = False         ' Message cancellation
    Field J:JNode                       ' Original JNode message
    Field id:int
    Method Run:String() ; End Method    ' V0.2, chnaged from Abstract to Ancestor
    ' Identify if message contains a symbol
    Method contains:int( path:string )
        'if J Publish( "log", "DEBG", J.Stringify() )
        if J and J.find( path ) Return True
        Return False
    End Method
End Type
