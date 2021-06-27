
Type TLogger 
    Field file:TStream
    Method New()
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

    Method Write( message:String, stamp:int=True )
        If Not file Return
        if stamp message = timestamp()+message
        'print message
		file.WriteLine( message )
        file.flush()
    End Method

    Method Write( message:String, severity:string, stamp:int=True )
        If Not file Return
        write( severity[..8]+ " "+message )
    End Method

    Method Close()
        Self.write( "CLOSED" )
        If file file.Close()
        file = Null
    End Method
End Type