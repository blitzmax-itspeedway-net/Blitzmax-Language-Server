
'	ABNF Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "lexer-const-abnf.bmx"
Include "TLexer.bmx"

Type TABNFLexer Extends TLexer

	Method New( text:String )
		Super.New( text )
		Print "Starting ABNF XLexer"
		
		'DebugStop

		' Add compound symbols to definition
		RestoreData abnf_compound_symbols
		readCompoundSymbols()
		
		' Add tokens to definition
		'RestoreData abnf_symbols
		'readSymbols()

		'RestoreData abnf_terminals
		'readTokens()

	End Method

	' Read symbols and add as tokens
	Method readTokens()
		Local id:Int, class:String
		ReadData id, class
		Repeat
			defined.insert( class, New TSymbol( id, class, class ) )
			ReadData id, class
		Until id = 0
	End Method

	' Read CompoundSymbols and add as tokens
	Method readCompoundSymbols()
		Local id:Int, value:String, class:String
		ReadData id, value, class
		Repeat
			defined.insert( value, New TSymbol( id, class, value ) )
			ReadData id, value, class
		Until id = 0
	End Method

	' Read symbols and add as tokens
	Method readSymbols()
		Local id:Int, value:String, class:String
		ReadData id, value, class
		Repeat
			lookup[Asc(value)]=class
			ReadData id, value, class
		Until id = 0
	End Method
		
End Type

' ABNF Tables

' Compound Symbols
#abnf_compound_symbols
'		ID				VALUE	CLASS
DefData TK_HEXDIGIT,    "%x",	"hexdigit"
DefData 0,"#","#"

