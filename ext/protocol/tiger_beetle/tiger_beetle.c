#include <ruby.h>
#include "checksum.h"

void Init_Protocol_TigerBeetle(void) {
	VALUE Protocol = rb_define_module("Protocol");
	VALUE Protocol_TigerBeetle = rb_define_module_under(Protocol, "TigerBeetle");
	
	Init_Protocol_TigerBeetle_Checksum(Protocol_TigerBeetle);
}
