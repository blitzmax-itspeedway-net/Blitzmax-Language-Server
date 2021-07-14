SuperStrict
'
'	TESTING documentSync / Change / Open
'
'	Text editor based on R-War ingame code editor
'	(c) Copyright Si Dunford, Aug 2013, All Right Reserved

' BEFORE YOU ASK:
' YES:	It would be quicker to not load it as lines, join it and then split it here.
' 		But the LSP Client sends it as a chunk, so I need to emulate it.

' Load a file into a contiguous string
Function LoadFile:String( filename:String )
	Local file:TStream = ReadFile( filename )
	If Not file Return ""
	Local text:String
	While Not Eof(file)
		text :+ ReadLine(file)+"~r~n"
	Wend
	CloseStream file
	Return text
End Function 

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
		
	End Method
End Type

'DebugStop

Local doc:TSourceDocument = New TSourceDocument()

' Open a document
doc.onOpen( loadfile( "capabilites.bmx" ) )

' Get a word at a specific position
'Local word:String = doc.wordAt( 3,14 )

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
