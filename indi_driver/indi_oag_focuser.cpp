/**
 * indi_oag_focuser.cpp
 *
 * INDI focuser driver for the jlecomte OAG Focuser (v2 hardware / Celestron OAG
 * variant) running the oag_focuser_firmware.ino sketch.
 *
 * Build deps:
 *   libindi-dev, libindi1 (Ubuntu/Debian: sudo apt install libindi-dev)
 *
 * Build:
 *   mkdir build && cd build
 *   cmake .. && make
 *
 * Install:
 *   sudo make install
 *
 * Use with PHD2:
 *   Start indiserver: indiserver -v indi_oag_focuser
 *   In PHD2 Equipment Profile -> Aux Mount or Focuser -> INDI
 *   Select "OAG Focuser" and connect.
 */

#include "indi_oag_focuser.h"

#include <libindi/connectionplugins/connectionserial.h>
#include <memory>
#include <cstring>
#include <unistd.h>
#include <termios.h>
#include <chrono>
#include <thread>
#include <sstream>

// ── INDI boilerplate ──────────────────────────────────────────────────────────
static std::unique_ptr<OAGFocuser> oagFocuser(new OAGFocuser());

void ISGetProperties(const char *dev)                               { oagFocuser->ISGetProperties(dev); }
void ISNewSwitch(const char *dev, const char *name, ISState *s, char *n[], int num) { oagFocuser->ISNewSwitch(dev, name, s, n, num); }
void ISNewText(const char *dev, const char *name, char *t[], char *n[], int num)    { oagFocuser->ISNewText(dev, name, t, n, num); }
void ISNewNumber(const char *dev, const char *name, double *v, char *n[], int num)  { oagFocuser->ISNewNumber(dev, name, v, n, num); }
void ISNewBLOB(const char *dev, const char *name, int s, char *f[], char *b[], int l[], int n) {}
void ISSnoopDevice(XMLEle *root)                                    { oagFocuser->ISSnoopDevice(root); }

// ── Constructor ───────────────────────────────────────────────────────────────
OAGFocuser::OAGFocuser()
{
    setVersion(1, 0);
    FI::SetCapability(FOCUSER_CAN_ABS_MOVE |
                      FOCUSER_CAN_REL_MOVE |
                      FOCUSER_CAN_ABORT);
}

// ── Identification ─────────────────────────────────────────────────────────────
const char *OAGFocuser::getDefaultName()
{
    return "OAG Focuser";
}

// ── initProperties ────────────────────────────────────────────────────────────
bool OAGFocuser::initProperties()
{
    INDI::Focuser::initProperties();

    // Absolute position range (matches MAX_POSITION in firmware)
    FocusAbsPosN[0].min  = 0;
    FocusAbsPosN[0].max  = 32767;
    FocusAbsPosN[0].step = 100;
    FocusAbsPosN[0].value = 0;

    // Relative steps range
    FocusRelPosN[0].min  = 1;
    FocusRelPosN[0].max  = 5000;
    FocusRelPosN[0].step = 50;
    FocusRelPosN[0].value = 100;

    // ── Reverse direction switch ──────────────────────────────────────────────
    IUFillSwitch(&ReverseS[0], "REVERSE_DISABLE", "Normal",   ISS_ON);
    IUFillSwitch(&ReverseS[1], "REVERSE_ENABLE",  "Reversed", ISS_OFF);
    IUFillSwitchVector(&ReverseSP, ReverseS, 2, getDeviceName(),
                       "FOCUSER_REVERSE", "Direction",
                       MAIN_CONTROL_TAB, IP_RW, ISR_1OFMANY, 0, IPS_IDLE);

    // ── Set zero position button ──────────────────────────────────────────────
    IUFillSwitch(&SetZeroS[0], "SET_ZERO", "Set Zero", ISS_OFF);
    IUFillSwitchVector(&SetZeroSP, SetZeroS, 1, getDeviceName(),
                       "FOCUSER_SETZERO", "Calibration",
                       MAIN_CONTROL_TAB, IP_RW, ISR_ATMOST1, 0, IPS_IDLE);

    // Serial port default
    // ESP32-S3 USB CDC enumerates as /dev/ttyACM0, not /dev/ttyUSB0
    serialConnection->setDefaultPort("/dev/ttyACM0");
    serialConnection->setDefaultBaudRate(Connection::Serial::B_115200);

    addAuxControls();
    return true;
}

// ── updateProperties ──────────────────────────────────────────────────────────
bool OAGFocuser::updateProperties()
{
    INDI::Focuser::updateProperties();

    if (isConnected())
    {
        defineProperty(&ReverseSP);
        defineProperty(&SetZeroSP);

        // Read current state from device
        syncPosition();

        bool rev = false;
        std::string response;
        if (sendCommand("COMMAND:FOCUSER:GETREVERSE", response))
        {
            // REPLY:FOCUSER:REVERSE:0 or :1
            rev = response.find(":1") != std::string::npos;
        }
        ReverseS[0].s = rev ? ISS_OFF : ISS_ON;
        ReverseS[1].s = rev ? ISS_ON  : ISS_OFF;
        IDSetSwitch(&ReverseSP, nullptr);

        SetTimer(500);
    }
    else
    {
        deleteProperty(ReverseSP.name);
        deleteProperty(SetZeroSP.name);
    }

    return true;
}

// ── Handshake ─────────────────────────────────────────────────────────────────
bool OAGFocuser::Handshake()
{
    // Give the Arduino time to reset after DTR toggled on connect
    std::this_thread::sleep_for(std::chrono::milliseconds(2000));

    // Flush any boot messages
    tcflush(PortFD, TCIOFLUSH);

    std::string response;
    if (!sendCommand("COMMAND:FOCUSER:HANDSHAKE", response))
    {
        LOG_ERROR("No response to handshake — check port and firmware.");
        return false;
    }

    if (response.find("READY") == std::string::npos)
    {
        LOGF_ERROR("Unexpected handshake reply: %s", response.c_str());
        return false;
    }

    LOGF_INFO("OAG Focuser connected: %s", response.c_str());
    return true;
}

// ── sendCommand (with reply) ──────────────────────────────────────────────────
bool OAGFocuser::sendCommand(const std::string &cmd, std::string &response)
{
    // Send command with newline terminator
    std::string full = cmd + "\n";
    int written = write(PortFD, full.c_str(), full.size());
    if (written < 0)
    {
        LOGF_ERROR("Serial write failed for command: %s", cmd.c_str());
        return false;
    }

    // Read reply (up to 256 bytes, timeout ~2 s)
    char buf[256] = {0};
    int  total    = 0;
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(2000);

    while (std::chrono::steady_clock::now() < deadline)
    {
        int n = read(PortFD, buf + total, sizeof(buf) - total - 1);
        if (n > 0)
        {
            total += n;
            buf[total] = '\0';
            // Look for newline — reply is complete
            if (strchr(buf, '\n')) break;
        }
        else
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }

    if (total == 0)
    {
        LOGF_DEBUG("No reply to: %s", cmd.c_str());
        return false;
    }

    response = std::string(buf);
    // Trim CR/LF
    while (!response.empty() && (response.back() == '\r' || response.back() == '\n'))
        response.pop_back();

    LOGF_DEBUG("CMD: %s  REPLY: %s", cmd.c_str(), response.c_str());
    return true;
}

// ── sendCommand (fire-and-forget) ─────────────────────────────────────────────
bool OAGFocuser::sendCommand(const std::string &cmd)
{
    std::string dummy;
    return sendCommand(cmd, dummy);
}

// ── syncPosition ──────────────────────────────────────────────────────────────
bool OAGFocuser::syncPosition()
{
    std::string response;
    if (!sendCommand("COMMAND:FOCUSER:GETPOSITION", response))
        return false;

    // REPLY:FOCUSER:POSITION:12345
    auto colon = response.rfind(':');
    if (colon == std::string::npos) return false;

    long pos = std::stol(response.substr(colon + 1));
    FocusAbsPosN[0].value = pos;
    IDSetNumber(&FocusAbsPosNP, nullptr);
    return true;
}

// ── queryMoving ───────────────────────────────────────────────────────────────
bool OAGFocuser::queryMoving(bool &moving)
{
    std::string response;
    if (!sendCommand("COMMAND:FOCUSER:ISMOVING", response))
        return false;

    // REPLY:FOCUSER:ISMOVING:0 or :1
    moving = response.find(":1") != std::string::npos;
    return true;
}

// ── MoveAbsFocuser ────────────────────────────────────────────────────────────
IPState OAGFocuser::MoveAbsFocuser(uint32_t targetTicks)
{
    std::string cmd = "COMMAND:FOCUSER:MOVE:" + std::to_string(targetTicks);
    std::string response;

    if (!sendCommand(cmd, response) || response.find("OK") == std::string::npos)
    {
        LOGF_ERROR("Move command failed: %s", response.c_str());
        return IPS_ALERT;
    }

    m_target = targetTicks;
    m_moving = true;
    return IPS_BUSY;
}

// ── MoveRelFocuser ────────────────────────────────────────────────────────────
IPState OAGFocuser::MoveRelFocuser(FocusDirection dir, uint32_t ticks)
{
    long current = static_cast<long>(FocusAbsPosN[0].value);
    long target  = (dir == FOCUS_INWARD)
                   ? current - static_cast<long>(ticks)
                   : current + static_cast<long>(ticks);

    target = std::max(0L, std::min(static_cast<long>(32767), target));
    return MoveAbsFocuser(static_cast<uint32_t>(target));
}

// ── AbortFocuser ──────────────────────────────────────────────────────────────
bool OAGFocuser::AbortFocuser()
{
    m_moving = false;
    return sendCommand("COMMAND:FOCUSER:HALT");
}

// ── TimerHit — poll for motion completion ────────────────────────────────────
void OAGFocuser::TimerHit()
{
    if (!isConnected()) return;

    if (m_moving)
    {
        bool moving = true;
        queryMoving(moving);

        if (!moving)
        {
            m_moving = false;
            syncPosition();
            FocusAbsPosNP.s = IPS_OK;
            IDSetNumber(&FocusAbsPosNP, nullptr);
        }
    }
    else
    {
        // Gentle position poll every timer cycle
        syncPosition();
    }

    SetTimer(500);
}

// ── ISNewSwitch ───────────────────────────────────────────────────────────────
bool OAGFocuser::ISNewSwitch(const char *dev, const char *name,
                              ISState *states, char *names[], int n)
{
    if (dev && strcmp(dev, getDeviceName()) != 0)
        return false;

    // Reverse direction
    if (!strcmp(name, ReverseSP.name))
    {
        IUUpdateSwitch(&ReverseSP, states, names, n);
        bool rev = (ReverseS[1].s == ISS_ON);
        std::string cmd = std::string("COMMAND:FOCUSER:SETREVERSE:") + (rev ? "1" : "0");
        std::string response;
        if (sendCommand(cmd, response) && response.find("OK") != std::string::npos)
        {
            ReverseSP.s = IPS_OK;
            LOGF_INFO("Reverse direction: %s", rev ? "enabled" : "disabled");
        }
        else
        {
            ReverseSP.s = IPS_ALERT;
        }
        IDSetSwitch(&ReverseSP, nullptr);
        return true;
    }

    // Set zero
    if (!strcmp(name, SetZeroSP.name))
    {
        IUUpdateSwitch(&SetZeroSP, states, names, n);
        std::string response;
        if (sendCommand("COMMAND:FOCUSER:SETZERO", response) &&
            response.find("OK") != std::string::npos)
        {
            FocusAbsPosN[0].value = 0;
            IDSetNumber(&FocusAbsPosNP, nullptr);
            SetZeroSP.s = IPS_OK;
            LOG_INFO("Zero position set.");
        }
        else
        {
            SetZeroSP.s = IPS_ALERT;
        }
        SetZeroS[0].s = ISS_OFF;
        IDSetSwitch(&SetZeroSP, nullptr);
        return true;
    }

    return INDI::Focuser::ISNewSwitch(dev, name, states, names, n);
}

// ── ISNewNumber ───────────────────────────────────────────────────────────────
bool OAGFocuser::ISNewNumber(const char *dev, const char *name,
                              double *values, char *names[], int n)
{
    return INDI::Focuser::ISNewNumber(dev, name, values, names, n);
}
