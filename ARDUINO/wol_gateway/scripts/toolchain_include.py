"""Corrige le chemin des en-têtes C++ avec un Core PlatformIO isolé."""

from glob import glob
from os.path import join

Import("env")

toolchain_dir = env.PioPlatform().get_package_dir("toolchain-xtensa-esp32")
target_includes = glob(
    join(toolchain_dir, "xtensa-esp32-elf", "include", "c++", "*", "xtensa-esp32-elf")
)
if len(target_includes) != 1:
    raise RuntimeError("En-têtes C++ ESP32 introuvables ou ambigus")

env.Append(CPPPATH=target_includes)
