#!/usr/bin/env python3
"""用标准库生成一张测试用 PNG（iOS 相册可识别）。

生成 800x600 的彩色渐变图，输出到与本脚本同目录的 test_meal.png。
"""
import os
import struct
import zlib

WIDTH, HEIGHT = 800, 600


def _chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def main():
    raw_rows = []
    for y in range(HEIGHT):
        row = bytearray(b"\x00")  # 每行开头的 filter 字节
        for x in range(WIDTH):
            r = int(255 * x / WIDTH)
            g = int(255 * y / HEIGHT)
            b = 180
            row += bytes((r, g, b))
        raw_rows.append(bytes(row))
    raw = b"".join(raw_rows)

    png = b"\x89PNG\r\n\x1a\n"
    png += _chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0))
    png += _chunk(b"IDAT", zlib.compress(raw, 6))
    png += _chunk(b"IEND", b"")

    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_meal.png")
    with open(out, "wb") as f:
        f.write(png)
    print(f"written: {out} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
