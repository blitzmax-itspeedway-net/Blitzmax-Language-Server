
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Type TClient_TCP Extends TClient

	Method open:Int() ; End Method
	Method Close() ; End Method
	Method read:String() ; End Method
	Method write( data:String ) ; End Method
	
End Type

