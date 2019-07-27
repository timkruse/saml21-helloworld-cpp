#include "Timer.h"
#include "System.h"

/**
 * periode: [0:255]
 * prescaler: TC_CTRLA_PRESCALER_DIVxxx_Val
 * tc: timer instance
 * info: clock needs to be configured in advance!
 */
void timer_init(TcCount8 *tc, timer_prescaler_t prescaler, uint8_t periode){
	// disable clock before configuring
	// disabling sets stop flag in status -> needs to be
	tc->CTRLA.bit.ENABLE = false;
	while(tc->SYNCBUSY.bit.ENABLE);

	TC_CTRLA_Type tc_ctrla_config = {.reg = 0};
	tc_ctrla_config.bit.PRESCALER = static_cast<uint8_t>(prescaler);
	tc_ctrla_config.bit.MODE = TC_CTRLA_MODE_COUNT8_Val;

	tc->CTRLA.reg = tc_ctrla_config.reg; 
	tc->PER.bit.PER = periode; // 48Mhz / 30 / 8 / 29 = 145us , Periode reg can only be written if 8bit mode is setup
	
}

void timer_enableInterrupts(TcCount8 *tc, IRQn_Type irqn, uint8_t prio, timer_interrupt_t type){
	NVIC_ClearPendingIRQ(irqn);
	NVIC_SetPriority(irqn, prio); 
	NVIC_EnableIRQ(irqn);
	timer_interruptTriggeredBy(tc, type);
}

void timer_interruptTriggeredBy(TcCount8 *tc, timer_interrupt_t type){
	if(type & timer_interrupt_t::OVF){
		tc->INTENSET.bit.OVF = true; // enable overflow interrupt
	}
	if(type & timer_interrupt_t::ERR){
		tc->INTENSET.bit.ERR = true; // enable error interrupt
	}
	if(type & timer_interrupt_t::MC0){
		tc->INTENSET.bit.MC0 = true; // enable compare match0 interrupt
	}
	if(type & timer_interrupt_t::MC1){
		tc->INTENSET.bit.MC1 = true; // enable compare match1 interrupt
	}
}

void timer_enable(TcCount8 *tc){

	tc->CTRLA.bit.ENABLE = true;
	while(tc->SYNCBUSY.bit.ENABLE);
}
void timer_start(TcCount8 *tc){
	tc->CTRLBSET.bit.CMD = TC_CTRLBSET_CMD_RETRIGGER_Val;
}
void timer_stop(TcCount8 *tc){
	tc->CTRLBSET.bit.CMD = TC_CTRLBSET_CMD_STOP_Val;
}

void timer_disable(TcCount8 *tc){
	tc->CTRLA.bit.ENABLE = false;
	while(tc->SYNCBUSY.bit.ENABLE);
}

void timer_setPeriode(TcCount8 *tc, uint8_t newVal){
	tc->PER.bit.PER = newVal;
}

void timer_setCount(TcCount8 *tc, uint8_t newVal){
	tc->COUNT.reg = newVal;
}

void timer_setOneshot(TcCount8 *tc){
	tc->CTRLBSET.bit.ONESHOT = true; // mind its SETbit = true
}
void timer_setRepeating(TcCount8 *tc){
	tc->CTRLBCLR.bit.ONESHOT = true; // mind its CLRbit = true
}