
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	initialize
'   TYPE:       Request
'
'https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialize

Type TMethod_initialize Extends TMessage
    Field id:Int
    Field jsonrpc:String
    Field methd:String
    Field params:JSON

    Method Run:String()
        Publish( "TMethod_initialize.run()" )
        LSP.initialized = True

        ' Write Client information to logfile
        If params
            'logfile.write( "PARAMS EXIST" )
            'if params.isvalid() logfile.write( "PARAMS IS VALID" )
            Local clientinfo:JSON = params.find( "clientInfo" )    ' VSCODE=clientInfo
            If clientinfo
                'logfile.write( "CLIENT INFO EXISTS" )
                Local clientname:String = clientinfo["name"]
                Local clientver:String = clientinfo["version"]
                Publish "CLIENT: "+clientname+", "+clientver
            'else
                'logfile.write( "NO CLIENT INFO EXISTS" )
            End If
        End If

        ' RESPONSE 

		'V0.2, Capabilities are managed by the LSP
		Local capabilities:JSON = lsp.capabilities

        Local response:JSON = New JSON()
        response.set( "id", id )
        response.set( "jsonrpc", "2.0" )
        'response.set( "result|capabilities", [["hover","true"]] )
        'response.set( "result|capabilities", [["hoverProvider","true"]] )
        response.set( "result|capabilities", capabilities )
        response.set( "result|serverinfo", [["name","~q"+AppTitle+"~q"],["version","~q"+version+"."+build+"~q"]] )
        Return response.stringify()

    End Method
End Type
