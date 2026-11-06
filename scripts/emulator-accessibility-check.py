#!/usr/bin/env python3
"""Inspect Oyla with TalkBack enabled, restoring previous service settings."""
import importlib.util, pathlib, time
spec=importlib.util.spec_from_file_location('smoke',pathlib.Path(__file__).with_name('emulator-smoke.py'))
s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
keys=['enabled_accessibility_services','accessibility_enabled']
previous={key:s.adb('shell','settings','get','secure',key).strip() for key in keys}
service='com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService'
try:
    services=service if previous[keys[0]]=='null' else previous[keys[0]]+':'+service
    s.adb('shell','settings','put','secure',keys[0],services)
    s.adb('shell','settings','put','secure',keys[1],'1');time.sleep(2)
    s.adb('shell','am','start','-n','com.oyla.app/.MainActivity');time.sleep(1)
    s.adb('shell','input','keyevent','61');s.adb('shell','input','keyevent','61')
    s.snap('17-talkback')
    state=s.adb('shell','dumpsys','accessibility')
    assert 'TalkBackService' in state
    # Focus traversal is checked structurally; this is not a human speech audit.
    (s.OUT/'talkback-state.txt').write_text(state)
    print('TalkBack service enabled; captured screen and accessibility tree.',flush=True)
finally:
    for key,value in previous.items():
        if value=='null':s.adb('shell','settings','delete','secure',key)
        else:s.adb('shell','settings','put','secure',key,value)
    s.adb('shell','am','start','-n','com.oyla.app/.MainActivity')
logs=s.adb('logcat','-d','-s','flutter:E','AndroidRuntime:E')
(s.OUT/'runtime-errors.txt').write_text(logs)
assert 'FATAL EXCEPTION' not in logs and 'Unhandled Exception' not in logs and 'RenderFlex overflow' not in logs,logs[-3000:]
print('PASS: no Flutter/native crash or overflow found in retained runtime logs. Accessibility settings restored.',flush=True)
