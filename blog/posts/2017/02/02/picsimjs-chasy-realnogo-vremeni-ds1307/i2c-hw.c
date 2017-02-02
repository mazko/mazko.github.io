#include <stdint.h>
#include <stdbool.h>

static void i2c_open() {
  SSPSTAT &= 0x3F;              // power on state, bits 0b111111 are readonly
  SSPCON1 = 0;                  // power on state
  SSPCON2 = 0;                  // power on state
  SSPCON1bits.SSPM3 = 1;        // I2C Master mode
  SSPSTATbits.SMP   = 1;        // Slew rate control disabled for Standard Speed mode
  SSPADD = 42;                  // I2C clock = Fosc/(4 * (SSPADD + 1))
  SSPCON1bits.SSPEN = 1;        // Enable serial port and configures SCK, SDO, SDI
}

static i2c_stop_and_close() {
  SSPCON2bits.PEN = 1;          // Stop condition I2C on bus
  while (SSPCON2bits.PEN);      // Wait until STOP condition is over
  SSPCON1 &= 0xDF;              // Close I2C
}

static void i2c_idle() {
  while ((SSPCON2 & 0x1F) || SSPSTATbits.R_W);
}

static void i2c_start(const bool restart) {
  if (restart) {
    SSPCON2bits.RSEN = 1;       // restart condition
    while (SSPCON2bits.RSEN);   // wait until condition end
  } else {
    SSPCON2bits.SEN = 1;        // start condition
    while (SSPCON2bits.SEN);    // wait until condition end
  }
}

static void i2c_wb(const uint8_t val) {
  SSPBUF = val;                 // write single byte to SSPBUF
  while (SSPSTATbits.BF);       // wait until write cycle is complete
}

static uint8_t i2c_rb(const bool ack) {
  SSPCON2bits.RCEN = 1;         // enable master for 1 byte reception
  while (!SSPSTATbits.BF);      // wait until byte received
  const uint8_t data = SSPBUF;  // read to variable
  //while (SSPCON2bits.RCEN);     // check that receive sequence is over  

  SSPCON2bits.ACKDT = !ack;     // set acknowledge bit for ACK
  SSPCON2bits.ACKEN = 1;        // initiate bus acknowledge sequence

  while (SSPCON2bits.ACKEN);    // Wait until ACK sequence is over

  return data;
}