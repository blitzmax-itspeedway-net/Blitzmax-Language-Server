SuperStrict
'	ABNF LEXER TEST
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "bin/loadfile().bmx"
Include "bin/TException.bmx"

Include "bin/TABNFLexer.bmx"

Include "bin/TToken.bmx"

DebugStop
Local lexer:TLexer
Local start:Int, finish:Int

Try
	'DebugStop
	Local source:String = loadFile( "samples/abnf.abnf" )
	'Local source:String = loadFile( "samples/blitzmaxng.abnf" )
	Local lexer:TLexer = New TABNFLexer( source )
	
	start  = MilliSecs()
	lexer.run()
	finish = MilliSecs()
	
	Print( "LEXER.TIME: "+(finish-start)+"ms" )
	
	Print( "Starting debug output...")
	Print( lexer.reveal() )

Catch exception:TException
	Print "## Exception: "+exception.toString()+" ##"
End Try
