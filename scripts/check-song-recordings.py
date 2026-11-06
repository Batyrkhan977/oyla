#!/usr/bin/env python3
"""Check public availability of Sing recordings via YouTube oEmbed.

No API key required. This detects missing/private and blocked recordings; it
cannot guarantee regional playback. Follow with the in-app emulator check.
"""
import concurrent.futures
import json
from pathlib import Path
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

SOURCE = Path(__file__).resolve().parents[1] / 'mobile/lib/src/song_recordings.dart'


def recordings():
    source = SOURCE.read_text()
    primary = re.findall(
        r"SongRecording\(\s*'([^']+)',\s*'[^']+',\s*'[^']+',"
        r"\s*AppLanguage\.\w+,\s*'([^']+)'", source)
    alternatives = re.findall(r"SongPerformance\(\s*'([^']+)',\s*'([^']+)'", source)
    return primary + [(f'alternative:{name}', video) for video, name in alternatives]


def check(recording):
    song, video = recording
    endpoint = 'https://www.youtube.com/oembed?' + urllib.parse.urlencode({
        'url': f'https://www.youtube.com/watch?v={video}', 'format': 'json'})
    result = {'song': song, 'videoId': video}
    try:
        with urllib.request.urlopen(endpoint, timeout=20) as response:
            data = json.load(response)
        result.update(status='available', title=data['title'], channel=data['author_name'])
    except (urllib.error.URLError, TimeoutError, ValueError, KeyError) as error:
        result.update(status='failed', error=str(error))
    return result


def main():
    entries = recordings()
    if len(entries) < 20:
        raise SystemExit('Could not read the complete song catalog.')
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(check, entries))
    for result in results:
        print(json.dumps(result, ensure_ascii=False))
    return int(any(result['status'] != 'available' for result in results))


if __name__ == '__main__':
    sys.exit(main())
