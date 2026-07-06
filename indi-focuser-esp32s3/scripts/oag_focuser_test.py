#!/usr/bin/env python3
"""
oag_focuser_test.py
-------------------
Standalone serial tester for the OAG focuser firmware.
Lets you talk to the Arduino directly without INDI — useful for initial
calibration, verifying the firmware, and measuring backlash.

Usage:
    python3 oag_focuser_test.py --port /dev/ttyUSB0

Alternatively, run with --interactive for a simple command prompt.

Requires: pyserial  (pip install pyserial)
"""

import argparse
import sys
import time
import serial

BAUD      = 115200
TIMEOUT   = 2.0   # seconds


def open_port(port: str) -> serial.Serial:
    s = serial.Serial(
        port=port,
        baudrate=BAUD,
        timeout=TIMEOUT,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
    )
    # Arduino resets when DTR is toggled; wait for it to boot
    time.sleep(2.0)
    s.reset_input_buffer()
    return s


def send(ser: serial.Serial, cmd: str) -> str:
    """Send a command and return the stripped reply."""
    full = cmd.strip() + "\n"
    ser.write(full.encode())
    reply = ser.readline().decode(errors="replace").strip()
    return reply


def handshake(ser: serial.Serial) -> bool:
    reply = send(ser, "COMMAND:FOCUSER:HANDSHAKE")
    return "READY" in reply


def get_position(ser: serial.Serial) -> int:
    reply = send(ser, "COMMAND:FOCUSER:GETPOSITION")
    # REPLY:FOCUSER:POSITION:12345
    try:
        return int(reply.split(":")[-1])
    except ValueError:
        return -1


def is_moving(ser: serial.Serial) -> bool:
    reply = send(ser, "COMMAND:FOCUSER:ISMOVING")
    return ":1" in reply


def move_to(ser: serial.Serial, position: int) -> bool:
    reply = send(ser, f"COMMAND:FOCUSER:MOVE:{position}")
    return "OK" in reply


def halt(ser: serial.Serial) -> bool:
    reply = send(ser, "COMMAND:FOCUSER:HALT")
    return "OK" in reply


def set_zero(ser: serial.Serial) -> bool:
    reply = send(ser, "COMMAND:FOCUSER:SETZERO")
    return "OK" in reply


def set_reverse(ser: serial.Serial, enabled: bool) -> bool:
    reply = send(ser, f"COMMAND:FOCUSER:SETREVERSE:{'1' if enabled else '0'}")
    return "OK" in reply


def wait_for_stop(ser: serial.Serial, poll_interval: float = 0.25):
    """Block until the focuser reports it has stopped moving."""
    while is_moving(ser):
        pos = get_position(ser)
        print(f"  Moving... position = {pos}", end="\r", flush=True)
        time.sleep(poll_interval)
    print()


def run_self_test(ser: serial.Serial):
    """Basic self-test: handshake, read position, small move, halt."""
    print("── Self-test ────────────────────────────────────────")

    if not handshake(ser):
        print("FAIL: Handshake — check firmware and port.")
        return

    print("PASS: Handshake")

    pos = get_position(ser)
    print(f"INFO: Current position = {pos}")

    target = pos + 200
    print(f"INFO: Moving to {target} ...")
    if not move_to(ser, target):
        print("FAIL: Move command rejected.")
        return

    wait_for_stop(ser)
    new_pos = get_position(ser)
    print(f"INFO: Position after move = {new_pos}")

    if abs(new_pos - target) <= 2:
        print("PASS: Move accuracy OK")
    else:
        print(f"WARN: Expected ~{target}, got {new_pos}")

    print("INFO: Returning to original position ...")
    move_to(ser, pos)
    wait_for_stop(ser)
    print(f"INFO: Final position = {get_position(ser)}")
    print("── Self-test complete ───────────────────────────────")


def interactive(ser: serial.Serial):
    """Simple REPL for manual testing."""
    print("OAG Focuser interactive mode. Type 'help' for commands, 'quit' to exit.")
    commands = {
        "pos":      lambda _: print(f"Position: {get_position(ser)}"),
        "moving":   lambda _: print(f"Moving: {is_moving(ser)}"),
        "halt":     lambda _: print("OK" if halt(ser) else "FAIL"),
        "zero":     lambda _: print("OK" if set_zero(ser) else "FAIL"),
        "rev on":   lambda _: print("OK" if set_reverse(ser, True) else "FAIL"),
        "rev off":  lambda _: print("OK" if set_reverse(ser, False) else "FAIL"),
        "test":     lambda _: run_self_test(ser),
        "help": lambda _: print(
            "Commands: pos | moving | halt | zero | rev on | rev off | "
            "move <n> | raw <CMD> | test | quit"
        ),
    }

    while True:
        try:
            line = input("focuser> ").strip()
        except (EOFError, KeyboardInterrupt):
            break

        if line in ("quit", "exit", "q"):
            break
        elif line.startswith("move "):
            try:
                n = int(line.split()[1])
                print("OK" if move_to(ser, n) else "FAIL")
                wait_for_stop(ser)
                print(f"Position: {get_position(ser)}")
            except (IndexError, ValueError):
                print("Usage: move <position>")
        elif line.startswith("raw "):
            cmd = line[4:]
            print(send(ser, cmd))
        elif line in commands:
            commands[line](None)
        else:
            print("Unknown command. Type 'help'.")


def main():
    parser = argparse.ArgumentParser(description="OAG Focuser serial tester")
    parser.add_argument("--port", default="/dev/ttyUSB0",
                        help="Serial port (default: /dev/ttyUSB0)")
    parser.add_argument("--test", action="store_true",
                        help="Run automated self-test and exit")
    parser.add_argument("--interactive", "-i", action="store_true",
                        help="Enter interactive prompt")
    args = parser.parse_args()

    print(f"Opening {args.port} at {BAUD} baud ...")
    try:
        ser = open_port(args.port)
    except serial.SerialException as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.test:
        run_self_test(ser)
    elif args.interactive:
        interactive(ser)
    else:
        # Default: print status
        if handshake(ser):
            pos     = get_position(ser)
            moving  = is_moving(ser)
            rev_raw = send(ser, "COMMAND:FOCUSER:GETREVERSE")
            rev     = ":1" in rev_raw
            print(f"Position : {pos}")
            print(f"Moving   : {moving}")
            print(f"Reversed : {rev}")
        else:
            print("Handshake failed.", file=sys.stderr)
            sys.exit(1)

    ser.close()


if __name__ == "__main__":
    main()
