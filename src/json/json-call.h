#ifndef JSON_CALL_H
#define JSON_CALL_H

/* Interface with PennMUSH host environment's call logic */

/* MUSHcode command: @rpc */
#ifdef COMMAND_PROTO
COMMAND_PROTO(cmd_json_rpc);
#endif /* def COMMAND_PROTO */

/* MUSHcode function: rpc(function, arg0, arg1, ...) */
#ifdef FUNCTION_PROTO
FUNCTION_PROTO(fun_json_rpc);
#endif /* def FUNCTION_PROTO */

#endif /* undef JSON_CALL_H */
