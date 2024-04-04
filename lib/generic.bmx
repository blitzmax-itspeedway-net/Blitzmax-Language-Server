SuperStrict

'   BLITZMAX LANGUAGE SERVER
'	Generic Functions
'
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved. 
'   VERSION: 1.0

' Manage the system state

'Import "trace.bmx"
Import brl.retro	' Hex()

' Allocate an LSP unique message ID. This is used when sending requests to the LSP Client
Function GenerateID:Int()
	Global nextid:Int = 1000	' Its easier to debug them when they dont align with VSCODE
	Local this:Int = nextid
	nextid :+ 1
	Return this
End Function
	
Rem	# rfc4122, Random GUID
	UUID                   = time-low "-" time-Mid "-"
                             time-high-and-version "-"
                             clock-seq-and-reserved
                             clock-seq-low "-" node
	time-low               = 4hexOctet
	time-mid               = 2hexOctet
	time-high-and-version  = 2hexOctet
	clock-seq-and-reserved = hexOctet
	clock-seq-low          = hexOctet
	node                   = 6hexOctet
	hexOctet               = hexDigit hexDigit
	hexDigit =
            "0" / "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9" /
            "a" / "b" / "c" / "d" / "e" / "f" /
            "A" / "B" / "C" / "D" / "E" / "F"
End Rem
Function GenerateUID:String()
	Const VERSION:Byte = $84						'PSUDO-RANDOM GUID
	Local time:Int = MilliSecs()	
	Local token:String
	token :+ Hex( time )+"-"						'4hexOctet	time-low
	token :+ Hex( time )[4..8]+"-"					'2hexOctet	time-mid
	token :+ Hex( time )[2..4]						'hexOctet	time-high
	token :+ Hex( version )[6..8]+"-"				'hexOctet	version
	token :+ Hex(Rand(0,$0000FFFF))[4..8]+"-"		'2hexOctet	clock-seq
	token :+ Hex(Rand(-$0FFFFFFF,$0FFFFFFF))		'4hexDigit	node (4 of 6)
	token :+ Hex(Rand(0,$0000FFFF))[4..8]			'2hexDigit	node (2 of 6)
	Return Lower(token)
End Function

' Inline IF
Function iif:String( condition:Int )
	If condition; Return "TRUE"
	Return "FALSE"
End Function

Function iif:String( condition:Int, ifTrue:String, ifFalse:String )
	If condition; Return ifTrue
	Return ifFalse
End Function
