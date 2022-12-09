"""
Continuously read images from webcam and write them to a memory-mapped file.
"""
import mmap
import sys

mm = None
try:
    while True:
        i = input(">>>")
        if mm is None:
            mm = mmap.mmap(-1, 1000, "mario-0_in")

        mm.seek(0)
        mm.write(bytes(i, 'utf-8'))
        mm.flush()
except KeyboardInterrupt:
    pass

print("Closing resources")
mm.close()