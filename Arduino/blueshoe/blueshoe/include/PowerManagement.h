#include <Arduino.h>
#include <BLEDevice.h>
#include <Time.h>
#include <TimeAlarms.h>

class PowerManagement
{
public:
    int16_t *X;
    int16_t *Z;

    PowerManagement(int16_t *xout, int16_t *zout, uint8_t steady_th)
    {
        X = xout;
        Z = zout;
        steady_threshold = steady_th;
    }
};
