SuperStrict
'	LEXER TEST USING REGEX
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Import Text.RegEx
Include "bin/loadfile().bmx"

Local start:Int, finish:Int

'Local source:String = loadFile( "samples/capabilites.bmx" )
Local source:String = loadFile( "samples/maxide.bmx" )

start  = MilliSecs()

Const COMMENT:String = "('[^\n]*)"
Const QSTRING:String = "(~q[\x20\x21\x23-\x7E]+~q)"
Const ALPHA:String = "([A-Za-z][A-Za-z0-9_]*)"
Const COMPOUND:String = "(\x2E\x2E|<>|<=|>=|:\+|:\*|:\/|:\-|:&|:\||:~~)"
Const NUMERIC:String = "([0-9]*(\.[0-9]*)?)"
Const SYMBOLS:String = "([\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E])"
Const EOL:String = "(\x0D)"
Local regex:TRegEx = TRegEx.Create( COMMENT+"|"+QSTRING+"|"+ALPHA+"|"+NUMERIC+"|"+COMPOUND+"|"+SYMBOLS+"|"+EOL )
Local matches:TRegExMatch = regex.find( source )

DebugStop

Print matches.subcount()
'DebugStop
While matches
	Local sym:String = matches.subExp()
	If Asc(sym)=13 sym="EOL"
	'Print sym
	matches = regex.find()
Wend

finish = MilliSecs()

Print( "LEXER.TIME: "+(finish-start)+"ms" )











