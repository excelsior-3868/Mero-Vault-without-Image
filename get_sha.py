import subprocess
import os

keystore = os.path.expanduser("~/.android/debug.keystore")
cmd = f'keytool -list -v -keystore "{keystore}" -alias androiddebugkey -storepass android -keypass android'
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
for line in result.stdout.splitlines():
    if "SHA1" in line:
        print(line.strip())
