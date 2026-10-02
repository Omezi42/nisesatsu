class_name GameEnums
extends RefCounted

# .tres は enum を整数で保存する。新しい値は必ず末尾へ足す(docs/Pitfalls.md)
enum Feature { PATTERN, COLOR, SERIAL, WATERMARK, MICROTEXT, UV_INK }
enum Tool { NAKED_EYE, LOUPE, BACKLIGHT, UV }
enum ViewMode { NORMAL, BACKLIGHT, UV }
enum Verdict { ACCEPT, REJECT }
