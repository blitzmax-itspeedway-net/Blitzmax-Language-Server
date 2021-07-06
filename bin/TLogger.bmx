
'   JSON PARSER / LOGGER
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

const LOG_EMERGENCY:int = 0 
const LOG_ALERT:int     = 1
const LOG_CRITICAL:int  = 2
const LOG_ERROR:int     = 3
const LOG_WARNING:int   = 4
const LOG_NOTICE:int    = 5
const LOG_INFO:int      = 6
const LOG_DEBUG:int     = 7

Type TLogger 
    Field file:TStream
    field loglevel:int = LOG_DEBUG
    global levels:string[] = ["EMER","ALRT","CRIT","ERRR","WARN","NOTE","INFO","DEBG"]
    Method New()
        ' Set loglevel within bounds
        loglevel = min( max( int( CONFIG["loglevel"] ), 0), 7 )
        Try
            Local filename:String = trim(CONFIG["logfile"])
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
    End Method

    method timestamp:string()
        return currentDate( "%d-%m-%Y %H:%M:%S")+" "
    end method

    private
    
    Method Write( message:String, stamp:int=True )
        If Not file Return
        if stamp message = timestamp()+message
        'print message
		file.WriteLine( message )
        file.flush()
    End Method

    Public

    Method Write( message:String, severity:int, stamp:int=True )
        if loglevel < severity return
        write( levels[severity]+" "+message )
    End Method

    Method critical( message:string, stamp:int=True )
        if loglevel < LOG_CRITICAL return
        write( "CRIT "+message )
    EndMethod

    Method error( message:string, stamp:int=True )
        if loglevel < LOG_ERROR return
        write( "ERRR "+message )
    EndMethod

    Method warning( message:string, stamp:int=True )
        if loglevel < LOG_WARNING return
        write( "WARN "+message )
    EndMethod

    Method info( message:string, stamp:int=True )
        if loglevel < LOG_INFO return
        write( "INFO "+message )
    EndMethod

    method debug( message:string, stamp:int=True )
        if loglevel < LOG_DEBUG return
        write( "DEBG "+message )
    EndMethod

    Method Close()
        Self.write( "CLOSED" )
        If file file.Close()
        file = Null
    End Method
End Type