SuperStrict

' In MaxIDE, true, false and null are updated using Autocomplete and break the JSON standard.

Local JText:String = """
	{
	"workspace":{
		"test1":true,
		"test2":false,
		"test3":null
		},
	"Another":"time"
	}
"""
