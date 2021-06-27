superstrict

'include "../bin/TMessageQueue.bmx"

'local queue:TMessageQueue = new TMessageQueue()

Graphics( 800,600 )
repeat

    if keyhit( KEY_1 ) sendmessage( "1" )
    if keyhit( KEY_2 ) sendmessage( "2" )
    if keyhit( KEY_3 ) sendmessage( "3" )
    if keydown( MODIFIER_SHIFT ) 
        if keyhit( KEY_1 ) sendmessage( "-1" )
        if keyhit( KEY_2 ) sendmessage( "-2" )
        if keyhit( KEY_3 ) sendmessage( "-3" )
    end if

until keyhit( KEY_ESCAPE )

function sendMessage( s:string )
    print s
end function