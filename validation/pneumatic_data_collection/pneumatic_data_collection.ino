// Pin definitions based on wiring 
// [CHANGED] Removed P1_PIN (A2) — pressure sensor 1 no longer used
const int P2_PIN = A0; // Pressure sensor 2 
const int Q_PIN  = A1; // Air flow sensor    

// Constants for ADC conversion
const float VREF = 5.0;
const int ADC_MAX = 1023;

// === NEW: SOFTWARE SAFETY SETTINGS ===
const float MAX_SAFE_PRESSURE = 0.5; // Max allowed pressure in MPa (e.g., 8 bar)
const unsigned long MAX_OVERPRESSURE_TIME = 2000; // Allowed spike duration in milliseconds (2 seconds)

unsigned long overpressureStartTime = 0; 
bool safetyTripped = false;

void setup() {
  Serial.begin(9600);
  // [CHANGED] No CSV header printed — using label:value format instead.
  // The Serial Plotter reads label:value pairs to show custom legend names.
}

// Conversion of raw ADC to voltage
float readVoltage(int pin) {
  int raw = analogRead(pin);
  float voltage = raw * (VREF / (float)ADC_MAX);
  return voltage;
}

// PSE570-02: 1V to 5V maps to 0 to 1 MPa
float pressureMPa(float voltage) {
  float pressure = (voltage - 1.0) / 4.0;
  if (pressure < 0) pressure = 0; // Grounding floor for noise
  return pressure;
}

// PF2A521-F03-1: 1V to 5V maps to 0 to 100 L/min (verify range with datasheet)
float flowLmin(float voltage) {
  float flow = 45.0 * voltage - 25.0; 
  if (flow < 0) flow = 0;
  return flow;
}

void loop() {
  // Timestamp (not sent to serial — plotter handles X-axis, MATLAB uses its own timer)
  float time_s = millis() / 1000.0;

  // Read voltages
  float V_P2 = readVoltage(P2_PIN);
  float V_Q  = readVoltage(Q_PIN);

  // Convert to engineering units
  float P2_MPa = pressureMPa(V_P2);
  float Q_L_min = flowLmin(V_Q);

// === SOFTWARE SAFETY CHECK ===
  // [CHANGED] Safety check now only monitors P2 — P1 sensor removed
  if (P2_MPa > MAX_SAFE_PRESSURE) {
    if (overpressureStartTime == 0) {
      overpressureStartTime = millis(); // Start timing the spike
    }
    
    // If the pressure stays too high for longer than allowed, trip the safety
    if ((millis() - overpressureStartTime) > MAX_OVERPRESSURE_TIME) {
      safetyTripped = true;
    }
  } else {
    overpressureStartTime = 0; // Reset timer if pressure drops back to normal
  }

  // [CHANGED] Output in label:value format for Serial Plotter custom names
  // Format: "V_P2:x.xxx,V_Q:x.xxx,P2_MPa:x.xxxx,Q_Lmin:xx.xx,Safety:0or1"
  // Safety encoded as numeric: 0 = NORMAL, 1 = CRITICAL_OVERPRESSURE
  // time_s omitted — its ever-increasing value would dominate the Y-axis scale
  Serial.print("V_P2:");
  Serial.print(V_P2, 3);
  Serial.print(",");
  Serial.print("V_Q:");
  Serial.print(V_Q, 3);
  Serial.print(",");
  Serial.print("P2_MPa:");
  Serial.print(P2_MPa, 4);
  Serial.print(",");
  Serial.print("Q_Lmin:");
  Serial.print(Q_L_min, 2);
  Serial.print(",");
  Serial.print("Safety:");
  Serial.println(safetyTripped ? 1 : 0);
  
  delay(10); // [FIXED] ~100Hz sample rate (delay is 10ms, not 1s)
}