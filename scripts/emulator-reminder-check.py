#!/usr/bin/env python3
"""Exercise a real scheduled reminder and its Skip action on the emulator."""
import datetime, importlib.util, json, pathlib, re, time, xml.etree.ElementTree as ET
spec=importlib.util.spec_from_file_location('smoke',pathlib.Path(__file__).with_name('emulator-smoke.py'))
s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
def pref(name):
    root=ET.fromstring(s.adb('exec-out','run-as','com.oyla.app','cat','shared_prefs/FlutterSharedPreferences.xml'))
    item=next((n for n in root if n.get('name')=='flutter.'+name),None)
    return json.loads(item.text) if item is not None else {}
def enter(node,value):
    x1,y1,x2,y2=map(int,re.findall(r'\d+',node.get('bounds')))
    s.adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
    s.adb('shell','input','keyevent','123','67','67','67','67','67','67','67','67','67','67','67','67')
    s.adb('shell','input','text',str(value))
original=pref('settings.v1').get('remindersEnabled',False)
try:
    s.home();s.tap('Settings')
    if not original:
        s.tap('reminders',partial=True);time.sleep(.5)
        if 'Allow' in s.labels():s.tap('Allow',scroll=False)
    s.back();s.tap('My routines');s.tap('My routine')
    fields=[n for n in s.tree().iter('node') if n.get('class')=='android.widget.EditText']
    enter(fields[0],'Reminder-check')
    s.tap('Time: 09:00',scroll=False)
    s.tap('Switch to text input mode',scroll=False)
    target=datetime.datetime.strptime(s.adb('shell','date','+%Y-%m-%dT%H:%M:%S').strip(),'%Y-%m-%dT%H:%M:%S')+datetime.timedelta(minutes=2)
    labels=s.labels();twelve='PM' in labels or 'AM' in labels
    fields=[n for n in s.tree().iter('node') if n.get('class')=='android.widget.EditText']
    enter(fields[0],target.hour%12 or 12 if twelve else target.hour)
    enter(fields[1],target.minute)
    if twelve:s.tap('PM' if target.hour>=12 else 'AM',scroll=False)
    s.tap('OK',scroll=False)
    s.tap('Remind at this time',partial=True,scroll=False)
    s.tap('Save',scroll=False);s.tap('Save my day')
    print('Scheduled Reminder-check for',target.strftime('%H:%M'),flush=True)
    deadline=time.time()+180
    while time.time()<deadline:
        notifications=s.adb('shell','dumpsys','notification')
        if re.search(r'NotificationRecord.*pkg=com\.oyla\.app',notifications):break
        time.sleep(8)
    else:raise AssertionError('No Oyla notification delivered within the observation window')
    s.adb('shell','cmd','statusbar','expand-notifications');time.sleep(1)
    s.snap('18-reminder-delivered');s.tap('Skip',scroll=False)
    s.adb('shell','cmd','statusbar','collapse');s.adb('shell','am','start','-n','com.oyla.app/.MainActivity');time.sleep(1)
    s.home();s.snap('19-reminder-skipped')
    assert any('Reminder-check' in label and 'Skipped' in label for label in s.labels()),s.labels()
    print('PASS: native reminder delivered and Skip updated My Day.',flush=True)
finally:
    s.adb('shell','cmd','statusbar','collapse');s.adb('shell','am','start','-n','com.oyla.app/.MainActivity')
    s.home()
    if not original and pref('settings.v1').get('remindersEnabled',False):
        s.tap('Settings');s.tap('reminders',partial=True);s.back()
    print('Restored the original app reminder preference.',flush=True)
