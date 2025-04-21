#include "LiquidCrystal_I2C.h";
#include<Wire.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

//ultrasonic pins
const int trigPin = 2, echoPin = 3;
//relay pin
const int relayPin = 10;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(relayPin, OUTPUT);

  // initialize the LCD
  lcd.begin();
  // Turn on the blacklight
  lcd.backlight();
  lcd.print("Initializing...");
  delay(2000);
  lcd.clear();
}

void loop() {
  // put your main code here, to run repeatedly:
  long duration, cm;
  
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH);
  
  long distance_cm = duration /29 / 2;

  if(distance_cm <= 10) {
    //turn off the pump
    Serial.print("Distance less than 10 cm:   ");
    digitalWrite(relayPin, HIGH);
    delay(50);
  }
  else if(distance_cm >= 30) {
    //turn on the pump
    Serial.print("Distance greater than 30 cm:   ");
    digitalWrite(relayPin, LOW);
    delay(50);
  }

  Serial.print(distance_cm);
  Serial.print("cm");
  
  lcd.setCursor(0, 0);
  lcd.print("Distance: ");
  lcd.print(distance_cm);
  lcd.print("cm ");
  lcd.setCursor(0, 1);
  lcd.print("Pump: ");
  if(distance_cm >= 30) {
    lcd.print("ON ");
  }
  else if(distance_cm <=10) {
    lcd.print("OFF");
  }

  Serial.print("\n");
  delay(50);

}
