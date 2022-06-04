#include <Arduino.h>

#include <Time.h>
#include <TimeAlarms.h>

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#include <valuetimelapse.h>
#include <def_bleuuid.h>

#define ONBOARD_LED_PIN 2

#include <BLEpedometer.h>

#include <Wire.h> // Wire library - used for I2C communication

#include <ADXL345.h>

ADXL345 accel(ADXL345_ALT);
float X_out, Y_out, Z_out; // Outputs

TaskHandle_t handle_pedometerTask;

bool deviceConnected = false;
memUint16_t pedometerCounter = 0;

// battery, something counter, on/off led, serial communicate.

class BLECallbacks : public BLEServerCallbacks
{

  void onConnect(BLEServer *server)
  {
    deviceConnected = true;
    Serial.print("Connected to ");
    Serial.print(server->getConnectedCount());
    Serial.println("devices.");
  }

  void onDisconnect(BLEServer *server)
  {
    deviceConnected = false;
    Serial.println("Disonnected device.");
    server->getAdvertising()->addServiceUUID(PHYSICALACTIVITYMONITOR_SERVICE_UUID);
    server->getAdvertising()->start();
    Serial.println("Started advertising again...");
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
  Serial.println("RUNNING REFRESH.");
  if (!deviceConnected)
    return;

  BLEpedometer.refresh();
}

void changerandomvalues()
{
  pedometerCounter = (uint16_t)(random(65533));
}

void setup()
{
  Serial.begin(115250);
  BLEDevice::init("BlueTest");
  pinMode(ONBOARD_LED_PIN, OUTPUT); // Declare the LED as an output

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
  // - ...
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

  setTime(0, 0, 0, 0, 0, 0);

  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new BLECallbacks());

  // INITIATE SERVERS
  BLEpedometer.init(server, &pedometerCounter, true);

  server->getAdvertising()->addServiceUUID(PHYSICALACTIVITYMONITOR_SERVICE_UUID);
  server->getAdvertising()->start();
  Serial.println("Bluetooth init. Waiting for client...");

  Alarm.timerRepeat(5, refreshBLEvalues);
  Alarm.timerRepeat(3, changerandomvalues);
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
  // if (led_read.startsWith(":") && led_read.endsWith(":"))
  // {
  //   if (led_read.equals(":LED!1:"))
  //     digitalWrite(ONBOARD_LED_PIN, HIGH);
  //   if (led_read.equals(":LED!0:"))
  //     digitalWrite(ONBOARD_LED_PIN, LOW);
  // }

  // === Read acceleromter data === //
  if (accel.update())
  {
    Serial.print(accel.getX());
    Serial.print(",");
    Serial.print(accel.getY());
    Serial.print(",");
    Serial.print(accel.getZ());
    Serial.println("");
  }
  else
  {
    Serial.println("update failed");
    while (1)
    {
      Alarm.delay(50);
    }
  }
  Alarm.delay(200);
}
