#include <stdint.h>
#include "lcd.c"


/**************************************************

  Inspired by the Arduino LiquidCrystal library &
  https://github.com/bobc/bobc_hardware/tree/master/Firmware/control_panel_v2/arduino/drivers/LiquidCrystal

***************************************************/

// state after lcd_init()
static uint8_t _lcd_displaycontrol = _LCD_DEFAULT_STATE_DISPLAYCONTROL,
               _lcd_displaymode = _LCD_DEFAULT_STATE_DISPLAYMODE;

void lcd_home() {
  lcd_cmd(LCD_RETURNHOME);  // set cursor position to zero
  __delay_ms(2);            // this command takes a long time!
}

void lcd_print(const char *str) {
  while (*str) {
    lcd_dat(*str++);
  }
}

void lcd_clear() {
  lcd_cmd(LCD_CLEARDISPLAY); // clear display, set cursor position to zero
  __delay_ms(2);             // this command takes a long time!
}

void lcd_set_cursor(const uint8_t col, uint8_t row) {
  const int row_offsets[] = { 0x00, 0x40, 0x14, 0x54 };
  if (row > 1) { // PICSim.js has 2 rows
    row = 1;
  }
  lcd_cmd(LCD_SETDDRAMADDR | (col + row_offsets[row]));
}

void lcd_no_display() {
  _lcd_displaycontrol &= ~LCD_DISPLAYON;
  lcd_cmd(LCD_DISPLAYCONTROL | _lcd_displaycontrol);
}
void lcd_display() {
  _lcd_displaycontrol |= LCD_DISPLAYON;
  lcd_cmd(LCD_DISPLAYCONTROL | _lcd_displaycontrol);
}

// Turns the underline cursor on/off
void lcd_no_cursor() {
  _lcd_displaycontrol &= ~LCD_CURSORON;
  lcd_cmd(LCD_DISPLAYCONTROL | _lcd_displaycontrol);
}
void lcd_cursor() {
  _lcd_displaycontrol |= LCD_CURSORON;
  lcd_cmd(LCD_DISPLAYCONTROL | _lcd_displaycontrol);
}

// Turn on and off the blinking cursor
void lcd_no_blink() {
  _lcd_displaycontrol &= ~LCD_BLINKON;
  lcd_cmd(LCD_DISPLAYCONTROL | _lcd_displaycontrol);
}
void lcd_blink() {
  _lcd_displaycontrol |= LCD_BLINKON;
  lcd_cmd(LCD_DISPLAYCONTROL | _lcd_displaycontrol);
}

// These commands scroll the display without changing the RAM
void lcd_scroll_display_left(void) {
  lcd_cmd(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVELEFT);
}
void lcd_scroll_display_right(void) {
  lcd_cmd(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVERIGHT);
}

// This is for text that flows Left to Right
void lcd_left_to_right(void) {
  _lcd_displaymode |= LCD_ENTRYLEFT;
  lcd_cmd(LCD_ENTRYMODESET | _lcd_displaymode);
}

// This is for text that flows Right to Left
void lcd_right_to_left(void) {
  _lcd_displaymode &= ~LCD_ENTRYLEFT;
  lcd_cmd(LCD_ENTRYMODESET | _lcd_displaymode);
}

// This will 'right justify' text from the cursor
void lcd_autoscroll(void) {
  _lcd_displaymode |= LCD_ENTRYSHIFTINCREMENT;
  lcd_cmd(LCD_ENTRYMODESET | _lcd_displaymode);
}

// This will 'left justify' text from the cursor
void lcd_no_autoscroll(void) {
  _lcd_displaymode &= ~LCD_ENTRYSHIFTINCREMENT;
  lcd_cmd(LCD_ENTRYMODESET | _lcd_displaymode);
}

// Allows us to fill the first 8 CGRAM locations
// with custom characters
void lcd_create_char(uint8_t location, const uint8_t charmap[]) {
  location &= 0x7; // we only have 8 locations 0-7
  lcd_cmd(LCD_SETCGRAMADDR | (location << 3));
  for (int i = 0; i < 8; i++) {
    lcd_dat(charmap[i]);
  }
}