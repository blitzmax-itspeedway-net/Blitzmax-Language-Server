
'	ABNF Rulebase
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	Version 0.1

Rem

sequence = "THIS" "AND" "THAT"
	
	+--------+       +--------+       +--------+       /--------\
	| "THIS" |suc--->| "AND"  |suc--->| "THAT" |suc--->|   OK   |
	+--------+       "--------+       "--------+       \--------/ 
	   null             null             null
	
alternate = "THIS" / "THAT"
	
	+--------+       /--------\ 
	| "THIS" |suc--->|   OK   |
	+--------+       \--------/ 
	   alt               |
	    |                |
	+--------+           |
	| "THAT" |suc--------/
	+--------+
	   null
	
optional = ["THIS"]
	
	+--------+       /--------\ 
	| "THIS" |suc--->|   OK   |
	+--------+       \--------/ 
	   alt               |
	    |                |
	+--------+           |
	| empty  |suc--------/
	+--------+
	   null

repetition = *"VERY"

		/-----------+
	+--------+      |
	| "VERY" |suc---+
	+--------+
	   alt 
	    |
    /--------\
	|   OK   |
	\--------/

End Rem

' Grammar Node
Type TGrammarNode
	Field alt:TGrammarNode			' Alternative Grammar Option
	Field suc:TGrammarNode			' Next Grammar Option
	Field terminal:Int = False		' True for node referencing another rule.
		' NOTE:
		'	A Terminal (True) is a node referencing another rule
		'	A Non-Terminal (False) is usually a constant like "(" or "Function"
	Field token:TToken				' The token within the node
	
	Method New( terminal:Int, token:TToken, alt:TGrammarNode=Null, suc:TGrammarNode=Null )
		Self.alt = alt
		Self.suc = suc
		Self.terminal = terminal
		Self.token = token
	End Method
End Type

'
Type TABNF
	Global rules:TStringMap = New TStringMap()
	Field name:String
	Field definition:TGrammarNode
	
	' Add a rule (Rule names are always lowercase)
	Method add( rule:String, definition:TGrammarNode )
'DebugStop
		rules.insert( Lower(rule), definition )
	End Method
	
	' Find a rule
	Method find:TGrammarNode( rule:String )
'DebugStop
'		For Local x:String = EachIn rules.keys()
'			Print x
'		Next

		Return TGrammarNode( rules.valueforkey( Lower(rule) ) )
	End Method
	
	' Get first rule name
	Method first:String()
		Local node:TStringNode = rules._FirstNode()
		If Not node Return ""
		Return node.key()
	End Method
	
End Type

