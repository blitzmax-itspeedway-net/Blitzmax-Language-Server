
'   JSON PARSER
'   (c) Copyright Si Dunford, Jule 2021, All Right Reserved

'   JSON Specification:
'   https://www.json.org/json-en.html

Type JSON

    Public

    ' Error Text, Line and Character
    Field errLine:Int = 0
    Field errPos:Int = 0
	Field errNum:Int = 0
    Field errText:String = ""

    ' Create JSON object from a string
    Method New( text:String )
        root = parsetext( text )
    End Method

    ' Create a JSON object from a Blitzmax Object (Reflection)
    Method New( obj:Object )
		'root = reflect( obj )
    End Method

	' Confirm if there is an error condition
	Method error:Int()
		Return ( errNum > 0 ) 
	End Method
	
    ' Convert text into a JSON object
    Function Parse:JSON( text:String )
        Return New JSON( text )
    End Function

    ' Convert JSON into a string
    Function Stringify:String( j:JSON )
		If j And j.root Return j.root.stringify()
		Return ""
    End Function

    Function Stringify:String( j:JNode )
		If j Return j.stringify()
		Return ""
    End Function

    'Method toString:String()
	'	Return _Stringify( root )
    'End Method

	' Extract a JNode from the root by key
	Method operator []:JNode( key:String )
		Return root[key]
	End Method

    ' Push a JSON object into a Blitzmax Object using Reflection 
    Method transpose:TRequest()
'DebugStop
		If Not root Return Null
		
		' Identify the Type that we are going to create
		Local invoke_method:String = Trim(root["method"].tostring())
		If invoke_method="" Return Null
		Local typestr:String = "MSG_"+invoke_method
		
		' Create an object of type "typestr"
		Print "Creating type "+typestr
		Local typeid:TTypeId = TTypeId.ForName( typestr )
		Local invoke:Object = typeid.newObject()
		If Not invoke Return Null
	
		' Enumerate fields

'DebugStop
		Local fields:TMap = New TMap()
		
		' Add Field names and types to map
		For Local fld:TField = EachIn typeid.EnumFields()
			'Local fldtype:TTypeId = fld.typeid
			Print fld.name() + ":" + fld.typeid.name()
			
			fields.insert( fld.name(), fld.typeid.name() )
		Next
	
		' Copy JSON fields into object
		For Local fldname:String = EachIn fields.keys()
			Local fldtype:String = String(fields[fldname]).tolower()
			Print "Field: "+fldname+":"+fldtype
			Local fld:TField = typeid.findField( fldname )
			If fld
			Select fldtype
			Case "string"
				fld.setString( invoke, "SCAREMONGER" )
            case "int"
                fld.setInt( invoke, 99 )
			Default
				DebugLog( fldtype + " not currently supported by transform" )
			End Select
			End If
		Next		
		
		
    End Method

	

    Private

    ' ##### PARSER

    Const SYM_WHITESPACE:String = " ~t~n~r"
    Const SYM_ALPHA:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghjklmnopqrstuvwxyz"
    Const SYM_NUMBER:String = "0123456789"

    Field tokens:TQueue<JToken> = New TQueue<JToken>
    Field unparsed:String
	Field root:JNode		' The parsed content of this JSON
	
    Field linenum:Int = 0
    Field linepos:Int = 0

    ' Parse string into a JSON object
    Method parsetext:JNode( text:String )

'DebugStop

        'Local node:TMap = New TMap()
        ' For convenience, and empty string is the same as {}
        If text.Trim()="" text = "{}"
        unparsed = text
    
        ' Tokenise the JSON string
        Tokenise()

		' Dump the tokens, just for debugging purposes
		'For Local t:JToken = EachIn tokens
		'	Print( t.symbol + "  =  "+String(t.value) )
		'Next
		
        ' Parse out the parent object
        If PopToken().symbol <> "{" Return InvalidNode( "Unexpected Symbol" )
        Local node:JNode = ReadObject()
		If node.invalid() Return node
        If PopToken().symbol <> "}" Return InvalidNode( "Unexpected Symbol" )
        ' There should be no more characters after the closing braces
        If tokens.isEmpty() Return node
        Return InvalidNode( "Unexpected characters past end" )
    End Method

    ' Reads an Object creating a TMAP
    Method ReadObject:JNode()
        Local node:TMap = New TMap()
        Local token:JToken

		'DebugStop
		
        If PeekToken().symbol = "}" Return New JNode( "object", node )
        Repeat
            ' Only valid option is a string (KEY)
            If PeekToken().symbol <> "string" Return InvalidNode()
            token = PopToken()

			'DebugStop
			'WE ARE LOOKING HERE To CHECK THAT JSON IS DEQUOTED

            Local name:String = Dequote( token.value )

            ' Only valid option is a colon
            If Not PopToken().symbol = ":" Return InvalidNode()

            ' Get the value for this KEY
            Select PeekToken().symbol
            Case "{"    ' OBJECT
                Local value:JNode = ReadObject()
                If PopToken().symbol <> "}" Return InvalidNode()
                node.insert( name, New JNode( "object", value ) )
            Case "["    ' ARRAY
                Local value:TList = ReadArray()
                node.insert( name, value )
                If PopToken().symbol <> "]" Return InvalidNode()
                node.insert( name, New JNode( "array", value ) )
            Case "string"
                token = PopToken()
                node.insert( name, New JNode( "string", Dequote(token.value) ) )
            Case "number"
                token = PopToken()
                node.insert( name, New JNode( "number", token.value ) )
            Case "alpha"
                token = PopToken()
                Local value:String = token.value
                If value="true" Or value="false" Or value="null"
                    node.insert( name, value )
                Else
                    Return InvalidNode( "Unknown identifier" )
                End If
            Default
                Return InvalidNode()
            End Select

            ' Valid options now are "}" or ","
            token = PeekToken()
            If token.symbol = "}"
                Return New JNode( "object", node )
            ElseIf token.symbol = ","
                PopToken()  ' Remove "," from token list
            Else
                Return InvalidNode( "Unexpected symbol" )
            End If
        Forever
    End Method

	Method dequote:String( text:String )
		If text.startswith( "~q" ) text = text[1..]
		If text.endswith( "~q" ) text = text[..(Len(text)-1)]
		Return text
	End Method

    ' Reads an Array creating a TList
    Method ReadArray:TList()
    End Method

    ' Pops the first token from the stack
    Method PopToken:JToken()
        ' Whitespace is no longer tokenised
        'while not tokens.isempty() and PeekToken().in( SYM_WHITESPACE ) 
        '    PopToken()
        'wend
        If tokens.isempty() Return New JToken( "EOF","")
        Return tokens.dequeue()
    End Method

    ' Peeks the top of the Token Stack
    Method PeekToken:JToken()
        ' Whitespace is no longer tokenised
        'while not tokens.isempty() and PeekToken().in( SYM_WHITESPACE ) 
        '    PopToken()
        'wend
        If tokens.isempty() Return New JToken( "EOF","")
        Return tokens.peek()
    End Method

    ' Returns an invalid node object
    Method InvalidNode:JNode( message:String = "Invalid JSON" )
        errNum  = 1
		errLine = linenum
        errPos  = linepos
        errText = message
        Return New JNode( "invalid", message )
    End Method

    ' Returns an error condition
    'Method InvalidJSON:TMap( message:String = "Invalid JSON" )
    '    errNum  = 1
'	'	errLine = linenum
    '    errPos  = linepos
    '    errText = message
    '    Return Null
    'End Method

    '##### TOKENISER

    ' Tokenise an unparsed string
    Method Tokenise()
        ' Toker the unparsed text
        Local token:JToken = ExtractToken()
        While token.symbol <> "EOF"
            tokens.enqueue( token )    ' ListAddLast()
			'Print( token.symbol )
            token = ExtractToken()
        Wend
    End Method

    ' Extract the next Token from the string
    Method ExtractToken:JToken()
    Local char:String = PeekChar()
    Local name:String
    Local token:JToken
        ' Identity the symbol
        If char=""
            Return New JToken( "EOF", "" )
		ElseIf Instr( "{}[]:,", char, 1 )               ' Single character symbol
            ' Single character tokens
			PopChar()
            Return New JToken( char, char )
        ElseIf char="~q"                            ' Quote indicates a string
            Return New JToken( "string", ExtractString() )
        ElseIf Instr( SYM_NUMBER+"-", char )     	' Number
            Return New JToken( "number", ExtractNumber() )
        ElseIf Instr( SYM_ALPHA, char )             ' Alphanumeric Identifier
            Return New JToken( "alpha", ExtractIdent() )
        Else
            Return New JToken( "EOF", "" )
        End If
    End Method

    ' Skips leading whitespace and returns next character
    Method PeekChar:String()
        Local char:String
        Repeat
            If unparsed.length = 0 Return ""
            char = unparsed[..1]
            Select char
            Case "~r"   ' CR
                unparsed = unparsed[1..]
            Case "~n"   ' LF
                linenum :+ 1
                linepos = 0
                unparsed = unparsed[1..]
            Case " ","~t"
                linepos :+ 1
                unparsed = unparsed[1..]
            End Select
        Until Not Instr( SYM_WHITESPACE, char )
        Return char
    End Method

    ' Skips leading whitespace and Pops next character
    Method PopChar:String()
        Local char:String
        Repeat
            If unparsed.length = 0 Return ""
            char = unparsed[..1]
            Select char
            Case "~r"   ' CR
                unparsed = unparsed[1..]
            Case "~n"   ' LF
                linenum :+ 1
                linepos = 0
                unparsed = unparsed[1..]
            Default
                linepos :+ 1
                unparsed = unparsed[1..]
            End Select
        Until Not Instr( SYM_WHITESPACE, char )
        Return char
    End Method

    Method ExtractIdent:String()
        Local text:String
        Local char:String = peekChar()
        While Instr( SYM_ALPHA, char ) And char<>""
            text :+ popChar()
            char = PeekChar()
        Wend
        Return text
    End Method

    Method ExtractNumber:String()
        Local text:String
        Local char:String = peekChar()
        While Instr( SYM_NUMBER+".", char ) And char<>""
            text :+ popChar()
            char = PeekChar()
        Wend
        Return text
    End Method

    Method ExtractString:String()
'DebugStop
        Local text:String = popChar()   ' This is the leading Quote
        Local char:String 
        Repeat
            char = PopChar()
            text :+ char
        Until char="~q" Or char=""
        Return text
    End Method

	' ##### STRINGIFY
	
	

End Type

Type JNode
    Field class:String
    Field value:Object
    Method New( class:String, value:Object )
        Self.class=class
        Self.value=value
    End Method
	Method Invalid:Int()
		Return ( class = "invalid" )
	End Method
	Method toString:String()
		Return String(value)
	End Method
	' Extract a JNode by key (Only works on objects)!
	Method operator []:JNode( key:String )
		If class="object" 
			Local map:TMap = TMap( value )
			If map Return JNode( map[key] )
		End If
		Return New JNode( "invalid", "" )
	End Method

    Method Stringify:String()
	
		'DebugStop
		
		Local text:String
		'If Not j Return "~q~q"
		Select class
		Case "object"
			Local map:TMap = TMap( value )
			text :+ "{"
			If map
			 
				For Local key:String = EachIn map.keys()
                    Local j:JNode = JNode( map[key] )
					text :+ "~q"+key+"~q:"+j.stringify()+","
				Next
				' Strip trailing comma
				text = text[..(Len(text)-1)]
			End If
			text :+ "}"
		Case "number"
			text :+ String(value)
		Case "string"
			text :+ "~q"+String(value)+"~q"
		Default
			Print "INVALID SYMBOL: '"+class+"'"
		End Select
		Return text
	End Method
End Type

Type JToken
    Field symbol:String
    Field value:String

    Method New( symbol:String, value:String )
        Self.symbol = symbol
        Self.value = value
    End Method
End Type