
'	ABNF Tree Walker
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

' Provides visual representation of an ABNF rule

Type TABNFTreeWalker

	Const MARGINX:Int = 10
	Const MARGINY:Int = 30
	Const GAPX:Int=20
	Const GAPY:Int=20
	Const PADX:Int=5
	Const PADY:Int=5
	Global TH:Int 		' Text height

	Field root:TGrammarNode
	Field abnf:TABNF
	Field name:String

	' Pointers for creating the tree
	Field level:Int, column:Int	', nextcolum:Int
	Field width:Int = 0		' Width of columns

	Method New( abnf:TABNF )
		Self.abnf = abnf
		Graphics(800,600)
		TH = TextHeight("8g")
	End Method
	
	Method Position( rule:String)
		Self.name = rule
		Self.root = abnf.find( rule )
		column = 0
		level  = 0
	
		' Walk the tree, allocating metrics
		'DebugStop
		_position( root )
		
	End Method
		
	Private
	
	Method _position( node:TGrammarNode )
'DebugStop
		Local thiscolumn:Int = column
		Local thislevel:Int = level
		node.level = thislevel
		node.column = thiscolumn
		
		' FORCE TOKEN IF NULL TO IDENTIFY ISSUE WITHOUT THROWING ERROR
		If Not node.token ; node.token = New TToken( TK_EOF, "ERROR",0,0,"ERROR" )
		'node.x = xpos
Print node.token.value[..20] + String(node.level)[..5] + String(node.column)[..5] 
'DebugStop	
		' Obtain Metrics for THIS column (LOOP THROUGH ALT)
		width = Max( TextWidth(node.token.value), width )
		'Local child:TGrammarNode = node.alt
		If node.alt
			level :+ 1
			'width = Max( width[thiscolumn], _position( node.alt ))
			_position( node.alt )
		End If
		'While child
		'	level :+ 1
		'	width[thiscolumn] = Max( width[thiscolumn], _position( child ))
		'	child = child.alt
		'Wend
		
		
		' LOOP THROUGH SUCCESSOR
		If node.suc
		'child = node.suc
		'While child
			column :+ 1
			'width :+ [0]
			'width = Max( width, _position( node.suc ))
			_position( node.suc )
			'child = child.suc
		'Wend
		End If
		
		'Return width[thiscolumn] 
	End Method
	
	Method show()

		Local rules:String[]
		Local cursor:Int = 0

		' Obtain a list of rules
		Print "RULES:"
		For Local key:String = EachIn abnf.rules.keys()
			rules :+ [key]
			Print "* "+key
		Next
'DebugStop
		position(rules[0])
		Repeat
			Cls
			If KeyHit( KEY_LEFT )
				cursor :- 1
				If cursor < 0 cursor = Len(rules)-1
				position(rules[cursor])
			End If
			If KeyHit( KEY_RIGHT )
				cursor :+ 1
				If cursor >= Len(rules) cursor = 0
				position(rules[cursor])
			End If
			
			SetColor( $ff,$ff,$ff)
			DrawText(name,0,0)
			_draw( root )
			'column = 0
			
			SetColor( $ff,$ff,$ff)
			DrawText( "LEFT / RIGHT", 0, GraphicsHeight()-TH )
			Flip
		Until KeyHit(KEY_ESCAPE) Or AppTerminate()
		
	End Method
		
	Method _draw( node:TGrammarNode )
'DebugStop
		Local w:Int = width + PADX*2
		Local x:Int = MARGINX + (node.column*w) + (node.column*GAPX)' + (node.column*PADX*2)
		Local h:Int = TH+PADY*2
		Local y:Int = MARGINY + (node.level*h) + (node.level*GAPY)
		
		'debugstop
		
		SetColor( $9d,$b5,$88 )
		DrawRect( x,y,w,h )
		SetColor( $ff,$ff,$ff )
		DrawText( node.token.value, x+PADX, y+PADY )
		
		' LOOP THROUGH ALTERNATIVES
		
		Local child:TGrammarNode = node.alt
		While child
			SetColor( $ff,$ff,$ff )
			DrawLine( x+(w/2), y+h, x+(w/2), y+h+GAPY )
			_draw( child )			
			child = child.alt
		Wend
		
		' LOOP THROUGH SUCCESSORS
		
		child = node.suc
		While child
			'xpos :+ width+GAPX
			SetColor( $ff,$ff,$ff )
			DrawLine( x+w, y+(h/2), x+w+GAPX, y+(h/2) )
			_draw( child )
			child = child.suc
		Wend
			
	End Method
	
End Type