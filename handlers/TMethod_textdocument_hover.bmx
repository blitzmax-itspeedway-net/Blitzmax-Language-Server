
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	textdocument/hover
'   TYPE:       Request
'
'https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_hover

Type TMethod_textdocument_hover Extends TMessage
    ' Commented out as we don't actually need them
    'Field jsonrpc:String
    'Field methd:String
    'field params:TMap 

    Method Run:string()
        Logfile.write( "TMethod_textdocument_hover.run()" )
        
    End Method

End Type
