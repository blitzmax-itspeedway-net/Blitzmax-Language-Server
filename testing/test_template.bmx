include "../bin/sandbox.bmx"
include "../bin/TTemplate.bmx"

'{"id":34,"result":{"capabilities":{"onHover":true},"serverinfo":{"name":"Language Server for BlitzMax NG","version":"0.1"}},"jsonrpc":"2.0"}
function initialize()
    local result:TTemplate = new TTemplate()
    result.addkey( "id", 34 )
    result.addkey( "result", TTemplate.CAPABILITIES )
    result.add( "capabilities", [["onHover","true"]] )
    result.add( "serverinfo", [["name","~qLanguage Server for BlitzMax NG~q"],["version","~q0.1~q"]] )
    print result.wrap()
end Function

'{"id":null,"error":{"code":123456,"message":THIS IS AN ERROR},"jsonrpc":"2.0"}
function error()
    local result:TTemplate = new TTemplate()
    result.addkey( "id", "null" )
    result.addkey( "error", [["code","123456"],["message","THIS IS AN ERROR"]] )
    print result.wrap()
end Function

initialize()
error()



