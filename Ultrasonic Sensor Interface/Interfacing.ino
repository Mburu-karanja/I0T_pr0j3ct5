Docs
sketch.ino
diagram.json
Library Manager

#define TRIG_PIN  3
#define ECHO_PIN 2 
void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  Serial.println("Hello, ESP32!");
}

void loop() {

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // Read the result:
  int duration = pulseIn(ECHO_PIN, HIGH);
  Serial.print("Distance in CM: ");
  Serial.println(duration / 58);
  Serial.print("Distance in inches: ");
  Serial.println(duration / 148);

  delay(1000);
}
Simulation
