
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Include "TMethod_exit.bmx"
include "TMethod_initialize.bmx"
Include "TMethod_initialized.bmx"
Include "TMethod_shutdown.bmx"

' BASIC REQUEST TYPE
Type TMessage
    Method Execute() Abstract
End Type
