SuperStrict

'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'
'   FILE LOGGING

'	03 APR 2024, Default logging folder is:
'		WINDOWS  C:\Documents And Settings\<username>\Application Data\bls\bls.log
'		LINUX	/home/<username>/.bls/bls.log
'		MACOS   /Users/<username>/Library/Application Support/bls/bls.log
'	This can be overwridden in bls.config, logfile=

Import BRL.volumes

Import bmx.observer
Import bmx.json

'Import "messages.bmx"
'Import "trace.bmx"
'Import "tasks.bmx"
Import "config.bmx"

Global logfile:TLogfile = New TLogfile()

Type TLogfile Implements IObserver

	Field file:TStream
	Field loglevel:Int = SEVERITY.DEBUG.ordinal()
	
	Method New()	' filename:String )
		'DebugStop
        ' Set loglevel from config within bounds
        loglevel = Min( Max( Int( CONFIG["loglevel"] ), 0), 7 )
        Try
			'DebugStop
            Local filename:String = Trim(CONFIG["logfile"])
            If Not filename 'Or filename = ""
				' Revert to default log location
				filename = GetUserAppDir() + "/.bls/bls.log"
			End If
			CreateDir( ExtractDir( filename ), True )

			file = OpenStream( filename, False, WRITE_MODE_APPEND )
			If Not file; Throw( "Unable to open logfile" )
			
			'If file SeekStream( file, file.Size())
			'If file file.seek( file.size(), SEEK_SET_ )
			Write( SEVERITY.INFO, "=======================================================" )
			Write( SEVERITY.INFO, "Logging Started" )
			Write( SEVERITY.INFO, "LOG LEVEL="+loglevel )
 
			' Listen for all messages
			'Observer.debug( Self )
			
			' Application Events:
			Observer.on( LOGTRACE, Self )
			'Observer.on( MSG_CLIENT_IN, Self )
			'Observer.on( MSG_SERVER_OUT, Self )
			'Observer.on( EV_TASK_ADD, Self )
			'Observer.on( EV_TASK_CANCEL, Self )

			' Set exit procedure to close files
			OnEnd( ExitProcedure )

        Catch exception:String
            ' Show the error, but otherwise just continue
            Trace.error( "TLogfile.new() EXCEPTION: "+exception )
            'Print "ERROR "+e
			Return
        End Try
    End Method

	Method Observe( ID:Int, data:Object )
        If Not file Return
		Select ID 
		Case LOGTRACE
			Local logdata:Trace = Trace( data )
			If Not logdata; Return
			If loglevel < logdata.level.ordinal(); Return
			Write( logdata.level, logdata.message )
		'Case MSG_CLIENT_IN
		'	Local J:JSON = JSON( data )
		'	If Not J
		'		WriteSummary( ID )
		'		Return
		'	End If
		'	Local message:String = J.stringify()
		'	If Len(message) > 80; message = message[..80]+".."
		'	Write( SEVERITY.DEBUG, "MESSAGE IN "+message )
		'Case MSG_SERVER_OUT
		'	Local J:JSON = JSON( data )
		'	If Not J
		'		WriteSummary( ID )
		'		Return
		'	End If
		'	Local message:String = J.stringify()
		'	If Len(message) > 80; message = message[..80]+".."
		'	Write( SEVERITY.DEBUG, "MESSAGE OUT "+message )
		'Case EV_TASK_ADD
		'	Local task:TTask = TTask( data )
		'	If Not task
		'		WriteSummary( ID )
		'		Return
		'	End If
		'	Write( SEVERITY.DEBUG, "ADD TASK "+task.name )
		'Case EV_TASK_CANCEL
		'	Local task:TTask = TTask( data )
		'	If Not task
		'		WriteSummary( ID )
		'		Return
		'	End If
		'	Write( SEVERITY.DEBUG, "CANCEL TASK "+task.name )
		Default
			WriteSummary( ID )
		End Select
	End Method
	
	Method WriteSummary( ID:Int )
		Write( SEVERITY.INFO, "["+Hex(ID)+"] "+observer.name(ID) )
	End Method

    Method timestamp:String()
        Return CurrentDate( "%d-%m-%Y %H:%M:%S")+" "
    End Method

    Method Write( sev:severity, message:String, stamp:Int=True )
?debug
		'DebugLog( "TLogfile.write() "+SYSLOG[severity] + " " + message )
?
        If Not file Return
        ' Send Errors and warnings to the client "output" window
		'If severity < 5; WriteStderr( SYSLOG[severity] + " " + message )
		' Write to file
		'Local sev:Int = level.ordinal()
        If stamp
			file.WriteLine( timestamp() + " " + Trace.Prefix(sev) + " " + message )
        Else
			file.WriteLine( Trace.Prefix(sev) + " " + message )
		End If
        ' Send to the log file.
        file.flush()
    End Method

'    Method WriteErr( message:String )
'        WriteStderr( message+"~n")      
'    End Method


	' Use the language servers "trace" level to support messaging
'	Method trace( message:String, verbose:String="" )
'
'		Write( "TRAC LEVEL: "+lsp.trace )	
'		Write( "TRAC MESSAGE: "+message )	
'		If verbose<>"" ; Write( "TRAC VERBOSE: "+verbose )
'		
'		If lsp.trace = "off" ; Return	' Client doesn't want to know!
'		
'		Local logTrace:JSON = EmptyResponse( "$/logTrace" )
'		logTrace.set( "params|message", message )
'		If lsp.trace = "verbose" And verbose<>"" ; logTrace.set( "params|verbose", verbose )
'
'		lsp.send( logTrace )
'		'
'	End Method
	
	Function ExitProcedure()
		If logfile And logfile.file
			logfile.Write( SEVERITY.INFO, "LOGFILE: ExitProcedure(), Closing logfile" )
			logfile.file.Close()
			logfile.file = Null
		End If
	End Function

End Type



