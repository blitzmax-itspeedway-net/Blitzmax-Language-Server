SuperStrict
Framework brl.gnet
Import Crypto.MD5digest
'Import brl.Graphics
'Import brl.standardIO
'Import brl.base64


Local data:String = "Hello World"

Local digest:TMessageDigest = GetMessageDigest("MD5")

If digest Then
	Print digest.Digest(data)
End If

'Import crypto.digest

'DebugStop

'Function computeChecksum:String( data:String )
'	Local digest:TMessageDigest = GetMessageDigest("MD5")
'	If digest ; Return digest.Digest( data )
'	Return ""
'End Function

'Local checksum:String = computeChecksum( "Once upon a time..." )

'Print checksum