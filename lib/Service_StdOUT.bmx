SuperStrict

'   StdOUT Service for BlitzMax Language Server
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved.
'
'   VERSION: 1.0

Import bmx.observer
Import bmx.json

Import "generic.bmx"
Import "messages.bmx"
'Import "lsp_types.bmx"
Import "trace.bmx"

' Language server defines EOL as \r\n
Const EOL:String = "~r~n"

Observer.threaded()

Service_StdOUT.initialise()

Type Service_StdOUT Implements IObserver

	Global instance:Service_StdOUT
	
	Field thread:TThread	= Null	' The message queue thread
	Field mutex:TMutex
	Field sleeper:TCondVar
	
	Field queue:TList ' of JSON
	
	Field systemState:ESYSTEMSTATE = ESYSTEMSTATE.NONE
	
	Function initialise()
		If Not instance; instance = New Service_StdOUT()
	End Function

	' Start Thread
	Function start()
		If Not instance; Throw( "Failed to start StdOUT" )
		Trace.Info( "StdOUT Service starting" )
		instance.thread	= CreateThread( FN, instance )	
	End Function
		
	Method New()
		queue = New TList()
		mutex = CreateMutex()
		sleeper = CreateCondVar()
		
		' Listen for events
		Observer.on( MSG_SERVER_OUT, Self )
		Observer.on( EV_SYSTEM_STATE, Self )
		
	End Method
	
	Method Observe( id:Int, data:Object )
		
		Select id
		Case MSG_SERVER_OUT
			Local J:JSON = JSON( data )
			If Not J; Return
			LockMutex( mutex )
			queue.addlast( data )
			UnlockMutex( mutex )
			sleeper.signal()			' Wake the sleeping send-thread
		Case EV_SYSTEM_STATE
			systemstate = ESYSTEMSTATE(Int[](data)[0])	' Unbox the integer
		End Select
		
	End Method
	
	Method CheckState:Int( J:JSON )
	
		Local methd:String = J.find("method").toString()

		' We have to let replies out:
		If methd = ""; Return True

		Local id:String = Trim( J.find("id").toString() )

		Local name:String = "{-|"+iif(id="","-",id)+"|"+iif(methd="","-",methd)+"}"

		' SYSTEMSTATE IS NONE
		
		' Cannot send anything until we have heard from client
		If systemState = ESYSTEMSTATE.NONE
			Trace.debug( "STDOUT DROPPING "+name+" DURING "+systemState.toString() )

			Return False
		End If
			
		' SYSTEMSTATE IS INITIALISING
		
		If systemState = ESYSTEMSTATE.INITIALIZING
		
			Rem
			The server is not allowed to send any requests or notifications to the client until it has 
			responded with an InitializeResult, with the exception that during the initialize request 
			the server is allowed to send the notifications window/showMessage, window/logMessage and 
			telemetry/event as well as the window/showMessageRequest request to the client. 
			
			In case the client sets up a progress token in the initialize params (e.g. property workDoneToken) 
			the server is also allowed to use that token (and only that token) using the $/progress 
			notification sent from the server to the client.
			End Rem

			Select methd
			Case "$/logTrace"; Return True
			'Case "$/progress"; Return True
			Case "window/showMessage"; Return True
			Case "window/logMessage"; Return True
			Case "telemetry/event"; Return True
			Case "window/showMessageRequest"; Return True
			End Select	
			Trace.debug( "STDOUT DROPPING "+name+" DURING "+systemState.toString() )	
			Return False
		End If
		
		' Anything else is allowed
		Return True
	
	End Method
	
	' Threaded StdOUT sender
	Function FN:Object( data:Object )
		Local this:Service_StdOUT = Service_StdOUT( data )
		
		LockMutex( this.mutex )
		Repeat
			' Sleep until there is something to do!
			If this.queue.isEmpty(); this.sleeper.wait( this.mutex )
			
			' Get next message as JSON
			Local J:JSON = JSON( this.queue.removeFirst() )
			If Not J; Continue
			
			Local content:String = J.stringify()
			If Not content; Continue	' Dont bother sending empty strings!
			
			' Check system state to be sure we are allowed to send
			If Not this.checkstate( J ); Continue
			
			Trace.Info( "StdOUT, Sending: "+content )
	
			' Wrap content
			content = "Content-Length: "+Len(content)+EOL+EOL+content

			' Send to client
			StandardIOStream.WriteString( content )
			StandardIOStream.Flush()
			
			' Log the response
			Trace.Info( "StdOUT, Sent:~n"+content )
					
		Forever
	End Function

End Type
