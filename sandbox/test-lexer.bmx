SuperStrict
'	LEXER TEST
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	TIMINGS USING MAXIDE.BMX

'					DEBUG	PROD
'	Tlist+string	281ms	56
'	

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
	'Local parser:TParser = New TBlitzMaxParser( lexer )
	
	start  = MilliSecs()
	lexer.run()
	finish = MilliSecs()
	Print( lexer.reveal() )
	
	'Print start+"-"+finish
	Print( "LEXER.TIME: "+(finish-start)+"ms" )
	
	'parser.parse()
	'Print parser.reveal()
	'Local langserv:TLangServ = New TLangServ( parser )

	'langserv.run()
	'Print langserv.reveal()

Catch exception:TException
	Print "## Exception: "+exception.toString()+" ##"
End Try








