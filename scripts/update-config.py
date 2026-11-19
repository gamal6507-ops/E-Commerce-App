"""Apply public Firebase app registrations downloaded using the Firebase CLI."""
import json
from pathlib import Path

web = json.loads(Path('firebase-web-config.json').read_text(encoding='utf-8-sig'))['result']['sdkConfig']
android = json.loads(json.loads(Path('android-sdk.json').read_text(encoding='utf-8-sig'))['result']['fileContents'])
Path('android/app/google-services.json').write_text(json.dumps(android,indent=2),encoding='utf-8')
android_key = android['client'][0]['api_key'][0]['current_key']
import plistlib
ios = plistlib.loads(Path('ios/Runner/GoogleService-Info.plist').read_bytes())
def option(name, app_id, key, bundle=None):
    lines = [f'  static const {name} = FirebaseOptions(', f"    apiKey: '{key}',", f"    appId: '{app_id}',", f"    messagingSenderId: '{web['messagingSenderId']}',", f"    projectId: '{web['projectId']}',", f"    storageBucket: '{web['storageBucket']}',"]
    if bundle: lines.append(f"    iosBundleId: '{bundle}',")
    if name == 'web': lines.append(f"    authDomain: '{web['authDomain']}',")
    return '\n'.join(lines + ['  );'])
source = """import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch(defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      _ => throw UnsupportedError('This platform needs its own Firebase app registration'),
    };
  }
"""
source += '\n'.join([option('web',web['appId'],web['apiKey']),option('android',android['client'][0]['client_info']['mobilesdk_app_id'],android_key),option('ios',ios['GOOGLE_APP_ID'],ios['API_KEY'],ios['BUNDLE_ID'])]) + '\n}\n'
Path('lib/firebase_options.dart').write_text(source,encoding='utf-8')
Path('.firebaserc').write_text(json.dumps({'projects':{'default':web['projectId']}},indent=2),encoding='utf-8')
config={'firestore':{'rules':'firestore.rules','indexes':'firestore.indexes.json'},'auth':{'providers':{'emailPassword':True}},'emulators':{'auth':{'port':9099},'firestore':{'port':8080},'ui':{'enabled':True},'singleProjectMode':True}}
Path('firebase.json').write_text(json.dumps(config,indent=2),encoding='utf-8')
print('Configured public app registrations for',web['projectId'])
