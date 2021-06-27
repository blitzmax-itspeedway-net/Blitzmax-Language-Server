
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	initialize
'   TYPE:       Request
'
'https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialize

Type TMethod_initialize Extends TMessage
    field id:int
    Field jsonrpc:String
    Field methd:String
    field params:JNode

    Method Execute()
        Logfile.write( "TMethod_initialize.execute()" )
        LSP.initialized = true

        ' Write Client information to logfile
        if params
            'logfile.write( "PARAMS EXIST" )
            'if params.isvalid() logfile.write( "PARAMS IS VALID" )
            local clientinfo:JNode = params.find( "clientInfo" )    ' VSCODE=clientInfo
            if clientinfo
                'logfile.write( "CLIENT INFO EXISTS" )
                local clientname:string = clientinfo["name"]
                local clientver:string = clientinfo["version"]
                logfile.write "CLIENT: "+clientname+", "+clientver
            'else
                'logfile.write( "NO CLIENT INFO EXISTS" )
            end if
        end if

        ' RESPONSE 

        local response:JNode = JSON.create()
        response.set( "id", id )
        response.set( "jsonrpc", "2.0" )
        response.set( "result|capabilities", [["hover","true"]] )
        'response.set( "result|capabilities", [["hoverProvider","true"]] )
        response.set( "result|serverinfo", [["name","~q"+apptitle+"~q"],["version","~q"+version+"."+build+"~q"]] )
        respond( response.stringify() )

    End Method
End Type
