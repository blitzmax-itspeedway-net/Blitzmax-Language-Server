SuperStrict
'	LEXER TEST
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	TIMINGS USING MAXIDE.BMX

'	DEBUG	PROD
'	281ms	56ms	Tlist+string - Incomplete symbols.
'	307ms	74ms	Tlist+integer (Symbols in defined:TMap)
'	269ms	60ms	Tlist+integer (Symbols in string[])

Include "bin/loadfile().bmx"
Include "bin/TException.bmx"

Include "bin/TBlitzMaxLexer.bmx"

Include "bin/TToken.bmx"

'DebugStop
Local lexer:TLexer
Local start:Int, finish:Int

Try
	'DebugStop
	'Local source:String = loadFile( "samples/capabilites.bmx" )
	Local source:String = loadFile( "samples/maxide.bmx" )
	Local lexer:TLexer = New TBlitzMaxLexer( source )
	
	start  = MilliSecs()
	lexer.run()
	finish = MilliSecs()
	
	Print( "LEXER.TIME: "+(finish-start)+"ms" )
	
	Print( "Starting debug output...")
	Print( lexer.reveal() )

Catch exception:TException
	Print "## Exception: "+exception.toString()+" ##"
End Try








