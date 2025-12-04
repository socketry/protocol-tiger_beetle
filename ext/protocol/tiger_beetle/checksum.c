#include <ruby.h>
#include <ruby/io/buffer.h>
#include <aegis.h>
#include <aegis128l.h>
#include <string.h>
#include <stdint.h>
#include <stddef.h>

// Compute checksum from IO::Buffer data
// TigerBeetle uses Aegis128L in checksum mode: adlen=message_length, mlen=0
static VALUE rb_checksum_from_buffer(VALUE self, VALUE buffer_value) {
	aegis_init();
	
	// Get IO::Buffer data pointer and size
	const void *base;
	size_t size;
	rb_io_buffer_get_bytes_for_reading(buffer_value, &base, &size);
	
	// Use encrypt_detached with mlen=0, adlen=size (checksum mode)
	uint8_t zero_key[16] = {0};
	uint8_t zero_nonce[16] = {0};
	uint8_t mac[16];
	uint8_t ciphertext[1]; // Dummy buffer, not used when mlen=0
	
	// For checksum mode: mlen=0 (no message), adlen=size (additional data is the data)
	// Handle empty input: pass NULL for ad when size is 0
	const uint8_t *ad = size > 0 ? (const uint8_t *)base : NULL;
	if (aegis128l_encrypt_detached(ciphertext, mac, 16, NULL, 0, ad, size, zero_nonce, zero_key) != 0) {
		rb_raise(rb_eRuntimeError, "aegis128l_encrypt_detached failed");
	}
	
	// Return MAC directly - TigerBeetle uses little-endian byte order
	return rb_str_new((const char *)mac, 16);
}

// Compute checksum from string data
// TigerBeetle uses Aegis128L in checksum mode: adlen=message_length, mlen=0
static VALUE rb_checksum_from_string(VALUE self, VALUE data_value) {
	aegis_init();
	
	StringValue(data_value);
	
	const uint8_t *data = (const uint8_t *)RSTRING_PTR(data_value);
	size_t data_size = RSTRING_LEN(data_value);
	
	// Use encrypt_detached with mlen=0, adlen=data_size (checksum mode)
	uint8_t zero_key[16] = {0};
	uint8_t zero_nonce[16] = {0};
	uint8_t mac[16];
	uint8_t ciphertext[1]; // Dummy buffer, not used when mlen=0
	
	// For checksum mode: mlen=0 (no message), adlen=data_size (additional data is the data)
	// Handle empty input: pass NULL for ad when data_size is 0
	const uint8_t *ad = data_size > 0 ? data : NULL;
	if (aegis128l_encrypt_detached(ciphertext, mac, 16, NULL, 0, ad, data_size, zero_nonce, zero_key) != 0) {
		rb_raise(rb_eRuntimeError, "aegis128l_encrypt_detached failed");
	}
	
	// Return MAC directly - TigerBeetle uses little-endian byte order
	return rb_str_new((const char *)mac, 16);
}

void Init_Protocol_TigerBeetle_Checksum(VALUE Protocol_TigerBeetle) {
	VALUE Protocol_TigerBeetle_Checksum = rb_define_module_under(Protocol_TigerBeetle, "Checksum");
	
	rb_define_singleton_method(Protocol_TigerBeetle_Checksum, "compute_from_buffer", rb_checksum_from_buffer, 1);
	rb_define_singleton_method(Protocol_TigerBeetle_Checksum, "compute_from_string", rb_checksum_from_string, 1);
}
