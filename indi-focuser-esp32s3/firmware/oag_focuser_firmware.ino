/**
 * OAG Focuser Firmware — ESP32-S3 / Arduino Nano ESP32 edition
 *
 * Hardware:
 *   - Arduino Nano ESP32 (ESP32-S3R8, NORA-W106-10B module)
 *   - 28BYJ-48 stepper motor (5V, 4-phase unipolar)
 *   - ULN2003 driver board
 *
 * ── CRITICAL DIFFERENCES vs ATmega328P Nano ──────────────────────────────────
 *
 * 1. LOGIC LEVEL — The ESP32-S3 runs at 3.3 V. The ULN2003 input threshold is
 *    ~1 V, so 3.3 V logic drives it reliably. No level shifter needed.
 *
 * 2. MOTOR POWER — The 28BYJ-48 runs on 5 V. Power the ULN2003 board's VCC
 *    from the Nano ESP32's 5V pin (VBUS, available when USB is connected) or
 *    from a separate 5 V supply. Do NOT power the motor from the 3.3 V rail.
 *
 * 3. PIN DEFINITIONS — Use the Arduino D-label names (D2, D3, etc.) rather
 *    than raw integers. The Nano ESP32 has two pin-numbering modes; the D-labels
 *    work correctly in both. Using bare integers (2, 3…) maps to GPIO numbers,
 *    which are completely different from the Nano labels on this board.
 *
 * 4. pinMode() IS REQUIRED — The ESP32-S3 does NOT default output pins to LOW.
 *    Without explicit pinMode(x, OUTPUT), the ULN2003 inputs float and the
 *    motor either jitters or draws current continuously. Always call pinMode()
 *    before any digitalWrite().
 *
 * 5. EEPROM — The ESP32-S3 has no true EEPROM. The Arduino-ESP32 core emulates
 *    it using a 4 KB flash partition. You must call EEPROM.begin(size) before
 *    any read/write and EEPROM.commit() after writes, otherwise data is never
 *    actually written to flash.
 *
 * 6. STEP TIMING — The ESP32-S3 is much faster than ATmega. delayMicroseconds()
 *    is accurate but the motor needs ≥ 1 ms per step at full speed to avoid
 *    missing steps. 1200 µs half-step delay is conservative and reliable.
 *
 * ── Wiring ────────────────────────────────────────────────────────────────────
 *   ULN2003 board → Nano ESP32 pin
 *   IN1            → D2
 *   IN2            → D3
 *   IN3            → D4
 *   IN4            → D5
 *   VCC            → 5V  (VBUS — USB power or external 5 V)
 *   GND            → GND
 *
 *   Pins D2-D5 were chosen because:
 *     - They are not strapping pins (avoids boot issues)
 *     - They are not the UART pins (D0/D1)
 *     - Confirmed working with ULN2003 in community testing
 *
 * ── Serial protocol ───────────────────────────────────────────────────────────
 *   115200 baud, newline-terminated. Identical to the jlecomte ASCOM driver
 *   protocol so the INDI driver works without modification.
 */

#include <EEPROM.h>

// ── Motor pins — use D-label names, not raw GPIO integers ─────────────────────
#define IN1 D2
#define IN2 D3
#define IN3 D4
#define IN4 D5

// ── Half-step sequence for 28BYJ-48 ──────────────────────────────────────────
// 8-phase half-step. Gives smoother motion and double the resolution vs full-step.
const uint8_t STEP_SEQ[8][4] = {
  {1, 0, 0, 0},
  {1, 1, 0, 0},
  {0, 1, 0, 0},
  {0, 1, 1, 0},
  {0, 0, 1, 0},
  {0, 0, 1, 1},
  {0, 0, 0, 1},
  {1, 0, 0, 1}
};

// ── EEPROM layout ─────────────────────────────────────────────────────────────
// ESP32-S3: must call EEPROM.begin() before use, EEPROM.commit() after write.
#define EEPROM_SIZE      8
#define EEPROM_MAGIC_0   0x00
#define EEPROM_MAGIC_1   0x01
#define EEPROM_POS_ADDR  0x02   // 4 bytes (long)
#define EEPROM_REV_ADDR  0x06   // 1 byte
#define MAGIC_BYTE_0     0xDA
#define MAGIC_BYTE_1     0x7A

// ── Limits ────────────────────────────────────────────────────────────────────
#define MAX_POSITION     32767L
#define STEP_DELAY_US    1200   // µs per half-step — do not reduce below ~800

// ── State ─────────────────────────────────────────────────────────────────────
long    currentPosition  = 0;
long    targetPosition   = 0;
bool    isMoving         = false;
bool    reverseDirection = false;
uint8_t stepIndex        = 0;
String  inputBuffer      = "";

// ── EEPROM helpers (ESP32-S3 flash emulation) ─────────────────────────────────
void saveState() {
  EEPROM.write(EEPROM_MAGIC_0, MAGIC_BYTE_0);
  EEPROM.write(EEPROM_MAGIC_1, MAGIC_BYTE_1);

  // Write long position byte-by-byte
  uint8_t *p = (uint8_t *)&currentPosition;
  for (int i = 0; i < 4; i++) {
    EEPROM.write(EEPROM_POS_ADDR + i, p[i]);
  }

  EEPROM.write(EEPROM_REV_ADDR, reverseDirection ? 0x01 : 0x00);
  EEPROM.commit();  // ← required on ESP32; no-op on AVR
}

void loadState() {
  if (EEPROM.read(EEPROM_MAGIC_0) == MAGIC_BYTE_0 &&
      EEPROM.read(EEPROM_MAGIC_1) == MAGIC_BYTE_1) {
    uint8_t *p = (uint8_t *)&currentPosition;
    for (int i = 0; i < 4; i++) {
      p[i] = EEPROM.read(EEPROM_POS_ADDR + i);
    }
    reverseDirection = (EEPROM.read(EEPROM_REV_ADDR) == 0x01);
  } else {
    currentPosition  = 0;
    reverseDirection = false;
    saveState();
  }
  targetPosition = currentPosition;
}

// ── Motor helpers ─────────────────────────────────────────────────────────────
void applyStep(uint8_t idx) {
  digitalWrite(IN1, STEP_SEQ[idx][0]);
  digitalWrite(IN2, STEP_SEQ[idx][1]);
  digitalWrite(IN3, STEP_SEQ[idx][2]);
  digitalWrite(IN4, STEP_SEQ[idx][3]);
}

void deenergise() {
  // De-energise fully — prevents heat buildup and vibration when idle.
  // Especially important on the ESP32-S3: pins stay in their last state
  // indefinitely unlike AVR which can be reset.
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void stepOnce(bool forward) {
  bool actualForward = reverseDirection ? !forward : forward;
  if (actualForward) {
    stepIndex = (stepIndex + 1) % 8;
  } else {
    stepIndex = (stepIndex + 7) % 8;
  }
  applyStep(stepIndex);
  delayMicroseconds(STEP_DELAY_US);
}

// ── Command handler ───────────────────────────────────────────────────────────
void handleCommand(String cmd) {
  cmd.trim();

  if (cmd == "COMMAND:FOCUSER:GETPOSITION") {
    Serial.println("REPLY:FOCUSER:POSITION:" + String(currentPosition));

  } else if (cmd == "COMMAND:FOCUSER:ISMOVING") {
    Serial.println("REPLY:FOCUSER:ISMOVING:" + String(isMoving ? "1" : "0"));

  } else if (cmd == "COMMAND:FOCUSER:GETMAXPOSITION") {
    Serial.println("REPLY:FOCUSER:MAXPOSITION:" + String(MAX_POSITION));

  } else if (cmd == "COMMAND:FOCUSER:SETZERO") {
    currentPosition = 0;
    targetPosition  = 0;
    saveState();
    Serial.println("REPLY:FOCUSER:OK");

  } else if (cmd == "COMMAND:FOCUSER:HALT") {
    targetPosition = currentPosition;
    isMoving       = false;
    deenergise();
    saveState();
    Serial.println("REPLY:FOCUSER:OK");

  } else if (cmd.startsWith("COMMAND:FOCUSER:MOVE:")) {
    long requested = cmd.substring(21).toInt();
    requested = constrain(requested, 0L, MAX_POSITION);
    targetPosition = requested;
    isMoving = (targetPosition != currentPosition);
    Serial.println("REPLY:FOCUSER:OK");

  } else if (cmd == "COMMAND:FOCUSER:GETREVERSE") {
    Serial.println("REPLY:FOCUSER:REVERSE:" + String(reverseDirection ? "1" : "0"));

  } else if (cmd.startsWith("COMMAND:FOCUSER:SETREVERSE:")) {
    reverseDirection = (cmd.substring(27) == "1");
    saveState();
    Serial.println("REPLY:FOCUSER:OK");

  } else if (cmd == "COMMAND:FOCUSER:HANDSHAKE") {
    Serial.println("REPLY:FOCUSER:READY");

  } else {
    Serial.println("REPLY:FOCUSER:ERROR:UNKNOWN_COMMAND");
  }
}

// ── Setup ─────────────────────────────────────────────────────────────────────
void setup() {
  // pinMode MUST be called before digitalWrite on ESP32-S3.
  // Skipping this causes the motor pins to float and the ULN2003 to behave
  // erratically — the most common cause of "works on Nano, fails on ESP32".
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  deenergise();

  // Initialise flash-based EEPROM emulation (ESP32 requirement)
  EEPROM.begin(EEPROM_SIZE);

  Serial.begin(115200);
  loadState();

  // Signal ready to INDI driver / test utility
  Serial.println("REPLY:FOCUSER:READY");
}

// ── Loop ──────────────────────────────────────────────────────────────────────
void loop() {
  // ── Serial input ──────────────────────────────────────────────────────────
  while (Serial.available() > 0) {
    char c = (char)Serial.read();
    if (c == '\n' || c == '\r') {
      if (inputBuffer.length() > 0) {
        handleCommand(inputBuffer);
        inputBuffer = "";
      }
    } else {
      inputBuffer += c;
    }
  }

  // ── Stepping ──────────────────────────────────────────────────────────────
  if (isMoving) {
    bool forward = (targetPosition > currentPosition);
    stepOnce(forward);

    currentPosition += forward ? 1 : -1;

    if (currentPosition == targetPosition) {
      isMoving = false;
      deenergise();
      saveState();
    }
  }
}
