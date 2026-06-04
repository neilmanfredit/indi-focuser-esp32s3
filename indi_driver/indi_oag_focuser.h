#pragma once

/**
 * indi_oag_focuser.h
 *
 * INDI driver for the jlecomte OAG Focuser (v2 hardware).
 * Communicates over USB serial at 115200 baud.
 * Works with PHD2, KStars/Ekos, and any INDI-compatible client on Linux.
 *
 * Hardware: Arduino Nano ESP32 (ESP32-S3R8 / NORA-W106-10B)
 *   The ESP32-S3 appears as a USB CDC serial device on Linux — no CH340/FTDI
 *   driver needed. It enumerates as /dev/ttyACM0 (not /dev/ttyUSB0).
 *   Update the default port below or use the udev rule to create a symlink.
 */

#include <libindi/indifocuser.h>
#include <string>

class OAGFocuser : public INDI::Focuser
{
public:
    OAGFocuser();
    virtual ~OAGFocuser() = default;

    // ── INDI lifecycle ───────────────────────────────────────────────────────
    bool initProperties() override;
    bool updateProperties() override;
    const char *getDefaultName() override;

    // ── Connection ───────────────────────────────────────────────────────────
    bool Handshake() override;

    // ── Focuser interface ────────────────────────────────────────────────────
    IPState MoveAbsFocuser(uint32_t targetTicks) override;
    IPState MoveRelFocuser(FocusDirection dir, uint32_t ticks) override;
    bool AbortFocuser() override;
    void TimerHit() override;

    // ── Properties ──────────────────────────────────────────────────────────
    bool ISNewSwitch(const char *dev, const char *name,
                     ISState *states, char *names[], int n) override;
    bool ISNewNumber(const char *dev, const char *name,
                     double *values, char *names[], int n) override;

private:
    // ── Serial helpers ───────────────────────────────────────────────────────
    bool sendCommand(const std::string &cmd, std::string &response);
    bool sendCommand(const std::string &cmd);  // fire-and-forget variant

    // ── Hardware queries ─────────────────────────────────────────────────────
    bool syncPosition();
    bool queryMoving(bool &moving);

    // ── Custom properties ────────────────────────────────────────────────────
    ISwitch  ReverseS[2];
    ISwitchVectorProperty ReverseSP;

    ISwitch  SetZeroS[1];
    ISwitchVectorProperty SetZeroSP;

    // ── Internal state ───────────────────────────────────────────────────────
    bool     m_moving     { false };
    uint32_t m_target     { 0 };
};
