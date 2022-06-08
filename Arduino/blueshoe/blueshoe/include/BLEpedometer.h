class BLEpedometerController
{
private:
    bool _notify = false;
    uint16_t _value = 0;

public:
    uint16_t *pedoCounter;
    // BLE PEDOMETER CHARACTERISTIC
    BLECharacteristic BLEpedometerCharacteristic = BLECharacteristic(STEPCOUNTER_CAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);

    void init(BLEServer *server, uint16_t *_value, bool notify = false)
    {
        try
        {
            // pedometer server
            // 1. CREATE SERVICE
            BLEService *BLEpedometerService = server->createService(PHYSICALACTIVITYMONITOR_SERVICE_UUID);
            // 2. CREATE CHARACTERISTIC
            BLEpedometerService->addCharacteristic(&BLEpedometerCharacteristic);

            if (notify)
            {
                BLEpedometerCharacteristic.addDescriptor(new BLE2902());
                _notify = true;
            }

            pedoCounter = _value;

            BLEpedometerService->start();
            sendValue(0);
        }
        catch (const std::exception &e)
        {
            Serial.println(e.what());
        }
    }

    void sendValue(uint16_t value)
    {
        _value = value;
        Serial.print("REAL PEDO VALUE -> ");
        Serial.println(_value, HEX);

        swap(_value);

        BLEpedometerCharacteristic.setValue(_value);
        BLEpedometerCharacteristic.notify();
    }

    void refresh(uint16_t value)
    {
        sendValue(value);
        return;
    }
};
