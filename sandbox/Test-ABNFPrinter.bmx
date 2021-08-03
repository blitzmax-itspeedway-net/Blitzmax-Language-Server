
'	ABNF Printer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	This is a tree walking algorithm used to draw the ABNF Grammar visually

Include "bin/TABNF.bmx"
Include "bin/TToken.bmx"

Include "bin/TABNFTreeWalker.bmx"

'	CREATE MANUAL ABNF
'DebugStop

Local abnf:TABNF = New TABNF()

Local _application:TGrammarNode = New TGrammarNode()
Local _module:TGrammarNode = New TGrammarNode()

' Application has no successor and "Module" as alternative
_application.terminal = False
_application.alt = _module
_application.suc = Null
_application.token = New TToken( 0, "application", 0,0,"" )

' Module has no successor and no alternative
_module.terminal = False
_module.alt = Null
_module.suc = Null
_module.token = New TToken( 0, "module", 0,0, "" )

' Create rule
abnf.add( "program", _application )		

'	Create "STRICTMODE" rule
Local _strict:TGrammarNode = New TGrammarNode()
Local _superstrict:TGrammarNode = New TGrammarNode()
Local _strictnull:TGrammarNode = New TGrammarNode()

' Strictmode can be either "strict" or "superstrict" or null
_strict.terminal = True
_strict.alt = _superstrict
_strict.suc = Null
_strict.token = New TToken( 0, "strict", 0,0, "" )

_superstrict.terminal = True
_superstrict.alt = _strictnull
_superstrict.suc = Null
_superstrict.token = New TToken( 0, "superstrict", 0,0, "" )	
	
_strictnull.terminal = True
_strictnull.alt = Null
_strictnull.suc = Null
_strictnull.token = New TToken( 0, "strictnull", 0,0, "" )		

' Create rule
abnf.add( "strictmode", _strict )

'	Create "Application" rule
Local _strictmode:TGrammarNode = New TGrammarNode()
Local _framework:TGrammarNode = New TGrammarNode()

_strictmode.terminal = False
_strictmode.alt = Null
_strictmode.suc = _framework
_strictmode.token = New TToken( 0, "strictmode", 0,0, "" )

_framework.terminal = False
_framework.alt = Null
_framework.suc = Null
_framework.token = New TToken( 0, "framework", 0,0, "" )

' Create rule
abnf.add( "application", _strictmode )	
'DebugStop

Local printer:TABNFTreeWalker = New TABNFTreeWalker( abnf )
printer.show()

