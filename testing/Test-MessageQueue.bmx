superstrict

include "../bin/TMessageQueue.bmx"
local queue:TMessageQueue = new TMessageQueue()

repeat
    queue.readStdIn()

    delay(25)
until keyhit( KEY_ESCAPE )

function sendMessage( s:string )
    print s
end function


Type ThreadedMessageLoop

end type

Type ThreadLoop
end type