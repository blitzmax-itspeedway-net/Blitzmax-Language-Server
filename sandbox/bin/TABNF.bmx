
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
	   alt        
	    |         
	+--------+    
	| "THIS" |null
	+--------+
	   alt        
	    |         
	+--------+    
	| empty  |null
	+--------+
	   null

repetition = *"VERY"

	+--------+       /--------\ 
	| repeat |suc--->|   OK   |
	+--------+       \--------/ 
	   rep        
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
	Field terminal:Int = False		' True for node referencing another rule.
		' NOTE:
		'	A Terminal (True) is a node referencing another rule
		'	A Non-Terminal (False) is usually a constant like "(" or "Function"
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
	Global rules:TStringMap = New TStringMap()
	Field name:String
	Field definition:TGrammarNode
	
	' Add a rule (Rule names are always lowercase)
	Method add( rule:String, definition:TGrammarNode )
'DebugStop
Print( "Adding rule "+rule )
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
	
	' Debug rules
	Method reveal:String()
DebugStop
		Local result:String
		For Local rule:String = EachIn rules.keys()
			result :+ Upper(rule)+"~n"
			result :+ revealRule( rule )
		Next
		Return result	
	End Method
	
	Method revealRule:String( rulename:String )
DebugStop
		Local sheet:String[][]
		Local node:TGrammarNode = TGrammarNode( rules[rulename] )
		sheet :+ []	' results column
		sheet :+ [walkAlt( node )]
		While node.suc <> Null
			sheet :+ [walkAlt( node )]
		Wend
		' Pass through each row and column, getting widths and then building table
		Local result:String = ""
		Local width:Int
		Rem
		For Local x:Int = 1 Until sheet.dimensions()[0]
			' Calculate width f column
			width = 0
			For Local y:Int = 0 Until sheet[x].dimensions()[0]
				width = Max( width, Len( sheet[x][y] ) )
			Next
			For Local y:Int = 0 Until sheet[x].dimensions()[0]
				sheet[0][y] :+ (sheet[x][y] )[..width]+"  "
			Next
		Next
		' Join first columns into a single string
		For Local y:Int = 0 Until sheet.dimensions()[0]
			result :+ sheet[0][y]+"~n"
		Next
		End Rem
		Return result
	End Method
	
	Private 
	
	Method walkAlt:String[]( node:TGrammarNode )
		Local row:String[]
		row :+ [node.token.value]
		While node.alt <> Null
			node = node.alt
		Wend
		Return row
	End Method
	
End Type


