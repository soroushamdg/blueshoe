#include <Arduino.h>

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

int16_t X_OFFSET;
int16_t Y_OFFSET;
int16_t Z_OFFSET;

TaskHandle_t handle_pedometerTask;

bool deviceConnected = false;

uint16_t pedometerCounter = 0;

AlarmID_t refreshAlarm;

ADXL345 accel(ADXL345_ALT);

int16_t X_out, Z_out; // Outputs

uint16_t x2z2_out;
uint16_t x2z2_out_old;

// battery, something counter, on/off led, serial communicate.

class BLECallbacks : public BLEServerCallbacks
{

  void onConnect(BLEServer *server)
  {
    deviceConnected = true;
    Serial.print("Connected to ");
    Serial.print(server->getConnectedCount());
    Serial.println("devices.");
    Alarm.delay(1000);
    Alarm.enable(refreshAlarm);
  }

  void onDisconnect(BLEServer *server)
  {
    deviceConnected = false;
    Serial.println("Disonnected device.");
    Alarm.disable(refreshAlarm);

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
  try
  {
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
  Serial.println(pedometerCounter);
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

void setup()
{
  Serial.begin(115250);

  Serial.println(esp_reset_reason());

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

  setTime(0, 0, 0, 0, 0, 0);

  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new BLECallbacks());

  // INITIATE SERVERS
  BLEpedometer.init(server, &pedometerCounter, true);

  server->getAdvertising()->addServiceUUID(PHYSICALACTIVITYMONITOR_SERVICE_UUID);
  server->getAdvertising()->start();
  Serial.println("Bluetooth init. Waiting for client...");

  calibrate();

  pedometerCounter = 0;

  X_out = 0;
  Z_out = 0;

  x2z2_out = 0;
  x2z2_out_old = 0;

  refreshAlarm = Alarm.timerRepeat(5, refreshBLEvalues);
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
    X_out = accel.getRawX() - X_OFFSET;
    Z_out = accel.getRawZ() - Z_OFFSET;

    x2z2_out_old = x2z2_out;
    x2z2_out = sqrt(pow(X_out, 2) + pow(Z_out, 2));

    Serial.print("X : ");
    Serial.println(X_out);
    Serial.print("Z : ");
    Serial.println(Z_out);

    if (x2z2_out_old > x2z2_out && x2z2_out_old > 150)
    {
      Serial.print("x2z2 now : ");
      Serial.println(x2z2_out);
      Serial.print("x2z2 old : ");
      Serial.println(x2z2_out_old);

      pedometerCounter++;
    }
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
//  pedometerCounter = accel.getX() * 100 + accel.getY() * 100 + accel.getZ() * 100;
//     Serial.println("_______________ UPDATED _______________");