// Pin definitions based on wiring 
const int P2_PIN = A0; // Pressure sensor 2 
const int Q_PIN  = A1; // Air flow sensor    
const int P1_PIN = A2; // Pressure sensor 1 

// Constants for ADC conversion
const float VREF = 5.0;
const int ADC_MAX = 1023;

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
  float P2_MPa = pressureMPa(V_V2);
  float Q_L_min = flowLmin(V_Q);

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

  delay(100); // 10Hz sample frequency
}