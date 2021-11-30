
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	This type is ONLY used as an interface to the database

Type TDBDocument

	Field uri:String
	Field size:Int
	Field date:Long
	Field checksum:String
	
	Method New( record:TQueryRecord )
		uri = record.getStringByName( "uri" )
		size = record.getIntbyName( "filesize" )
		date = record.getIntbyName( "filedate" )
		checksum = record.getStringByName( "checksum" )
	End Method
	
End Type
