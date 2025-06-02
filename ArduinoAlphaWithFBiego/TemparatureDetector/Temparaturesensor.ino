const int tempPin = A3;
const int ledCool = 11;
const int ledNormal = 12;
const int ledHot = 13;
const int buzzer = 9;

void setup() {
  pinMode(ledCool, OUTPUT);
  pinMode(ledNormal, OUTPUT);
  pinMode(ledHot, OUTPUT);
  pinMode(buzzer, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int sensorVal = analogRead(tempPin);
  float voltage = sensorVal * (5.0 / 1023.0);
  float temperatureC = (voltage - 0.5) * 100;

  Serial.println(temperatureC);

  // Turn all LEDs ON first
  digitalWrite(ledCool, HIGH);
  digitalWrite(ledNormal, HIGH);
  digitalWrite(ledHot, HIGH);
  digitalWrite(buzzer, LOW);

  if (temperatureC < 20) {
    // Cool condition: turn OFF cool LED
    digitalWrite(ledCool, LOW);
  } else if (temperatureC < 30) {
    // Normal: turn OFF normal LED
    digitalWrite(ledNormal, LOW);
  } else {
    // Hot: turn OFF hot LED and activate buzzer
    digitalWrite(ledHot, LOW);
    tone(buzzer, 1000, 200);
  }

  delay(1000);
}
