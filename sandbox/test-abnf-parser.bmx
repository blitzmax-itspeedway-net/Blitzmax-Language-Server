SuperStrict
'	ABNF PARSER TEST
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	This test will bulld a grammar tree from a given ABNF notation

Include "bin/loadfile().bmx"
Include "bin/TException.bmx"

Include "bin/TABNF.bmx"
Include "bin/TABNFLexer.bmx"
Include "bin/TABNFParser.bmx"

Include "bin/TToken.bmx"

'DebugStop
Local start:Int, finish:Int

Try
	'DebugStop
	Local source:String = loadFile( "samples/abnf.abnf" )
	'Local source:String = loadFile( "samples/bmx-build.abnf" )
	Local lexer:TLexer = New TABNFLexer( source )
	Local parser:TParser = New TABNFParser( lexer )
	
	start  = MilliSecs()
'DebugStop
	parser.parse()
	finish = MilliSecs()
	
	Print( "PARSER.TIME: "+(finish-start)+"ms" )
	
	Print( "Starting debug output...")
	Local abnf:TABNF = parser.abnf
	Print( parser.reveal() )

Catch exception:TException
	Print "## Exception: "+exception.toString()+" ##"
End Try
