
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' The Message Queue listens for messages on a thread and adds them to a queue ready for
' parsing

Type TMessageQueue
    global requestThread:TThread

    Method new()
        ' Start the listener
        requestThread = CreateThread( Listener, null )
        ' Start the responder
        respondThread = CreateThread( Responder, null )
        ' 
    End Method

    ' Thread that listens for incoming messages
    Function Listener()

        ' Create a mutex  

    End Function

    ' Thread that responds to client
    Function Responder()
    end Function

End Type