Messaging
=========

Message Overview
----------------
Messages are sent as simple character strings from the client (IDE) over Stdin. They are retrieved by the TLSP.ReceiverThread, encapsulated into a TMessage (Which extends TEvent) and emitted as an Event with an ID of EV_receivedFromClient.

TEventHandler has an eventhook that calls a TEventHandler.EventHander() when a message arrives and passes it to to TEventHandler.distribute(). Each Type that needs to handle events must extend TEventHandler.

TEventHandler.distribute() extracts the event ID and calls an "on" event method associated with the event ID passing the received TMessage as a parameter. For example event ID EV_ReceiveFromClient calls self.onReceivedFromClient().

Flow of a Message
-----------------
The mechanism in the previous section describes how the messaging works, but this section explains where the messages flow.

* Client to Server via StdIn, String in JSON format
* Message received by TLSP.ReceiverThread and packages into a TMessage
* TMessage emitted to the Blitzmax Event system with ID of EV_receivedFromClient

* TMessageQueue.EventHandler() receives EV_receivedFromClient event and calls TMessageQueue.distribute()
* TMessageQueue.distribute() calls TMessageQueue.onReceivedFromClient()
* TMessageQueue.onReceivedFromClient() extracts the method and params from the JSON message, Creates a TMessage using the Method and emits it to the Blitzmax event system.

Implementing a message handler
------------------------------
Every Type that extends TEventHandler can potentially receive any message simply by adding a method for it's handler. The on-event handler method must return the message if it does not process it (or allows other types to process it), or returns NULL to inform the event system that the message has been processed.

The following event handler methods are defined in TEventHandler:
    
| EVENT                             | HANDLER                         |
| --------------------------------- | ------------------------------- |
| | |
| **MESSAGE/IO** | |
| EV_receivedFromClient             | onReceivedFromClient( message ) |
| EV_sendToClient                   | onSendToClient( message ) |
| | |
| **PROTOCOL IMPLEMENTATION DEPENDENT** | **($ Notifications)** |
| EV_CancelRequest                  | onCancelRequest( message ) |
| EV_SetTraceNotification           | onSetTraceNotification( message ) |
| | |
| **GENERAL** | |
| EV_initialize                     | onInitialize( message ) |
| EV_initialized                    | onInitialized( message ) |
| EV_shutdown                       | onShutdown( message ) |
| EV_exit                           | onExit( message ) |
| | |
| **COMPLETION** | |
| EV_completionItem_resolve         | onCompletionResolve( message ) |
| | |
| **TEXT SYNC** | |
| EV_textDocument_didChange         | onDidChange( message ) |
| EV_textDocument_didOpen           | onDidOpen( message ) |
| EV_textDocument_willSave          | onWillSave( message ) |
| EV_textDocument_willSaveWaitUntil | onWillSaveWaitUntil( message ) |
| EV_textDocument_didSave           | onDidSave( message ) |
| EV_textDocument_didClose          | onDidClose( message ) |
| | |
| **WORKSPACE** | |
| EV_didChangeWorkspaceFolders      | onDidChangeWorkspaceFolders( message ) |
| EV_didChangeConfiguration         | onDidChangeConfiguration( message ) |
| EV_didChangeWatchedFiles          | onDidChangeWatchedFiles( message ) |
| | |
| **LANGUAGE FEATURES** | |
| EV_textDocument_definition        | onDefinition( message ) |
| EV_textDocument_completion        | onCompletion( message ) |
| EV_textDocument_documentSymbol    | onDocumentSymbol( message ) |

Message Handling
----------------

| EVENT                             | PROCESSED BY                    |
| --------------------------------- | ------------------------------- |
| | |
| **MESSAGE/IO** | |
| EV_receivedFromClient             | TMessageQueue |
| EV_sendToClient                   | tbc |
| EV_ClientCapabilityNotify         | TWorkspace |
| | |
| **PROTOCOL IMPLEMENTATION DEPENDENT** | **($ Notifications)** |
| EV_CancelRequest                  | tbc |
| EV_SetTraceNotification           | tbc |
| | |
| **GENERAL** | |
| EV_initialize                     | TLSP |
| EV_initialized                    | TLSP |
| EV_shutdown                       | TLSP |
| EV_exit                           | TLSP |
| | |
| **COMPLETION** | |
| EV_completionItem_resolve         | tbc |
| | |
| **TEXT SYNC** | |
| EV_textDocument_didChange         | tbc |
| EV_textDocument_didOpen           | tbc |
| EV_textDocument_willSave          | tbc |
| EV_textDocument_willSaveWaitUntil | tbc |
| EV_textDocument_didSave           | tbc |
| EV_textDocument_didClose          | tbc |
| | |
| **WORKSPACE** | |
| EV_didChangeWorkspaceFolders      | tbc |
| EV_didChangeConfiguration         | tbc |
| EV_didChangeWatchedFiles          | tbc |
| | |
| **LANGUAGE FEATURES** | |
| EV_textDocument_definition        | tbc |
| EV_textDocument_completion        | tbc |
| EV_textDocument_documentSymbol    | tbc |







