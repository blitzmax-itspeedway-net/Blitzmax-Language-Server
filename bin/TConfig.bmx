
'   JSON PARSER / CONFIG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Type TConfig ' Extends TMap
	Field J:JSON = New JSON()
	Field filename:String

    Method New()
        'logfile.write( "Config started" )
        'defaults()
        filename = AppDir+"/bls.config"
        Try
            ' Check if file exists
            Select FileType( filename )
            Case 0  ' File does not exist
			    'writeconfig( filename )
            Case 1  ' File exists
                readconfig( filename )
			    'writeconfig( filename )
            Case 2  ' Directory !!
            Default
                'Publish( "log", "WARN", "Invalid configuration file" )
				logfile.warning( "Invalid configuration file" )
            End Select
        Catch exception:String
            ' Show the error, but otherwise just continue
            'Logfile.write( exception, "CRITICAL" )
            'Publish( "log", "ERRR", "ERROR: "+exception )
			logfile.error( exception )
        End Try
		defaults()
		'
    End Method

    Method defaults()
		If Not J.Contains("logfile") ; J.set( "logfile", "" )
		If Not J.Contains("loglevel") ; J.set( "loglevel", "7" )
		'If Not J.Contains("threadpool") ; J.set( "threadpool", "4" )
		If Not J.Contains("transport") ; J.set( "transport", "stdio" )		' STDIO or TCP
    End Method 

'    Method defaults()
'		insert( "logfile","" )
'        insert( "loglevel","7" )
'        insert( "threadpool","4" )
'    End Method 

	' Read configuration and merge into existing
    Method readconfig( filename:String )
		Local file:TStream = ReadFile( filename )
		If Not file Return
		Local Text:String
		While Not Eof(file)
			Text :+ ReadLine(file)+EOL
		Wend
		CloseStream file

		J = JSON.Parse( Text )
    End Method

Rem
    Method readconfig:Int( filename:String )
        Local file:TStream = ReadStream( filename )
        If Not file Return Publish( "log", "WARN", "Unable to open logfile" )

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
        Return True
    End Method
End Rem

Rem
    Method writeconfig( filename:String )
        Local file:TStream = WriteStream( filename )
        For Local key:String = EachIn keys()
            WriteLine( file, Lower(key) + "=" +String( valueforkey( key ) )) 
        Next
        file.Close()
    End Method
End Rem

    Method save()
		If filename="" ; Return
        Local file:TStream = WriteStream( filename )
        WriteString( file, J.Stringify() )
        file.Close()
    End Method

	Method Operator []:String( key:String )
		Local JResult:JSON = J.find( key )
		If JResult Return JResult.toString()
		Return ""
'		Return String( valueforkey( key ) )
	End Method
	
	Method Operator []=( key:String, value:String )
		J.set( key, value )
	End Method
	
    ' Method to match other capability queries
    Method has:Int( path:String )
		Local key:JSON = J.find( path )
		Return key.isTrue()
	End Method

	Method isTrue:Int( path:String )
		Local key:JSON = J.find( path )
'logfile.debug( "KEY:"+key.stringify() )
		Return key.isTrue()
	End Method
	
	Method find:JSON( key:String )
		 Return J.find( key )
	End Method
	
End Type
