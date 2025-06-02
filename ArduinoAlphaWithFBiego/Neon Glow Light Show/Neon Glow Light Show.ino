const int ldrPin = A0;
const int led1 = 13; // Neon LED 1
const int led2 = 12; // Neon LED 2
const int led3 = 11; // Neon LED 3 
void setup() {
  pinMode(led1, OUTPUT);
  pinMode(led2, OUTPUT);
  pinMode(led3, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int lightLevel = analogRead(ldrPin);
  Serial.println(lightLevel);
  if (lightLevel < 500) { 
    
    digitalWrite(led1, random(0, 2));
    digitalWrite(led2, random(0, 2));
    digitalWrite(led3, random(0, 2));
    delay(random(100, 300));  
  } else { 
    digitalWrite(led1, LOW);
    digitalWrite(led2, LOW);

    digitalWrite(led3, HIGH);
    delay(500);
    digitalWrite(led3, LOW);
    delay(500);
  }
}
