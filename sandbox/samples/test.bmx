'   This program tests framework, import and include statements
superstrict

framework brl.retro     ' Lets start with retro basic

REM EXAMPLE
da da

endrem ' with a weird comment

import brl.graphics
import brl.linkedlist

include "first.bmx"
include "second.bmx"

function abc()
end function

function xyz:int()
end function

function weird()
end function ' with weird trailing comment!

