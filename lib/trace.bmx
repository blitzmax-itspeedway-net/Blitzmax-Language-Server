SuperStrict

'   Logger functionality for BlitzMax Language Server
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved. 
'   VERSION: 1.1

Import bmx.observer

Global LOGTRACE:Int = Observer.Allocate( "Global Logging" )

' Severity is based on SYSLOG Severity from RFC3164/RFC5424
Enum Severity
	EMERGENCY	= 0		' A "panic" condition
	ALERT		= 1		' Urgent failures
	CRITICAL	= 2		' Critical condition
	ERROR		= 3		' Non-urgent failures
	WARNING		= 4		' Warnings that are not an error at the moment
	NOTICE		= 5		' Events that are unusual but not error conditions
	INFO		= 6		' Normal but significant operational messages
	DEBUG		= 7		' Debug-level messages
End Enum

' SYSLOG compatible severity
Global SYSLOG:String[]=["EMER","ALRT","CRIT","ERRR","WARN","NOTC","INFO","DEBG"]

Type Trace

	Field level:Severity = Severity.INFO
	Field message:String

	Method New( level:Severity, message:String )
		Self.level = level
		Self.message = message
	End Method

	Function Prefix:String( level:Severity )
		Return SYSLOG[ level.ordinal() ]
	End Function
	
	Function Write( level:Severity, message:String )
		Observer.post( LOGTRACE, New Trace( level, message ) ) 
	End Function

	Function Emergency( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.EMERGENCY, message ) ) 
	End Function

	Function Alert( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.ALERT, message ) ) 
	End Function

	Function Critical( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.CRITICAL, message ) ) 
	End Function

	Function Error( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.ERROR, message ) ) 
	End Function

	Function Warning( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.WARNING, message ) ) 
	End Function

	Function Notice( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.NOTICE, message ) ) 
	End Function

	Function Info( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.INFO, message ) ) 
	End Function

	Function Debug( message:String )
		Observer.post( LOGTRACE, New Trace( Severity.DEBUG, message ) ) 
	End Function

End Type


