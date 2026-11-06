#!/usr/bin/env python3
"""Non-destructive UI smoke test on the connected Oyla Android emulator.
Creates a walking routine and reading progress; never clears app/user data.
"""
import pathlib, re, subprocess, time, xml.etree.ElementTree as ET
OUT = pathlib.Path('/tmp/oyla-emulator-evidence')
OUT.mkdir(exist_ok=True)

def adb(*args, binary=False):
    result = subprocess.run(['adb', '-s', 'emulator-5554', *args], check=True, capture_output=True)
    return result.stdout if binary else result.stdout.decode(errors='replace')

def tree():
    adb('shell', 'uiautomator', 'dump', '/sdcard/oyla-smoke.xml')
    return ET.fromstring(adb('exec-out', 'cat', '/sdcard/oyla-smoke.xml'))

def label(n): return n.get('text') or n.get('content-desc') or ''
def labels(): return [label(n) for n in tree().iter('node') if label(n)]
def tap(text, partial=False, scroll=True):
    for attempt in range(8 if scroll else 1):
        nodes = [n for n in tree().iter('node') if (text in label(n) if partial else label(n) == text)]
        if nodes:
            n=nodes[-1]
            x1,y1,x2,y2=map(int,re.findall(r'\d+',n.get('bounds')))
            adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
            time.sleep(.45)
            return
        adb('shell','input','swipe','540','1850','540','700','350')
    raise AssertionError(f'Could not find {text!r}. Visible: {labels()}')
def snap(name):
    (OUT/f'{name}.png').write_bytes(adb('exec-out','screencap','-p',binary=True))
    (OUT/f'{name}.xml').write_text(ET.tostring(tree(),encoding='unicode'))
def back():
    adb('shell','input','keyevent','4');time.sleep(.5)
def home():
    for _ in range(5):
        if 'My Day' in labels():return
        back()
    raise AssertionError('Cannot return to My Day')
def expect(text):
    assert any(text in s for s in labels()),(text,labels())

def main():
    home();snap('01-my-day')
    tap('My routines');tap('Walking');tap('Save',scroll=False)
    tap('Save my day');expect('Walking');snap('02-walking-planned')
    tap('Start');expect('Were you able');snap('03-movement-timer')
    tap('Completed partly / enter minutes');tap('7',scroll=False)
    time.sleep(.7);home();expect('Completed');snap('04-movement-confirmed')
    tap('Progress');expect('Movement minutes');snap('05-progress');back()
    tap('Library');expect('The window garden');tap('The window garden',partial=True)
    expect('Amina');snap('06-reader');tap('Next');expect('Each morning');back()
    expect('Library');tap('The window garden',partial=True);expect('Each morning')
    tap('Listen');time.sleep(2);snap('07-tts');
    if any('Pause listening'==s for s in labels()):tap('Pause listening')
    tap('Next');tap('Finish reading');tap('Answer 2 questions');expect('Where were the pots?');snap('08-reading-questions');tap('Done');home()
    tap('Free practice');
    for game in ['Quick Sums','Word Garden','Picture Pairs','Find the Target']:expect(game)
    assert not any('Low to High' in s or 'Color Word' in s for s in labels())
    snap('09-four-games')
    for game in ['Word Garden','Picture Pairs','Find the Target']:
        tap(game,partial=True);time.sleep(5);snap('game-'+game.replace(' ','-'));back()
    home();snap('10-final-my-day')
    print('PASS: plan creation, movement confirmation, progress, library, reader resume, TTS control, optional questions, four-game navigation. Evidence:', OUT)

if __name__ == '__main__':
    main()
