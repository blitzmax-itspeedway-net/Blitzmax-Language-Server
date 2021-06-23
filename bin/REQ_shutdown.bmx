
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	REQUEST:	initialize
'	RESPONSE:	

Type REQ_shutdown Extends TRequest
    'Field id:int
    Field jsonrpc:String
    Field methd:String

    Method Execute()
Logfile.write( "LSP_shutdown.execute() " )

        local error:int = false

        local response:string = "{~qid~q:<ID>,~qresult~q:null,~qparams~q:{}}"
        response = response.replace( "<ID>", id )
        Logfile.write( "RESPONSE:" )
        Logfile.write( response )
        'local response:TResponse
        'if error
        '    response = new TResponseFailure()
        'else
        '    response = new TResponseSuccess()
        'end if
        'response.id = id


        ' Send response to StdOut
        'local jtext:string = JSON.Stringify( response )
        print response

    End Method

End Type
