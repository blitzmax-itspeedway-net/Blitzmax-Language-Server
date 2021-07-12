'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   LOGGING

Const LOG_EMERGENCY:Int = 0 
Const LOG_ALERT:Int     = 1
Const LOG_CRITICAL:Int  = 2
Const LOG_ERROR:Int     = 3
Const LOG_WARNING:Int   = 4
Const LOG_NOTICE:Int    = 5
Const LOG_INFO:Int      = 6
Const LOG_DEBUG:Int     = 7

Local Logfile:TLogger = New TLogger()
Type TLogger Extends TObserver
    Field file:TStream
    Field loglevel:Int = LOG_DEBUG
    Global levels:String[] = ["EMER","ALRT","CRIT","ERRR","WARN","NOTE","INFO","DEBG"]

    Method New()
        ' Set loglevel within bounds
        loglevel = Min( Max( Int( CONFIG["loglevel"] ), 0), 7 )
        Try
            Local filename:String = Trim(CONFIG["logfile"])
            'filename="/home/si/dev/LSP/runlog.txt"
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
        Subscribe( ["log","info","debug","error","critical","exitnow","cancelrequest"] )
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
    Method Notify( event:String, data:Object, extra:Object )
        Local datastr:String = String(data)
        Local extrastr:String = String(extra)
        'debugstop
        Select event
        Case "log"
            WriteFile( datastr[..4]+" "+extrastr )
        Case "info"
            WriteFile( "INFO "+datastr )
            WriteErr( datastr )
        Case "debug"
            WriteFile( "DEBG "+datastr )
            If DEBUGGER WriteErr( "# "+datastr )
        Case "error"
            WriteFile( "ERRR "+datastr )
            WriteErr( "# "+datastr )
        Case "critical"
            WriteFile( "CRIT "+datastr )
            WriteErr( "# "+datastr )
        'case "receive","send"
        '    debug( upper(event)+":" )
        '    debug( extrastr )
        Case "cancelrequest"
            Local node:JSON = JSON( data )
            If node debug( "CANCEL: "+node.toint() )
        Case "exitnow"
            debug( "TLogger is closing" )
            Close()
        Default
            error( "TLogger: event '"+event+"' ignored")
        End Select
    End Method

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

    Method Close()
        Self.WriteFile( "CLOSED" )
        If file file.Close()
        file = Null
    End Method
End Type