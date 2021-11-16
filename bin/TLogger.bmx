'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   LOGGING

Type TLogger Extends TEventHandler
    Field file:TStream
    Field loglevel:Int = LOG_DEBUG
    Global levels:String[] = ["EMER","ALRT","CRIT","ERRR","WARN","NOTE","INFO","DEBG"]

    Method New()
        ' Set loglevel within bounds
        loglevel = Min( Max( Int( CONFIG["loglevel"] ), 0), 7 )
        Try
            Local filename:String = Trim(CONFIG["logfile"])
            'filename="/home/si/dev/LSP/runlog.txt"
'Print "FILENAME: "+filename
'Print "LOGLEVEL: "+loglevel
            If filename<>"" 
                'file = AppendStream:TStream( filename )
				file = OpenStream( filename, False, WRITE_MODE_APPEND )
				'If file SeekStream( file, file.Size())
                'If file file.seek( file.size(), SEEK_SET_ )
            End If
            'Print "- Opening log"
            'Self.write( "Logger started" )
        Catch exception:String
            ' Show the error, but otherwise just continue
            DebugLog( exception )
            'Print "ERROR "+e
        End Try
        '
        ' Start message observer
        'Subscribe( ["log","info","debug","error","critical","exitnow","cancelrequest"] )
		Register()
    End Method

    Method timestamp:String()
        Return CurrentDate( "%d-%m-%Y %H:%M:%S")+" "
    End Method

    Private
    
    Method WriteFile( message:String, stamp:Int=True )
        If Not file Return
        If stamp message = timestamp()+message
        ' Send to the client "output" window
        'writeStdErr( message )      
        ' Send to the log file.
		file.WriteLine( message )
        file.flush()
    End Method

    Method WriteErr( message:String )
        WriteStderr( message+"~n")      
    End Method

    ' Observations
' DEPRECIATED 25/10/21
'    Method Notify( event:String, data:Object, extra:Object )
'        Local datastr:String = String(data)
'        Local extrastr:String = String(extra)
        'debugstop
'        Select event
'        Case "log"
'            WriteFile( datastr[..4]+" "+extrastr )
'        Case "info"
'            WriteFile( "INFO "+datastr )
'            WriteErr( datastr )
'        Case "debug"
'            WriteFile( "DEBG "+datastr )
'            If DEBUGGER WriteErr( "# "+datastr )
'        Case "error"
'            WriteFile( "ERRR "+datastr )
'            WriteErr( "# "+datastr )
'        Case "critical"
'            WriteFile( "CRIT "+datastr )
'            WriteErr( "# "+datastr )
'        'case "receive","send"
'        '    debug( upper(event)+":" )
'        '    debug( extrastr )
'        Case "cancelrequest"
'            Local node:JSON = JSON( data )
'            If node debug( "CANCEL: "+node.toint() )
'        Case "exitnow"
'            debug( "TLogger is closing" )
'            Close()
'        Default
'            error( "TLogger: event '"+event+"' ignored")
'        End Select
'    End Method

    Public

    Method WriteFile( message:String, severity:Int, stamp:Int=True )
        If loglevel < severity Return
        WriteFile( levels[severity]+" "+message )
    End Method

    Method critical( message:String, stamp:Int=True )
        If loglevel < LOG_CRITICAL Return
        WriteFile( "CRIT "+message )
    EndMethod

    Method error( message:String, stamp:Int=True )
        If loglevel < LOG_ERROR Return
        WriteFile( "ERRR "+message )
    EndMethod

    Method warning( message:String, stamp:Int=True )
        If loglevel < LOG_WARNING Return
        WriteFile( "WARN "+message )
    EndMethod

    Method info( message:String, stamp:Int=True )
        If loglevel < LOG_INFO Return
        WriteFile( "INFO "+message )
    EndMethod

    Method debug( message:String, stamp:Int=True )
        If loglevel < LOG_DEBUG Return
        WriteFile( "DEBG "+message )
    EndMethod

	' Use the language servers "trace" level to support messaging
	Method trace( message:String, verbose:String="" )

		WriteFile( "TRAC LEVEL: "+lsp.trace )	
		WriteFile( "TRAC MESSAGE: "+message )	
		If verbose<>"" ; WriteFile( "TRAC VERBOSE: "+verbose )
		
		If lsp.trace = "off" ; Return	' Client doesn't want to know!
		
		Local logTrace:JSON = EmptyResponse( "$/logTrace" )
		logTrace.set( "params|message", message )
		If lsp.trace = "verbose" And verbose<>"" ; logTrace.set( "params|verbose", verbose )

		lsp.send( logTrace )
		'
	End Method

    Method Close()
        Self.WriteFile( "CLOSED" )
        If file file.Close()
        file = Null
    End Method

	' V4 EVENT HANDLERS
	
	Method on_exit:JSON( message:TMessage )
		Close()
	End Method
	
End Type



