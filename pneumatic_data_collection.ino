// Pin definitions based on wiring 
const int P2_PIN = A0; // Pressure sensor 2 
const int Q_PIN  = A1; // Air flow sensor    
const int P1_PIN = A2; // Pressure sensor 1 

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
  
  // CSV file header
  Serial.println("time_s,V_P1,V_P2,V_Q,P1_MPa,P2_MPa,Q_L_min");
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
  // Timestamp
  float time_s = millis() / 1000.0;

  // Read voltages
  float V_P1 = readVoltage(P1_PIN);
  float V_P2 = readVoltage(P2_PIN);
  float V_Q  = readVoltage(Q_PIN);

  // Convert to engineering units
  float P1_MPa = pressureMPa(V_P1);
  float P2_MPa = pressureMPa(V_P2);
  float Q_L_min = flowLmin(V_Q);

// === SOFTWARE SAFETY CHECK ===
  // Check if either pressure sensor exceeds the maximum safe limit
  if (P1_MPa > MAX_SAFE_PRESSURE || P2_MPa > MAX_SAFE_PRESSURE) {
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

  // Output in CSV format
  Serial.print(time_s, 3);
  Serial.print(",");
  
  Serial.print(V_P1, 3);
  Serial.print(",");
  Serial.print(V_P2, 3);
  Serial.print(",");
  Serial.print(V_Q, 3);
  Serial.print(",");
  
  Serial.print(P1_MPa, 4);
  Serial.print(",");
  Serial.print(P2_MPa, 4);
  Serial.print(",");
  Serial.println(Q_L_min, 2);

// Append safety status string so MATLAB can read it
  if (safetyTripped) {
    Serial.println("CRITICAL_OVERPRESSURE");
  } else {
    Serial.println("NORMAL");
  }
  
  delay(10); // 1Hz sample frequency
}