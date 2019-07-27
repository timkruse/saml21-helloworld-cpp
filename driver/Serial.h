#ifndef SERIAL_H_
#define SERIAL_H_

#include <saml21.h>
#include <cstring>

class Serial{
public:
	char line_buffer[64]; // this one can be changed by user and will be overwritten on new line received event / receive buffer full event

	Serial();
	void write(uint8_t byte);
	char read();
	
	void print(const char *str, const char *endl = "\n");

	void (*line_received_cb)(char *) = nullptr;
	void (*receive_buffer_full_cb)(char *) = nullptr;
};

extern Serial serial;

#endif