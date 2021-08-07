
'	ABNF Rulebase
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	Version 0.2

Rem

sequence = "THIS" "AND" "THAT"
	
	+--------+       +--------+       +--------+       /--------\
	| "THIS" |suc--->| "AND"  |suc--->| "THAT" |suc--->|   OK   |
	+--------+       "--------+       "--------+       \--------/ 
	   null             null             null
	
alternate = "THIS" / "THAT"
	
	+--------+       /--------\ 
	| group  |suc--->|   OK   |
	+--------+       \--------/ 
	   alt        
	    |         
	+--------+    
	| "THIS" |null
	+--------+
	   alt        
	    |         
	+--------+    
	| "THAT" |null
	+--------+
	   null
	
optional = ["THIS"]
	
	+--------+       /--------\ 
	| option |suc--->|   OK   |
	+--------+       \--------/ 
	   opt        
	    |         
	+--------+    
	| "THIS" |null
	+--------+
	   opt        
	    |         
	+--------+    
	| empty  |null
	+--------+
	   null

repetition = *"VERY"

	+--------+       /--------\ 
	| repeat |suc--->|   OK   |
	+--------+       \--------/ 
	   opt        
	    |         
	+--------+    
	| "VERY" |null
	+--------+
	   null        

End Rem

' Grammar Node
Type TGrammarNode
	Field alt:TGrammarNode			' Alternative Grammar Option (When using "/")
	Field suc:TGrammarNode			' Next Grammar Option
	Field opt:TGrammarNode			' Used for children lists (Repeat, Group, Options)
		' NOTE:
		'	Added on version 0.2
		'	Previously repeat was put in alt, but this statement then failed:
		'		rule = THIS / *THAT / ANOTHER
		'	It failed because *THAT put the option into alt, but ANOTHER overwrote it
	Field terminal:Int = False		' False for node referencing another rule.
		' NOTE:
		'	A Terminal (True) is usually a constant like "(" or "Function"
		'	A Non-Terminal (False) is a node referencing another rule
	Field token:TToken				' The token within the node

	' These fields are used for debugging the tree
	'Field x:Int = 0
	'Field y:Int = 0
	Field level:Int = 0
	Field column:Int =0
	
	Method New( terminal:Int, token:TToken, alt:TGrammarNode=Null, suc:TGrammarNode=Null )
		Self.alt = alt
		Self.suc = suc
		Self.terminal = terminal
		Self.token = token
	End Method
End Type

'
Type TABNF
	Field rules:TStringMap = New TStringMap()
	Field _first:String
	'Field name:String
	'Field definition:TGrammarNode
	
	' Add a rule (Rule names are always lowercase)
	Method add( rule:String, definition:TGrammarNode )
'DebugStop
Print( "Adding rule "+rule )
		If _first = "" _first = Lower(rule)
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
		'DebugStop
		'For Local key:String = EachIn rules.keys()
		'	Print "RULE: "+key
		'Next
	
		'Local node:TStringNode = rules._FirstNode()
		'If Not node Return ""
		'Return node.key()
		
		Return _first
	End Method
	
	' Debug rules
	' NOTE: THIS IS NOT A GOOD TREE VISUALISER
	' TODO: Improve this (Maybe use a visitor?)
	Method reveal:String()
'DebugStop
		Local result:String
		For Local rule:String = EachIn rules.keys()
			Local node:TGrammarNode = TGrammarNode( rules[rule] )
			result :+ Upper(rule)+"~n"
			result :+ reveal_sequence( node,2 )
		Next
		Return result	
	End Method

	Private

	Method space:String( length:Int )
		Return " "[..length]
	End Method

	Method pad:String( text:String, length:Int )
		Return text[..length]
	End Method
	
	Method reveal_sequence:String( node:TGrammarNode, indent:Int=0 )
'DebugStop
		Local result:String
		
		Repeat
			If node = Null
				result :+ space(indent) + "NULL~n"
			Else
				Select node.token.id
				Case TK_Repeater
					result :+ space(indent) + "REPEAT:"
					reveal_sequence( node.opt, indent+2 )
				Default
					result :+ space(indent) + node.token.value
				End Select
			End If
			If node.alt
				Local alt:TGrammarNode = node.alt
				'result :+ space(indent+1) + "alt: " 
				While alt
					result :+ " | "+ alt.token.value
					alt = alt.alt
				Wend
			End If
			result :+ "~n"
			If node.opt
				Local opt:TGrammarNode = node.opt
				result :+ space(indent+1) + "opt: " 
				While opt
					result :+ " | "+ opt.token.value
					opt = opt.opt
				Wend
				result :+ "~n"
			End If
			
			node = node.suc			
		Until node = Null

		Return result
	End Method
	
End Type


