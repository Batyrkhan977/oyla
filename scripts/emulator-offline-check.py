#!/usr/bin/env python3
"""Check offline operation, postpone/skip, restart persistence, and large text.
Network and font settings are restored in finally blocks.
"""
import importlib.util, pathlib, time
spec=importlib.util.spec_from_file_location('smoke',pathlib.Path(__file__).with_name('emulator-smoke.py'))
s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
s.home();s.tap('My routines');s.tap('My routine');s.tap('Save',scroll=False);s.tap('Save my day')
s.tap('Postpone');s.tap('OK',scroll=False);s.expect('Postponed');s.snap('11-postponed')
s.tap('Skip');s.expect('Skipped');s.snap('12-skipped')
wifi=s.adb('shell','settings','get','global','wifi_on').strip()
data=s.adb('shell','settings','get','global','mobile_data').strip()
scale=s.adb('shell','settings','get','system','font_scale').strip()
try:
    s.adb('shell','svc','wifi','disable');s.adb('shell','svc','data','disable')
    s.tap('Library');s.tap('A map for a visitor',partial=True);s.expect('Timur');s.snap('13-offline-reading');s.home()
    s.adb('shell','am force-stop com.oyla.app; am start -n com.oyla.app/.MainActivity')
    time.sleep(2);s.expect('My Day');s.expect('Completed');s.snap('14-restart-offline')
    s.adb('shell','settings','put','system','font_scale','2.0');time.sleep(1)
    s.snap('15-large-text');s.expect('My Day')
finally:
    s.adb('shell','svc','wifi','enable' if wifi=='1' else 'disable')
    s.adb('shell','svc','data','enable' if data=='1' else 'disable')
    if scale=='null':s.adb('shell','settings','delete','system','font_scale')
    else:s.adb('shell','settings','put','system','font_scale',scale)
s.home();s.snap('16-restored-my-day')
print('PASS: postpone, skip, new reading offline, restart persistence, 200% font scale. Network/font settings restored.',flush=True)
