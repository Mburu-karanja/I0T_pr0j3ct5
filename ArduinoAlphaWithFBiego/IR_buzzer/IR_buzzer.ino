#include <IRremote.h>

const int irRxPin = 7;
const int irTxPin = 4;
const int buzzerPin = 9;
const int buttonPin = A4;

const int ledReceived = 13;
const int ledSent = 12;
const int ledError = 11;

IRrecv irrecv(irRxPin);
IRsend irsend(irTxPin);
decode_results results;

unsigned int *rawData = nullptr;
unsigned int rawLen = 0;
bool hasSignal = false;

void setup() {
  Serial.begin(9600);
  irrecv.enableIRIn();

  pinMode(buzzerPin, OUTPUT);
  pinMode(buttonPin, INPUT_PULLUP);  // Button pressed = LOW
  pinMode(ledReceived, OUTPUT);
  pinMode(ledSent, OUTPUT);
  pinMode(ledError, OUTPUT);

  digitalWrite(ledReceived, LOW);
  digitalWrite(ledSent, LOW);
  digitalWrite(ledError, LOW);
}

void loop() {
  if (irrecv.decode(&results)) {
    tone(buzzerPin, 1500, 150);
    blinkLED(ledReceived, 2, 100);

    // Free old buffer if any
    if (rawData != nullptr) {
      free(rawData);
      rawData = nullptr;
    }

    rawLen = results.rawlen;
    rawData = (unsigned int *)malloc(rawLen * sizeof(unsigned int));
    if (rawData != nullptr) {
      for (unsigned int i = 0; i < rawLen; i++) {
        rawData[i] = results.rawbuf[i];
      }
      hasSignal = true;
      Serial.println("IR signal saved!");
    } else {
      Serial.println("Memory allocation failed!");
      hasSignal = false;
    }

    irrecv.resume();
  }

  if (digitalRead(buttonPin) == LOW) {
    if (hasSignal) {
      Serial.println("Transmitting saved IR signal...");
      irsend.sendRaw(rawData, rawLen, 38);  
      tone(buzzerPin, 1000, 150);
      blinkLED(ledSent, 3, 100);
    } else {
      Serial.println("No IR signal saved yet.");
      blinkLED(ledError, 3, 200);
    }

    while (digitalRead(buttonPin) == LOW) {
      delay(10);
    }
  }
}

void blinkLED(int pin, int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(pin, HIGH);
    delay(delayMs);
    digitalWrite(pin, LOW);
    delay(delayMs);
  }
}
