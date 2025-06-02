const int potPitch = A1;
const int potDuration = A2;
const int button = A4;
const int buzzer = 9;
const int led = 13;

// Note frequencies
#define NOTE_C4  262
#define NOTE_D4  294
#define NOTE_E4  330
#define NOTE_F4  349
#define NOTE_G4  392
#define NOTE_A4  440
#define NOTE_B4  494
#define NOTE_AS4 466
#define NOTE_C5  523

// Happy Birthday melody
int melody[] = {
  NOTE_C4, NOTE_C4, NOTE_D4, NOTE_C4, NOTE_F4, NOTE_E4,
  NOTE_C4, NOTE_C4, NOTE_D4, NOTE_C4, NOTE_G4, NOTE_F4,
  NOTE_C4, NOTE_C4, NOTE_C5, NOTE_A4, NOTE_F4, NOTE_E4, NOTE_D4,
  NOTE_AS4, NOTE_AS4, NOTE_A4, NOTE_F4, NOTE_G4, NOTE_F4
};

// Note durations (milliseconds)
int durations[] = {
  250, 250, 500, 500, 500, 1000,
  250, 250, 500, 500, 500, 1000,
  250, 250, 500, 500, 500, 500, 1000,
  250, 250, 500, 500, 500, 1000
};

const int notesCount = sizeof(melody) / sizeof(melody[0]);

void setup() {
  pinMode(potPitch, INPUT);
  pinMode(potDuration, INPUT);
  pinMode(button, INPUT_PULLUP);
  pinMode(buzzer, OUTPUT);
  pinMode(led, OUTPUT);
}

void loop() {
  int buttonState = digitalRead(button);

  if (buttonState == LOW) { // Button pressed
    digitalWrite(led, HIGH);

    for (int i = 0; i < notesCount; i++) {
      // Read pots before each note for real-time control
      int pitchControl = analogRead(potPitch);
      int tempoControl = analogRead(potDuration);

      float pitchFactor = map(pitchControl, 0, 1023, 80, 120) / 100.0;  // 0.8x to 1.2x pitch
      float tempoFactor = map(tempoControl, 0, 1023, 50, 150) / 100.0;  // 0.5x to 1.5x tempo

      int noteFreq = melody[i] * pitchFactor;
      int noteDuration = durations[i] * tempoFactor;

      tone(buzzer, noteFreq, noteDuration);

      delay(noteDuration * 1.3);  // pause between notes
    }

    digitalWrite(led, LOW);
    delay(500); // debounce delay
  } else {
    digitalWrite(led, LOW);
    noTone(buzzer);
  }

  delay(50);
}
