SuperStrict
'
'	TESTING documentSync / Change / Open
'
'	Text editor based on R-War ingame code editor
'	(c) Copyright Si Dunford, Aug 2013, All Right Reserved

' BEFORE YOU ASK:
' YES:	It would be quicker to not load it as lines, join it and then split it here.
' 		But the LSP Client sends it as a chunk, so I need to emulate it.

Import Text.RegEx

Include "loadfile().bmx"

Type TSourceDocument
	Field sourcecode:String
	Field lines:String[]
	
	Method New( text:String )
		onOpen( text )
	End Method
	
	Method wordAt:String( line:Int, pos:Int )
	End Method
	
	Method onOpen( text:String )
		sourcecode = text

		' For the test we will change tabs to spaces
		' because drawtext() ignores them
		sourcecode = sourcecode.Replace("~t","  ")
		
		' Split it into lines
		lines = sourcecode.split( "~r~n" )

		'Print( "LINES: " + lines.length )
		'For Local n:Int = 0 Until lines.length
		'	Print RSet(n+1,4)+"  "+lines[n]
		'Next
		
' -> VERY INEFFICIENT CODE HERE 
' -> TO BE REVIEWED LATER
		PoorMansParser()
' -^

	End Method
	
	Method onChange( range_start:Int[], range_end:Int[], length:Int, text:String )
'DebugStop
		' Print JSON so we can compare to VSCODE:
		Print "[{ start:{ character:"+range_start[0]+", line:"+range_start[1]+"},"
		Print "   end:{ character:"+range_end[0]+", line:"+range_end[1]+"},"
		Print "   rangeLength:"+length+","
		Print "   text:~q"+text+"~q}]"

		' Apply the change
		Rem Local line_start:Int = range_start[1]
		Local line_end:Int = range_end[1]
		Local textleft:String
		Local textright:String
		If line_start=line_end
			textleft = lines[line_start][..(range_start[0])]
			textright = lines[line_start][(range_end[0])..]
			lines[line_start] = textleft+text+textright
		Else
			' TODO
		End If
		End Rem
		
		' WARNING --v
		' This allocates the entire source code every change
		' It is not efficient
		' WARNING --^
		
		Local start_pos:Int = range_start[0]
		Local start_line:Int = range_start[1]
		Local end_pos:Int = range_end[0]
		Local end_line:Int = range_end[1]
		
		sourcecode = ""
		
		For Local line:Int = 0 Until lines.length
			If (line<start_line) Or (line>end_line)
				sourcecode :+ lines[line]+"~r~n"
				Continue
			End If
			If line=start_line sourcecode :+ lines[line][..start_pos] + text
			If line=end_line sourcecode :+ lines[line][end_pos..]+"~r~n"
		Next
		' Trim additional CRLF from end
		sourcecode = sourcecode[..(sourcecode.length-2)]
		
		' Update self
		sourcecode = sourcecode.Replace("~t","  ")
		lines = sourcecode.split( "~r~n" )
		
' -> VERY INEFFICIENT CODE HERE 
' -> TO BE REVIEWED LATER
		PoorMansParser()
' -^
		
		
	End Method
	
	Method getDefinition( line:Int, pos:Int )
		{	"id":11,
			"jsonrpc":"2.0",
			"method":"textDocument/definition",
			"params":{
				"position":{
					"character":10,
					"line":209
					},
				"textDocument":{
					"uri":
					"file:///home/si/dev/LSP/sandbox/documentSync.bmx"
					}
				}
			}
			
		' First we need to get the symbol under the cursor
		
		'Local definition:TDefinition = SyAtPosition( line,pos )
		
		
		' Position = {"line":INTEGER,"character":INTEGER}
		Local originSelectionRange:String	'Range = {"start":Position,"end":Position}'
		Local targetUri:String				'DocumentUri
		Local targetRange:String			'Range = {"start":Position,"end":Position}'
		Local targetSelectionRange:String	'Range = {"start":Position,"end":Position}'
		
		' Produce a LocationLink
		Local locationLink:String = "{<ORIGINSELECTION>,<TARGETURL>,<TARGETRANGE>,<TARGETSELECTION>}"
		locationLink = locationLink.Replace( "<ORIGINSELECTION>", "~qoriginSelectionRange:~q:<originSelectionRange>" )
		locationLink = locationLink.Replace( "<TARGETURL>", "~qtargetUri:~q:<targetUri>" )
		locationLink = locationLink.Replace( "<TARGETRANGE>", "~qtargetRange:~q:<targetRange>" )
		locationLink = locationLink.Replace( "<TARGETSELECTION>", "~qtargetSelectionRange:~q:<targetSelectionRange>" )
		'
		locationLink = locationLink.Replace( "<originSelectionRange>", originSelectionRange )
		locationLink = locationLink.Replace( "<targetUri>", targetUri )
		locationLink = locationLink.Replace( "<targetRange>", targetRange )
		locationLink = locationLink.Replace( "<targetSelectionRange>", targetSelectionRange )
	End Method
	
	' This is not really a parser, but I need something to start me off
	Method PoorMansParser()
DebugStop
		Local symbols:TSymbol[]
		'Local index:TIntMap = New TIntMap()
		Local match:TRegExMatch
		Local rxFunction:TRegEx = TRegEx.Create( "(?i)(\s*)(function\s*([[A-Za-z_][A-Za-z0-9_]*).*\(\s*(.*)\)).*" )
		Local rxType:TRegEx = TRegEx.Create( "(?i)(\s*)(type\s([A-Za-z][A-Za-z0-9_]*)).*" )
		Local rxMethod:TRegEx = TRegEx.Create( "(?i)(\s*)(method\s*([A-Za-z_][A-Za-z0-9_]*).*\(\s*(.*)\)).*" )
		Local rxGlobal:TRegEx = TRegEx.Create( "(?i)(\s*)(global\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z]*).*" )
		Local rxLocal:TRegEx = TRegEx.Create( "(?i)(\s*)(local\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z]*).*" )
		Local rxField:TRegEx = TRegEx.Create( "(?i)(\s*)(field\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z]*).*" )
		'
		For Local line:Int = 0 Until lines.length
			If Trim(lines[line])="" Continue
			match = rxType.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Type", match.subExp(3),match.subExp(0),line,match.subExp(1).length) ]
			match = rxMethod.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Method", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxFunction.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Function", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxGlobal.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Global", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxLocal.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Local", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
			match = rxField.find( lines[line] )
			If match symbols :+ [ New TSymbol( "Field", match.subExp(3),match.subExp(2),line,match.subExp(1).length) ]
		Next
	
		' Debug the symbol table
		For Local symbol:Int = 0 Until symbols.length
			Local sym:TSymbol=symbols[symbol]
			Print( (sym.line+","+sym.char)[..7]+"  "+sym.symbol[..10]+"  "+sym.value[..20]+" "+sym.definition )
		Next
		
	End Method
End Type

Type TSymbol
	Field symbol:String
	Field value:String
	Field definition:String
	Field line:Int
	Field char:Int

	Method New( symbol:String, value:String, definition:String, line:Int, character:Int )
		Self.symbol = symbol
		Self.value = value
		Self.definition = definition
		Self.line = line
		Self.char = character
	End Method
	
End Type

'DebugStop

Local doc:TSourceDocument = New TSourceDocument()

' Open a document
doc.onOpen( loadfile( "capabilites.bmx" ) )

' Get a word at a specific position
'Local word:String = doc.wordAt( 3,14 )
DebugStop

Graphics 800,600

Local cx:Int = 0, cy:Int =1
Local state:Int=True, time:Int=MilliSecs()

Local range_start:Int[]
Local range_end:Int[]
Local rangelength:Int

Repeat 
	Cls
	' CURSOR
	If time<MilliSecs() 
		time=MilliSecs()+250
		state = Not state
	End If
	
	' CURSOR CONTROL
	If KeyHit( KEY_UP ) And cy>1
		cy:-1
		cx = Min( cx, doc.lines[cy-1].length )
	End If
	If KeyHit( KEY_DOWN ) And cy<doc.lines.length
		cy:+1
		cx = Min( cx, doc.lines[cy-1].length)
	End If
	If KeyHit( KEY_LEFT )
		If cx>0
			cx:-1
		ElseIf cy>1
			cy:-1
			cx=doc.lines[cy-1].length
		End If
	End If
	If KeyHit( KEY_RIGHT )
		If cx<doc.lines[cy-1].length
			cx:+1
		ElseIf cy<doc.lines.length
			cy:+1
			cx=0
		End If
	End If
	If KeyHit( KEY_END ) cx=doc.lines[cy-1].length
	If KeyHit( KEY_HOME ) cx=0
	
	' MOUSECLICK
	If MouseHit( 1 )
		Local mx:Int = MouseX()
		Local my:Int = MouseY() / 15 +1
		If my<=doc.lines.length
			cy=my
			cx=$7FFFFFFF
			For Local n:Int = 0 Until doc.lines[cy-1].length
				If TextWidth( "8888"+doc.lines[cy-1][..n]) > mx 
					cx=Max(0,n-1)
					Exit
				End If
			Next
			cx = Min( cx, doc.lines[cy-1].length )
		End If
	End If 
	
	' DELETE/BACKSPACE
	If KeyHit( KEY_DELETE )
		If cy<doc.lines.length Or (cy=doc.lines.length And cx<doc.lines[cy].length)
			range_start = [cx,cy-1]
			rangelength = 1
			If cx=doc.lines[cy-1].length
				' CONFIRMED THIS IS THE SAME AS VSCODE
'[{"range":{"end":{"character":0,"line":22},"start":{"character":35,"line":21}},"rangeLength":2,"text":""}]
				' End of line
				range_end = [0,cy]
				doc.onChange( range_start, range_end, 2, "" )
			Else
				' CONFIRMED THIS IS THE SAME AS VSCODE
'[{"range":{"end":{"character":6,"line":0},"start":{"character":5,"line":0}},"rangeLength":1,"text":""}]
				' Midline
				range_end = [cx+1,cy-1]
				doc.onChange( range_start, range_end, 1, "" )
			End If
		End If
	End If
	
	If KeyHit( KEY_BACKSPACE )
		' CONFIRMED THIS IS THE SAME AS VSCODE
		If cy>1 Or (cy=1 And cx>0)
			Print "- Backspace"
			range_end = [cx,cy-1]
			rangelength = 0
			cx:-1
			If cx<0
				' Start of line
				cy:-1
				cx=doc.lines[cy-1].length
				rangelength :+ 2	' CRLF
			End If
			range_start = [cx,cy-1]
			doc.onChange( range_start, range_end, rangelength, "" )
		End If
	End If
	
	' CARRIAGE RETURN/ENTER
	If KeyHit( KEY_ENTER )
		Print "- Carriage Return"
		'[{"range":{"end":{"character":35,"line":21},"start":{"character":35,"line":21}},"rangeLength":0,"text":"~r~n"}
' ** NOT CONFIRMED
		range_start = [cx,cy-1]
		range_end = [cx,cy-1]
		rangelength = 0
		doc.onChange( range_start, range_end, rangelength, "~r~n" )
		cx=0
		cy:+1
	End If
	
	' F12 is DEFINITION
	If KeyHit( KEY_F12 ) doc.getDefinition( cx, cy )
	
	' INSERT
	Local char:Int = GetChar()
	If char>0	' INSERT
		Print( "- Inserting character ascii "+char )
		Select True
		Case char>=32 And char<127
			' CONFIRMED THIS IS THE SAME AS VSCODE
			' Single characters have a start/end position that matches the cursor
			' rangeLength is 0 and text is the character pressed
			range_start = [cx,cy-1]
			range_end = [cx,cy-1]
			rangelength = 0
			doc.onChange( range_start, range_end, rangelength, Chr(char) )
			cx:+1
		'Case char=13
			
		Default
			Print( "- Ignoring ascii "+char )
		End Select
	End If
	
	' DRAW A BASIC TEXT EDITOR
	For Local n:Int = 0 Until doc.lines.length
		DrawText( (n+1), 0, n*15 )
		DrawText( doc.lines[n], TextWidth("8888"), n*15 )
		If state And cy-1=n
			Local x:Int = TextWidth("8888"+doc.lines[n][..cx])
			Local y:Int = n*15
			DrawLine( x,y, x,y+TextHeight("Jj") )
		End If
		DrawText( doc.lines[n].length, GraphicsWidth()-TextWidth("WW"), n*15 )
	Next
	
	' SHOW CURSOR POSITION
	Local text:String= "("+(cy)+","+cx+")"
	Local x:Int = GraphicsWidth()-TextWidth( text )
	Local y:Int = GraphicsHeight()-15
	DrawText( text, x, y )
	
	Flip
Until KeyHit( KEY_ESCAPE ) Or AppTerminate()
