#!/usr/bin/env python3
"""Install an emulator APK without clearing application data.
Temporarily reduce Android's free-space reserve during installation, then
restore its exact prior settings even when installation fails.
"""
import subprocess, sys

def adb(*args):
    return subprocess.run(['adb','-s','emulator-5554',*args],check=True,capture_output=True,text=True).stdout.strip()
settings=['sys_storage_threshold_percentage','sys_storage_threshold_max_bytes']
previous={key:adb('shell','settings','get','global',key) for key in settings}
try:
    adb('shell','settings','put','global',settings[0],'2')
    adb('shell','settings','put','global',settings[1],str(64*1024*1024))
    print(adb('install','-r',sys.argv[1]),flush=True)
finally:
    for key,value in previous.items():
        if value=='null':adb('shell','settings','delete','global',key)
        else:adb('shell','settings','put','global',key,value)
    print('Restored emulator storage reserve settings.',flush=True)
