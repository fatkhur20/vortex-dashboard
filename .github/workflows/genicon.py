import struct, zlib
w=1024;h=1024;r=10;g=15;b=30
def c(t,d):
    return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
row=b'\x00'+bytes([r,g,b])*w
open('fresh/assets/icon.png','wb').write(b'\x89PNG\r\n\x1a\n'+c(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+c(b'IDAT',zlib.compress(row*h))+c(b'IEND',b''))
