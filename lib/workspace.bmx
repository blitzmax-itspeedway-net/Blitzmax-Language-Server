SuperStrict

'   Blitzmax Language Server / Workspace
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved. 
'   VERSION: 1.0

Import bmx.observer

'Import "jtypes.bmx"
'Import "lsp_types.bmx"
Import "messages.bmx"
Import "trace.bmx"
'Import "textdocuments.bmx"

Type TWorkspaceManager 'Implements IObserver

	Field root:String

	Method New()
		' Listen for events
		'Observer.on( EV_SYSTEM_STATE, Self )

		' Register to receive messages of a specific type
		TMessage.register( "workspace", Self )
	End Method


	'Method createFileSystemWatcher( regex:String )
	'End Method
	

'	Method Observe( id:Int, data:Object )
'		Select id
'		Case EV_SYSTEM_STATE
'			'LockMutex( mutex )
'			systemState = ESYSTEMSTATE(Int[](data)[0])	' Unbox the integer
'			'UnlockMutex( mutex )
'			trace.debug( "Application received system state change: "+systemState.toString() )
'		End Select
'	End Method
	
'workspace.didChangeConfiguration

	' ============================================================

'	Method on_message( message:TMessage )				' DEFAULT HANDLER
'		Trace.debug( "Workspace default handler called for "+message.name )
'	End Method

	' ============================================================
	
	Method on_workspace_DidChangeConfiguration( message:TMessage )
		Trace.debug( "on_workspace_DidChangeConfiguration()" )
		Trace.debug( message.request.stringify() )
	End Method
	
	Method on_workspace_DidChangeWorkspaceFolders( message:TMessage )
		Trace.debug( "on_workspace_DidChangeWorkspaceFolders()" )		
		Trace.debug( message.request.stringify() )
	End Method
End Type