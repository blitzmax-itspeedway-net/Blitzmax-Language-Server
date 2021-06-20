
' Creates a Tree Structure using:
'   JSON    To represent a JSON Object
'   STRING  To Represent a JSON String
'   

' Based on JSON Definition located at:
' https://www.json.org/json-en.html




Type JSON Final
    
    field errLine:int = 0
    field errChar:int = 0
    field errText:string = ""

    Method new()
    End Method

    Method New( text:String )
    End Method

    Method Stringify:String()
    End Method

    Function Parse:JSON( text:string )
        return new JSON( text )
    End Function

    Private

    field Root:string[]
    field tokens:TQueue<JSON_Token> = new TQueue<JSON_Token>
    field unparsed:string

    const SYM_WHITESPACE:string = " ~t~n~r"
    const SYM_ALPHA:string = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghjklmnopqrstuvwxyz"
    const SYM_NUMBER:string = "0123456789"

    ' Current line number being parsed
    field linenum:int = 0
    field linepos:int = 0

    Method Parser:JSON( text:string )
        ' For convenience, and empty string is the same as {}
        if text.trim()="" text = "{}"
        unparsed = text

        ' Toker the text
        'local list:JSON_Token[]
        local token:JSON_Token
        Repeat
            token = ExtractToken()
            if token tokens.enqueue( token )    ' ListAddLast()
        Until not token

        token = PopToken()
        if token.symbol <> "{" return InvalidJSON()
        root = ReadObject()
        if token.symbol <> "}" return InvalidJSON()
        ' There should be no more characters after the closing braces
        if tokens.length>0 return InvalidJSON()
    End Method

    Method ReadObject:TMap()
        local node:TMap = new TMap()
        local token:JSON_Token
        IgnoreWhiteSpace()
        if peekToken().symbol = "}" return null
        repeat
            select PeekToken().symbol
            case "string"
                token = PopToken()
                local name:string = token.value
                IgnoreWhiteSpace()
                if not PopToken().symbol = ":" return InvalidJSON()
                IgnoreWhiteSpace()
                ' Get value
                select PeekToken().symbol
                case "{"    ' OBJECT
                    local value:TMap = ReadObject()
                    node.insert( node, name, value )
                    if not nextToken().token="}" return InvalidJSON()
                case "["    ' ARRAY
                    local value:TList = ReadArray()
                    node.insert( node, name, value )
                    if not nextToken().token="]" return InvalidJSON()
                case "string"
                    token = getToken()
                    local value:string = token.value 
                    node.insert( node, name, value )
                case "number"
                    token = getToken()
                    local value:string = token.value 
                    node.insert( node, name, string(value) )
                case "boolean"
                    token = getToken()
                    local value:string = token.value
                    if value="true" or value="false"
                        node.insert( node, name, value )
                    else
                        return InvalidJSON()
                    end if
                case "null"
                    token = getToken()
                    local value:string = "null"
                    return [name,value]
                default
                    return InvaidJSON()
                end select
            case "}"
            default
                return InvalidJSON()
            end select

            ' Do we end or loop?
            select peekToken().name
            case "}"
                Exit
            case ","
                Continue
            Default
                return InvalidJSON()
            end select
        forever
        return node
    End Method

    Method InvalidJSON:JSON( message:string = "Invalid JSON" )
        errLine=0
        errChar=0
        errText=message
        return null
    End Method

    Method IgnoreWhiteSpace()
        'local token:JSON_Token = PeekToken()
        while PeekToken().in( SYM_WHITESPACE )
            PopToken()
        wend
    End Method

    '##### TOKER

    ' Pops the first token from the stack
    Method PopToken:JSON_Token()
        if tokens.isempty() return new JSON_Token( "EOF","")
        return tokens.dequeue()
    End Method

    ' Peeks the top of the Token Stack
    Method PeekToken:JSON_Token()
        if tokens.isempty() return new JSON_Token( "EOF","")
        return tokens.peek()
    End Method

    '##### PARSER

    Method PeekChar:String( text:string )
        if not text return ""
        local ch:string = text[..1]
        
    End Method

    

    Method ExtractSymbol:String()
    End Method

    '########## OPERATOR OVERLOADING

    Method operator []:String( key:String )
		Return ""   'TGadget(MapValueForKey( gadgets, Lower(name) ))
	End Method

    Method toString:String( key:String )
		Return ""    'int((MapValueForKey( gadgets, Lower(name) ))
	End Method

    Method toInt:int( key:String )
		Return 0    'int((MapValueForKey( gadgets, Lower(name) ))
	End Method

End Type

Type JSON_Token
    Field symbol:string
    Field value:String
    Field _Next:JSON_Symbol
    field _Prev:JSON_Symbol

    Method New( symbol:string, value:string )
        self.symbol = symbol
        self.value = value
    End Method

    ' Request if a symbol is in a given list
    Method in:int( list:string )
        return instr( value,list)
    end method
End Type


