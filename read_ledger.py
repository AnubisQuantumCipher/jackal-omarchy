#!/usr/bin/python3 -B
"""Read a bounded regular ledger before any bytes reach the QML collector.

Oversized or unreadable ledgers produce no output and a failure exit status.
No partial history is presented as a complete ledger.
"""
import os
import stat
import sys

MAX_LEDGER_BYTES = 8 * 1024 * 1024


def read_ledger(path):
    fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_LEDGER_BYTES:
            raise ValueError("ledger is not a bounded regular file")
        with os.fdopen(fd, "rb", closefd=False) as stream:
            data = stream.read(MAX_LEDGER_BYTES + 1)
        if len(data) > MAX_LEDGER_BYTES:
            raise ValueError("ledger grew beyond the byte limit")
        data.decode("utf-8", errors="strict")
        return data
    finally:
        os.close(fd)


def main():
    try:
        if len(sys.argv) != 2:
            return 1
        data = read_ledger(sys.argv[1])
    except (OSError, ValueError):
        return 1
    sys.stdout.buffer.write(data)
    return 0


if __name__ == "__main__":
    sys.exit(main())
