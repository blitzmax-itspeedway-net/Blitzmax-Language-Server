
'   JSON PARSER / CONFIG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Global CONFIG:TConfig = New TConfig

Type TConfig Extends TMap

    Method New()
        'logfile.write( "Config started" )
        defaults()
        Try
            Local filename:String = AppDir+"/lsp.config"
            ' Check if file exists
            Select FileType( filename )
            Case 0  ' File does not exist
			    writeconfig( filename )
            Case 1  ' File exists
                readconfig( filename )
			    writeconfig( filename )
            Case 2  ' Directory?
            Default
                Logfile.write( "Invalid configuration file" )
            End Select
        Catch exception:String
            ' Show the error, but otherwise just continue
            'Logfile.write( exception, "CRITICAL" )
            DebugLog "ERROR "+exception
        End Try
    End Method

    Method defaults()
        insert( "logfile","" )
        insert( "loglevel","7" )
    End Method 

    Method readconfig( filename:String )
        Local file:TStream = ReadStream( filename )
        If Not file
            logfile.warning "Unable to open logfile"
            Return
        End If
        ' Read file into TMAP
        While Not Eof( file )
            Local line:String = Trim(ReadLine(file))
            If line="" Or line.startswith("'") Continue
            Local keyvalue:String[] = line.split("=")
            Select keyvalue.length
            Case 1  keyvalue :+ [""]
            Case 2  ' Do nothing
            Default ' Implode value
                keyvalue = [keyvalue[0],"=".join(keyvalue[1..])]
            End Select
            keyvalue[0] = Lower( Trim( keyvalue[0]) )
            keyvalue[1] = Trim( keyvalue[1] )
            If keyvalue[0] <> "" insert( keyvalue[0], keyvalue[1] )
        Wend
        file.Close()
    End Method

    Method writeconfig( filename:String )
        Local file:TStream = WriteStream( filename )
        For Local key:String = EachIn keys()
            WriteLine( file, Lower(key) + "=" +String( valueforkey( key ) )) 
        Next
        file.Close()
    End Method

	Method Operator []:String( key:String )
		Return String( valueforkey( key ) )
	End Method
End Type