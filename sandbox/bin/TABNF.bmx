
'	ABNF Rulebase
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	Version 0.0

'
Type TABNF
	Global rules:TStringMap = New TStringMap()
	Field name:String
	Field definition:TGNode
	
	' Add a rule (Rule names are always lowercase)
	Method add( rule:String, definition:TGnode )
DebugStop
		rules.insert( Lower(rule), definition )
	End Method
	
	' Find a rule
	Method find:TGNode( rule:String )
debugstop
		Return TGNode( rules.valueforkey( Lower(rule) ) )
	End Method
	
End Type

' Grammar Node
Type TGNode
	Field terminal:Int = False		' True for leaf nodes
	Field alt:TGNode
	Field suc:TGNode
	Field sym:TSymbol
End Type