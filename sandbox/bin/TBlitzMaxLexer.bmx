
'	BlitzMax Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "TLexer.bmx"

Type BlitzMaxLexer Extends TLexer

	Method New( text:String )
		Super.New( text )
		Print "Starting MAXLexer"
		
		' Define Lexer options
		linecomment_symbol = "'"
		valid_symbols      = "#$%()*+,-.:;<=>[]^"
		compound_symbols   = "<> >= <= :+ :- :* :/ .."
		
		' Language specific definitions
		Local data:String[]
		RestoreData bmx_expressions
		define( "expression", loadTable() )
		RestoreData bmx_reservedwords
		define( "reserved", loadTable() )

		' For debugging:
		include_comments = True
	End Method

	Method loadtable:String()
		Local line:String
		Local word:String 
		ReadData( word )
		Repeat
			line:+ "["+word+"]"
			ReadData( word )
		Until word = "#"
		Return word
	End Method

	Method LexAlpha:TSymbol( text:String, line:Int, pos:Int )
		Local criteria:String = "["+Lower(text)+"]"	' Case insensitive search criteria
		For Local token:String = EachIn tokens.keys()
			If Instr( String(tokens[token]), criteria ) Return New TSymbol( token, Lower(text), line, pos )
		Next
		Return New TSymbol( "alpha", text, line, pos )
	End Method
		
End Type

' Blitzmax Tables
#bmx_expressions
DefData "and","false","mod","new","not","null","or","pi","sar","self","shl","shr","sizeof","super","true","varptr"
DefData "#"

#bmx_reservedwords
DefData "alias","and","asc","assert"
DefData "byte"
DefData "case","catch","chr","const","continue"
DefData "defdata","default","delete","double"
DefData "eachin","else","elseif","end","endextern","endfunction","endif","endinterface","endmethod","endrem","endselect","endstruct","endtry","endtype","endwhile","exit","export","extends","extern"
DefData "false","field","final","finally","float","for","forever","framework","function"
DefData "global","goto"
DefData "if","implements","import","incbin","incbinlen","incbinptr","include","int","interface"
DefData "len","local","long"
DefData "method","mod","module","moduleinfo"
DefData "new","next","nodebug","not","null"
DefData "object","operator","or"
DefData "pi","private","protected","ptr","public"
DefData "readdata","readonly","release","rem","repeat","restoredata","return"
DefData "sar","select","self","shl","short","shr","sizeof","size_t","step","strict","string","struct","super","superstrict"
DefData "then","throw","to","true","try","type"
DefData "uint","ulong","until"
DefData "var","varptr"
DefData "wend","where","while"
DefData "#"