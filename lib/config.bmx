
'   JSON PARSER / CONFIG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	03 APR 2024, Default Config folder is:
'		WINDOWS  C:\Documents And Settings\<username>\Application Data\bls\bls.config
'		LINUX	/home/<username>/.bls/bls.config
'		MACOS   /Users/<username>/Library/Application Support/bls/bls.config

Import BRL.volumes

'Import bmx.observer
Import bmx.json

'Import "generic.bmx"
Import "trace.bmx"

Global Config:TConfig = TConfig.Start()

Type TConfig ' Extends TMap
	Field J:JSON = New JSON()
	Field filename:String

	Global instance:TConfig = Null

	Function start:TConfig()
		If Not instance; instance = New TConfig()
		Return instance
	End Function
	
    Method New()
        'logfile.write( "Config started" )
        'defaults()
		DebugStop
?win32
		filename = GetUserAppDir() + "\bls\bls.config"
?linux
		filename = GetUserAppDir() + "/.bls/bls.config"
?macos
		filename = GetUserAppDir() + "/bls/bls.config"
?
		CreateDir( ExtractDir( filename ), True )
        'Try
		' Check if file exists
		Select FileType( filename )
		Case 0  ' File does not exist
			defaults()
			save()
		Case 1  ' File exists
			readconfig( filename )
			defaults()
		'Case 2  ' Directory !!
		Default
			'Publish( "log", "WARN", "Invalid configuration file" )
			Trace.Error( "Invalid configuration file: "+filename )
		End Select
        'Catch exception:String
        '    ' Show the error, but otherwise just continue
        '    'Logfile.write( exception, "CRITICAL" )
        '    'Publish( "log", "ERRR", "ERROR: "+exception )
		'	Trace.Critical( exception )
        'End Try
		'defaults()
		'
    End Method

    Method defaults()
		If Not J.Contains("logfile") ; J.set( "logfile", "" )
		If Not J.Contains("loglevel") ; J.set( "loglevel", "5" )
		'If Not J.Contains("threadpool") ; J.set( "threadpool", "4" )
		'If Not J.Contains("transport") ; J.set( "transport", "stdio" )		' STDIO or TCP
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
			Text :+ ReadLine(file) '+EOL
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
		CreateDir( ExtractDir( filename ), True )
        Local file:TStream = WriteStream( filename )
        'WriteString( file, J.Stringify() )
        WriteString( file, J.Prettify() )
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
