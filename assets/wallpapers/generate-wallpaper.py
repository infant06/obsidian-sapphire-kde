#!/usr/bin/env python3
"""Generates a 2560x1440 Obsidian & Sapphire Silk Wave Wallpaper."""
import os
import sys
from PyQt6.QtCore import QPointF
from PyQt6.QtGui import (
    QColor,
    QGuiApplication,
    QImage,
    QLinearGradient,
    QPainter,
    QPainterPath,
    QRadialGradient,
)


def main():
    out_path = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.path.expanduser("~/.local/share/wallpapers/Obsidian-Sapphire.png")
    )
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    app = QGuiApplication(sys.argv)
    w, h = 2560, 1440
    img = QImage(w, h, QImage.Format.Format_RGB32)
    p = QPainter(img)
    p.setRenderHint(QPainter.RenderHint.Antialiasing, True)

    bg = QLinearGradient(0, 0, w, h)
    bg.setColorAt(0.0, QColor(9, 11, 18))
    bg.setColorAt(0.5, QColor(14, 19, 32))
    bg.setColorAt(1.0, QColor(10, 13, 22))
    p.fillRect(0, 0, w, h, bg)

    g1 = QRadialGradient(QPointF(w * 0.72, h * 0.28), w * 0.48)
    g1.setColorAt(0.0, QColor(37, 99, 235, 75))
    g1.setColorAt(0.5, QColor(30, 58, 138, 32))
    g1.setColorAt(1.0, QColor(10, 13, 22, 0))
    p.fillRect(0, 0, w, h, g1)

    g2 = QRadialGradient(QPointF(w * 0.26, h * 0.74), w * 0.45)
    g2.setColorAt(0.0, QColor(79, 70, 229, 65))
    g2.setColorAt(0.5, QColor(49, 46, 129, 28))
    g2.setColorAt(1.0, QColor(10, 13, 22, 0))
    p.fillRect(0, 0, w, h, g2)

    wave1 = QPainterPath()
    wave1.moveTo(0, h * 0.65)
    wave1.cubicTo(w * 0.28, h * 0.45, w * 0.62, h * 0.82, w, h * 0.52)
    wave1.lineTo(w, h)
    wave1.lineTo(0, h)
    wave1.closeSubpath()
    wg1 = QLinearGradient(0, h * 0.45, w, h)
    wg1.setColorAt(0.0, QColor(59, 130, 246, 38))
    wg1.setColorAt(0.5, QColor(37, 99, 235, 22))
    wg1.setColorAt(1.0, QColor(15, 23, 42, 60))
    p.fillPath(wave1, wg1)

    wave2 = QPainterPath()
    wave2.moveTo(0, h * 0.78)
    wave2.cubicTo(w * 0.35, h * 0.92, w * 0.68, h * 0.58, w, h * 0.72)
    wave2.lineTo(w, h)
    wave2.lineTo(0, h)
    wave2.closeSubpath()
    wg2 = QLinearGradient(0, h * 0.6, w, h)
    wg2.setColorAt(0.0, QColor(99, 102, 241, 32))
    wg2.setColorAt(1.0, QColor(15, 17, 26, 85))
    p.fillPath(wave2, wg2)

    p.end()
    img.save(out_path)


if __name__ == "__main__":
    main()
