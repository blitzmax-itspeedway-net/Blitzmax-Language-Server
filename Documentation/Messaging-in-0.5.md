
== StdIN Messages ==
Inbound message are received by Service-StdIN and published to MSG_CLIENT_IN


MSG_CLIENT_IN is received by Service-InQueue and added to a message queue
(Cancel requests clear messages from this queue)

The threaded service processes these and publishes them on EV_TASK_ADD


== StdOUT Messages ==
Outbound messages are simply published to MSG_SERVER_OUT


