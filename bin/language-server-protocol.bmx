'
'	LANGUAGE SERVER PROTOCOL TYPES
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved
'
'	Based on Language server protocol 3.16 at:
'	https://microsoft.github.io/language-server-protocol/specifications/specification-current/

Enum DiagnosticSeverity ; Error = 1 ; Warning ; Information ; Hint ; EndEnum
Enum DiagnosticTag ; Unnecessary = 1 ; Depreciated ; EndEnum

Enum CompletionItemKind 
	_Text = 1
    _Method = 2
    _Function = 3
    _Constructor = 4
    _Field = 5
    _Variable = 6
    _Class = 7
    _Interface = 8
    _Module = 9
    _Property = 10
    _Unit = 11
    _Value = 12
    _Enum = 13
    _Keyword = 14
    _Snippet = 15
    _Color = 16
    _File = 17
    _Reference = 18
    _Folder = 19
    _EnumMember = 20
    _Constant = 21
    _Struct = 22
    _Event = 23
    _Operator = 24
    _TypeParameter = 25
EndEnum

Enum DocumentHighlightKind	;	Text = 1 ; Read ; Write ; EndEnum
Enum InsertTextFormat ; PlainText = 1 ; Snippet ; EndEnum

Enum EMessageType ; Error = 1 ; Warning ; Info ; Log ; EndEnum

Enum SymbolKind
    _File			= 1
    _Module			= 2
    _Namespace		= 3
    _Package		= 4
    _Class			= 5
    _Method			= 6
    _Property		= 7
    _Field			= 8
    _Constructor	= 9
    _Enum			= 10
    _Interface		= 11
    _Function		= 12
    _Variable		= 13
    _Constant		= 14
    _String			= 15
    _Number			= 16
    _Boolean		= 17
    _Array			= 18
	_Object			= 19
	_Key			= 20
	_Null			= 21
	_EnumMember		= 22
	_Struct			= 23
	_Event			= 24
	_Operator		= 25
	_TypeParameter	= 26
EndEnum
global SymbolKindText:String[] = [ ..
	"Unknown","File","Module","Namespace","Package",	..
	"Class","Method","Property","Field","Constructor",	..
	"Enum","Interface","Function","Variable","Constant",	..
	"String","Number","Boolean","Array","Object",	..
	"Key","Null","EnumMember","Struct","Event",	..
	"Operator","TypeParameter"]	


Enum TextDocumentSyncKind ; NONE = 0 ; FULL = 1 ; INCREMENTAL = 2 ; EndEnum

' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#diagnostic
Type TDiagnostic Extends TASTErrorMessage
	Field range: TRange
	Field severity: DiagnosticSeverity	' The diagnostic's severity.
	'Field code: String					' The diagnostic's code, which might appear in the user interface.
	'Field codeDescription:TCodeDescription		' An optional property to describe the error code.
	Field source: String				' The source of this diagnostic
	Field message : String				' The diagnostic's message
	'Field tags: TDiagnostTag[]			' Additional metadata
	'Field relatedInformation:TDiagnosticRelatedInformation[]	' Related diagnostic information
	Field data:Int						' Data entry field that is preserved between Notification and request
	
	Method New()
		range = New TRange()
		range.start = New TPosition()
		range.ends = New TPosition()
	End Method
	
	Method New( error:String, severity:DiagnosticSeverity )
		Self.message = error
		Self.severity = severity
		Self.range = New TRange()
		Self.range.start = New TPosition()
		Self.range.ends = New TPosition()
	End Method

	Method New( error:String, severity:DiagnosticSeverity, range:TRange )
		Self.range = range
		Self.message = error
		Self.severity = severity
	End Method
	
	Method reveal:String()
		Local result:String
		result :+ Upper( severity.tostring() )
		result :+ " ["+range.start.line+","+range.start.character+"] - "
		result :+ "["+range.ends.line+","+range.ends.character+"] " 
		result :+ "{"+ source + "} "
		result :+ message
		Return result
	End Method
End Type

Type TDiagnosticRelatedInformation
	Field location: TLocation
	Field message: String
End Type

' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#location
Type TLocation
	Field uri:String
	Field range:TRange = Null

	Method New( uri:String, token:TToken )
		Self.uri = uri
		If token ; range = New TRange( New TPosition( token ), New TPosition( UInt(token.line), UInt(token.pos+token.value.length )) )
	End Method

	Method reveal:String()
		If range ; Return range.reveal()
        Return "[]"
	End Method

End Type

' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#position
Type TPosition
	Field line: UInt
	Field character: UInt
	
	Method New( line:UInt, character:UInt )
		Self.line = line
		Self.character = character
	End Method
	
	Method New( token:TToken )
		If Not token Return
		Self.line = token.line
		Self.character = token.pos
	End Method

	Method New( position:JSON )
		Try
			Self.line = position.find("line").toInt()
			Self.character = position.find("character").toint()
		Catch Exception:String
			' Ignore issues, result will be empty!
		End Try
	End Method

	Method reveal:String()
		Return "["+line+","+character+"]"
	End Method
	
End Type

' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#range
Type TRange
	Field start: TPosition
	Field ends: TPosition

	Method New( starting:TPosition, ending:TPosition )
		Self.start = starting
		Self.ends = ending
	End Method

	Method New( ast:TASTNode )
		If Not ast ; Return
		Self.start = New TPosition( ast.start_line, ast.start_char )
		Self.ends = New TPosition( ast.end_line, ast.end_char )	
	End Method
	
	Method New( start_line:UInt, start_char:UInt, end_line:UInt, end_char:UInt )
		Self.start = New TPosition( start_line, start_char )
		Self.ends = New TPosition( end_line, end_char )
	End Method
	
	Method New( range:JSON )
		Try
			Self.start = New TPosition( range.find("start") )
			Self.ends = New TPosition( range.find("end") )
		Catch Exception:String
			' Ignore issues, result will be empty!
		End Try
	End Method
	
	Method reveal:String()
		Local str:String
		If start 
			str :+ start.reveal()
		Else
			str = "[]"
		End If
		str:+"-"
		If ends 
			str :+ ends.reveal()
		Else
			str = "[]"
		End If
		Return str	
	End Method
	
End Type

' Functions to return a JSON range object from positional or node arguments
' CLIENT IS ZERO-BASED, BUT TEXT DOCUMENT IS LINE BASED
Function JRange:JSON( range:TRange, offset:Int=-1 )
	'Local offset:Int = 0
	'If zerobased ; offset = 1
	'Local J:JSON = New JSON()
	If Not range Or Not range.start Or Not range.ends ; Return New JSON()
	Try
		Return JRange( range.start.line, range.start.character, range.ends.line, range.ends.character, offset )
	'	J.set( "start|line", range.start.line-offset)
	'	J.set( "start|character", range.start.character-offset )
	'	J.set( "end|line", range.ends.line-offset )
	'	J.set( "end|character", range.ends.character-offset )
	Catch Exception:String
		' Ignore and continue
		Return New JSON()
	End Try
End Function

Function JRange:JSON( node:TASTNode, offset:Int=-1 )
	'Local offset:Int = 0
	'If zerobased ; offset = 1
	'Local J:JSON = New JSON()
	'J.set( "start|line", node.start_line-offset )
	'J.set( "start|character", node.start_char-offset )
	'J.set( "end|line", node.end_line-offset )
	'J.set( "end|character", node.end_char-offset )
	If Not node Return New JSON()
	Return JRange( node.start_line, node.start_char, node.end_line, node.end_char, offset )
End Function

Function JRange:JSON( start_line:Int, start_char:Int, end_line:Int, end_char:Int, offset:Int=-1 )
	Local J:JSON = New JSON()
	J.set( "start|line", Max(start_line+offset,0) )
	J.set( "start|character", Max(start_char+offset,0) )
	J.set( "end|line", Max(end_line+offset,0) )
	J.set( "end|character", Max(end_char+offset,0) )
	Return J
End Function

'DebugStop
'Local test:URI
'test = URI.Parse( "http://example.com:222/in/this/path?param=22#fragment" )
''test = URI.Parse( "http://example.com/" )
'Print test.scheme
'Print test.authority
'Print test.path
'End 
