import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/android_manifest.dart';

const _android = 'http://schemas.android.com/apk/res/android';

const _dump =
    '''
N: android=$_android (line=2)
  E: manifest (line=2)
    A: package="io.github.diegociarafoni.scacchi" (Raw: "io.github.diegociarafoni.scacchi")
    E: uses-permission (line=10)
      A: $_android:name(0x01010003)="android.permission.INTERNET" (Raw: "android.permission.INTERNET")
    E: uses-permission (line=11)
      A: $_android:name(0x01010003)="io.github.diegociarafoni.scacchi.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" (Raw: "io.github.diegociarafoni.scacchi.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION")
    E: application (line=20)
      A: $_android:debuggable(0x0101000f)=true
      A: $_android:allowBackup(0x01010280)=false
      E: activity (line=21)
        A: $_android:name(0x01010003)="io.github.diegociarafoni.scacchi.MainActivity" (Raw: "io.github.diegociarafoni.scacchi.MainActivity")
        A: $_android:exported(0x01010010)=true
        E: intent-filter (line=30)
          E: action (line=31)
            A: $_android:name(0x01010003)="android.intent.action.MAIN" (Raw: "android.intent.action.MAIN")
      E: receiver (line=40)
        A: $_android:name(0x01010003)="androidx.profileinstaller.ProfileInstallReceiver" (Raw: "androidx.profileinstaller.ProfileInstallReceiver")
        A: $_android:permission(0x01010006)="android.permission.DUMP" (Raw: "android.permission.DUMP")
        A: $_android:exported(0x01010010)=true
      E: provider (line=50)
        A: $_android:name(0x01010003)="com.example.LeakyProvider" (Raw: "com.example.LeakyProvider")
        A: $_android:exported(0x01010010)=(type 0x12)0xffffffff
''';

void main() {
  final manifest = AndroidManifest.parseXmlTree(_dump);

  test('legge pacchetto e permessi', () {
    expect(manifest.packageName, 'io.github.diegociarafoni.scacchi');
    expect(manifest.permissions, [
      'android.permission.INTERNET',
      'io.github.diegociarafoni.scacchi.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
    ]);
  });

  test('legge gli attributi booleani dell\'applicazione', () {
    expect(manifest.isDebuggable, isTrue);
    expect(manifest.allowsBackup, isFalse);
  });

  test('individua i componenti esportati senza permesso', () {
    expect(manifest.unprotectedExportedComponents, [
      'io.github.diegociarafoni.scacchi.MainActivity',
      'com.example.LeakyProvider',
    ]);
  });
}
