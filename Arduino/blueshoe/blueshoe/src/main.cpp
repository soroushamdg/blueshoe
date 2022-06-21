#include <Arduino.h>
#include <EEPROM.h>
#include <Preferences.h>

#include <Time.h>
#include <TimeAlarms.h>

#include <Wire.h> // Wire library - used for I2C communication
#include <ADXL345.h>

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#include <valuetimelapse.h>
#include <def_bleuuid.h>

#define ONBOARD_LED_PIN 2

#include <BLEpedometer.h>

Preferences preferences;

int16_t X_OFFSET;
int16_t Y_OFFSET;
int16_t Z_OFFSET;

TaskHandle_t handle_pedometerTask;

bool deviceConnected = false;

uint16_t pedometerCounter = 0;

AlarmID_t refreshAlarm;

ADXL345 accel(ADXL345_ALT);

int16_t Y_out, Z_out; // Outputs

uint16_t y2z2_out;
uint16_t y2z2_out_old;

uint16_t steadySamples = 0;

BLEServer *_server;
uint16_t connectID;

// battery, something counter, on/off led, serial communicate.

class BLECallbacks : public BLEServerCallbacks
{

  void onConnect(BLEServer *server)
  {
    Serial.print("Connected to ");
    Serial.print(server->getConnectedCount());
    Serial.println("devices.");
    connectID = server->getConnId();
    Alarm.enable(refreshAlarm);

    deviceConnected = true;
  }

  void onDisconnect(BLEServer *server)
  {

    Serial.println("Disonnected device.");
    Alarm.disable(refreshAlarm);
    deviceConnected = false;
    if (steadySamples != 0)
    {
      server->getAdvertising()->addServiceUUID(PHYSICALACTIVITYMONITOR_SERVICE_UUID);
      server->getAdvertising()->start();
      Serial.println("Started advertising again...");
    }
  }
};

class pedometerCharCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    pCharacteristic->setValue(":OK:");
  }
};

BLEpedometerController BLEpedometer = BLEpedometerController();

void refreshBLEvalues()
{
  if (!deviceConnected)
  {
    return;
  }

  Serial.println("RUNNING REFRESH.");

  try
  {
    Alarm.delay(500);
    BLEpedometer.refresh(pedometerCounter);
    pedometerCounter = 0;
  }
  catch (const std::exception &e)
  {
    Serial.println(e.what());
  }
}

void changerandomvalues()
{
  // pedometerCounter = (uint16_t)(random(65533));
  Serial.print("pedometer value -> ");
  preferences.putUShort("counter", pedometerCounter);

  Serial.println(pedometerCounter);
  Serial.println(preferences.getUShort("counter"));
}

void calibrate()
{
  int16_t dataX_sum = 0;
  int16_t dataY_sum = 0;
  int16_t dataZ_sum = 0;

  for (int i = 0; i < 25; i++)
  {
    if (accel.update())
    {
      dataX_sum += accel.getRawX();
      dataY_sum += accel.getRawY();
      dataZ_sum += accel.getRawZ();
    }
    Alarm.delay(100);
  }
  X_OFFSET = dataX_sum / 25;
  Y_OFFSET = dataY_sum / 25;
  Z_OFFSET = dataZ_sum / 25;
}

uint16_t eeprom_read_pedo()
{
  return (uint16_t)(8 << EEPROM.read(0)) + (EEPROM.read(1));
}

void eeprom_write_pedo()
{
  EEPROM.write(pedometerCounter >> 8, 0);
  EEPROM.write((pedometerCounter << 8) >> 8, 1);
}

byte read_register(int I2CAddress, byte address)
{
  // Send a request
  // Start talking to the device at the specified address
  Wire.beginTransmission(I2CAddress);
  // Send a bit asking for requested register address
  Wire.write(address);
  // Complete Transmission
  Wire.endTransmission(false);
  // Read the register from the device
  // Request 1 Byte from the specified address
  Wire.requestFrom(I2CAddress, 1);
  // wait for response
  while (Wire.available() == 0)
    ;
  // Get the temp and read it into a variable
  byte data = Wire.read();
  return data;
}

// Writes a single byte (data) into address
void write_register(int I2CAddress, unsigned char address, unsigned char data)
{
  // Send a request
  // Start talking to the device at the specified address
  Wire.beginTransmission(I2CAddress);
  // Send a bit asking for requested register address
  Wire.write(address);
  Wire.write(data);
  // Complete Transmission
  Wire.endTransmission(true);
}

void Ext_INT1_ISR()
{
  Serial.println("Interrupt called");
}

void setup()
{
  Serial.begin(115250);

  BLEDevice::init("BlueTest");
  pinMode(ONBOARD_LED_PIN, OUTPUT); // Declare the LED as an output

  preferences.begin("pedocounter", false);

  esp_sleep_enable_touchpad_wakeup();

  esp_sleep_wakeup_cause_t wakeup_reason;

  wakeup_reason = esp_sleep_get_wakeup_cause();

  switch (wakeup_reason)
  {
  case ESP_SLEEP_WAKEUP_EXT0:
    Serial.println("Wakeup caused by external signal using RTC_IO");
    break;
  case ESP_SLEEP_WAKEUP_EXT1:
    Serial.println("Wakeup caused by external signal using RTC_CNTL");
    break;
  case ESP_SLEEP_WAKEUP_TIMER:
    Serial.println("Wakeup caused by timer");
    break;
  case ESP_SLEEP_WAKEUP_TOUCHPAD:
    Serial.println("Wakeup caused by touchpad");
    break;
  case ESP_SLEEP_WAKEUP_ULP:
    Serial.println("Wakeup caused by ULP program");
    break;
  default:
    Serial.printf("Wakeup was not caused by deep sleep: %d\n", wakeup_reason);
    break;
  }

  Wire.begin(); // Initiate the Wire library

  byte deviceID = accel.readDeviceID();
  if (deviceID != 0)
  {
    Serial.print("0x");
    Serial.print(deviceID, HEX);
    Serial.println("");
  }
  else
  {
    Serial.println("read device id: failed");
    while (1)
    {
      delay(100);
    }
  }

  // Data Rate
  // - ADXL345_RATE_3200HZ: 3200 Hz
  // - ADXL345_RATE_1600HZ: 1600 Hz
  // - ADXL345_RATE_800HZ:  800 Hz
  // - ADXL345_RATE_400HZ:  400 Hz
  // - ADXL345_RATE_200HZ:  200 Hz
  // - ADXL345_RATE_100HZ:  100 Hz
  // - ADXL345_RATE_50HZ:   50 Hz
  // - ADXL345_RATE_25HZ:   25 Hz
  // // - ...
  if (!accel.writeRate(ADXL345_RATE_25HZ))
  {
    Serial.println("write rate: failed");
    while (1)
    {
      delay(100);
    }
  }

  // Data Range
  // - ADXL345_RANGE_2G: +-2 g
  // - ADXL345_RANGE_4G: +-4 g
  // - ADXL345_RANGE_8G: +-8 g
  // - ADXL345_RANGE_16G: +-16 g
  if (!accel.writeRange(ADXL345_RANGE_2G))
  {
    Serial.println("write range: failed");
    while (1)
    {
      delay(100);
    }
  }

  if (!accel.start())
  {
    Serial.println("start: failed");
    while (1)
    {
      delay(100);
    }
  }

  // // accel.setActivityXYZ();
  // write_register(0x53, 0x27, 0b01110000);
  // // accel.setActivityThreshold(0);
  // int activityThreshold = constrain(10, 0, 255);
  // byte _b = byte(activityThreshold);
  // write_register(0x53, 0x24, _b);
  // // accel.setInterruptMapping(0x04, 0x00);
  // write_register(0x53, 0x2f, 0b11111111);
  // // accel.setInterruptEnable(0x04, 1);
  // write_register(0x53, 0x2e, 0b11111111);

  write_register(0x53, 0x24, 0x04);
  write_register(0x53, 0x25, 0x02);
  write_register(0x53, 0x26, 0x01); // time register
  write_register(0x53, 0x27, 0b00111000);
  write_register(0x53, 0x2D, 0x38); // accelerometer auto-sleep
  write_register(0x53, 0x2F, 0x08);
  write_register(0x53, 0x2E, 0x18);

  // Serial.println(read_register(0x53, 0x27), BIN);
  // Serial.println(read_register(0x53, 0x24), BIN);
  // Serial.println(read_register(0x53, 0x2f), BIN);
  // Serial.println(read_register(0x53, 0x2e), BIN);
  // Serial.println(read_register(0x53, 0x30), BIN);

  Serial.println(read_register(0x53, 0x24), BIN);
  Serial.println(read_register(0x53, 0x25), BIN);
  Serial.println(read_register(0x53, 0x26), BIN);
  Serial.println(read_register(0x53, 0x27), BIN);
  Serial.println(read_register(0x53, 0x2D), BIN); // accelerometer auto-sleep
  Serial.println(read_register(0x53, 0x2F), BIN);
  Serial.println(read_register(0x53, 0x2E), BIN);
  Serial.println(read_register(0x53, 0x30), BIN);

  attachInterrupt(digitalPinToInterrupt(35), Ext_INT1_ISR, RISING);
  touchAttachInterrupt(T3, Ext_INT1_ISR, 40);

  read_register(0x53, 0x30);

  setTime(0, 0, 0, 0, 0, 0);

  _server = BLEDevice::createServer();
  _server->setCallbacks(new BLECallbacks());

  // INITIATE SERVERS
  BLEpedometer.init(_server, &pedometerCounter, true);

  _server->getAdvertising()->addServiceUUID(PHYSICALACTIVITYMONITOR_SERVICE_UUID);
  _server->getAdvertising()->start();
  Serial.println("Bluetooth init. Waiting for client...");

  calibrate();

  pedometerCounter = preferences.getUShort("counter", 0);

  Y_out = 0;
  Z_out = 0;

  y2z2_out = 0;
  y2z2_out_old = 0;

  refreshAlarm = Alarm.timerRepeat(10, refreshBLEvalues);
  Alarm.timerRepeat(3, changerandomvalues);
  Alarm.disable(refreshAlarm);
}

void printDigits(int digits)
{
  Serial.print(":");
  if (digits < 10)
    Serial.print('0');
  Serial.print(digits);
}
void systemup_time()
{
  Serial.print(hour());
  printDigits(minute());
  printDigits(second());
  Serial.println();
}
void loop()
{
  // === Read acceleromter data === //
  if (accel.update())
  {
    Y_out = accel.getRawY() - Y_OFFSET;
    Z_out = accel.getRawZ() - Z_OFFSET;

    y2z2_out_old = y2z2_out;
    y2z2_out = sqrt(pow(Y_out, 2) + pow(Z_out, 2));

    Serial.print("Y : ");
    Serial.println(Y_out);
    Serial.print("Z : ");
    Serial.println(Z_out);

    if (y2z2_out_old > y2z2_out && y2z2_out_old > 150)
    {
      Serial.print("x2z2 now : ");
      Serial.println(y2z2_out);
      Serial.print("x2z2 old : ");
      Serial.println(y2z2_out_old);

      pedometerCounter++;

      steadySamples = 0;
    }
    else
    {
      steadySamples++;
      Serial.println(steadySamples);
      if (steadySamples > 5 * 1 * 60)
      {
        preferences.putUShort("counter", pedometerCounter);
        _server->disconnect(connectID);
        deviceConnected = false;
        Serial.println("Disonnected device.");
        Alarm.disable(refreshAlarm);

        preferences.end();
        Serial.println("Putting to sleep");
        write_register(0x53, 0x27, 0b00000100);

        esp_deep_sleep_start();
      }
    }
  }
  else
  {
    Serial.println("update failed");

    Alarm.delay(50);
  }

  Alarm.delay(200);
}