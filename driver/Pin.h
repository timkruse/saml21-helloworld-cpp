#ifndef PIN_H_
#define PIN_H_

#include <saml21.h>

class Pin{
public:
	enum class Port: uint8_t{
		A = 0,	/**< Index of Port A */
		B = 1,	/**< Index of Port B */
		OutOfBounds = 2 /**< Invalid port index */
	};
	/** Enum: Function.
	 * \brief Defines, how to use the pin.
	 * 0b0000xxxx -> Pin assigned to Peripheral if xxxx > 0
	 * 0b0xx10000 -> Pin configured as GPIO, xx are options and can be ORed together
	 * */
	enum class Function: uint16_t{
		PeripheralA = 1 << 0,
		PeripheralB = 2 << 0,
		PeripheralC = 3 << 0,
		PeripheralD = 4 << 0,
		PeripheralE = 5 << 0,
		PeripheralF = 6 << 0,
		PeripheralG = 7 << 0,
		PeripheralH = 8 << 0,
		PeripheralI = 9 << 0,
		GPIO_Input 	= 0 << 5,
		GPIO_Output = 1 << 5,
		Pullup 		= 1 << 6,
		Pulldown	= 1 << 7,
		Low			= 0 << 8,
		High		= 1 << 8,
		StrongDrive = 1 << 9,
		OutOfBounds	= 1 << 10
	};
private:
	Port port;
	uint8_t pin;
public:

	Pin();
	/**\brief Initialises a port pin
	 * \brief port indicates the port [A, B]
	 * \param pin indicates the pin [0: 32] (not the already shifted define!)
	 * \param f Pin config ORed together
	 */
	Pin(Port port, uint8_t pin, Function f);
	~Pin(){}

	void setHigh();
	void setLow();
	void toggle();
	uint8_t getValue();
	uint8_t getPin();
	uint8_t getPort();
};

inline Pin::Function operator| (Pin::Function lhs, Pin::Function rhs){
	return static_cast<Pin::Function>(static_cast<uint32_t>(lhs) | static_cast<uint32_t>(rhs));
}
inline Pin::Function operator| (Pin::Function lhs, uint32_t rhs){
	return static_cast<Pin::Function>(static_cast<uint32_t>(lhs) | rhs);
}
inline bool operator& (Pin::Function lhs, Pin::Function rhs){
	return static_cast<uint32_t>(lhs) & static_cast<uint32_t>(rhs);
}
inline bool operator& (Pin::Function lhs, uint32_t rhs){
	return static_cast<uint32_t>(lhs) & rhs;
}

#endif