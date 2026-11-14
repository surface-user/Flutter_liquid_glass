import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _get(JSString key);
@JS('localStorage.setItem')
external void _set(JSString key, JSString value);
@JS('document.createElement')
external JSObject _element(JSString name);
extension type Anchor(JSObject _) implements JSObject {
  external set href(JSString value);
  external set download(JSString value);
  external void click();
}
String? readSaved() {
  try {
    return _get('glasslab.scene.v1'.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}

String? readBackup() {
  try {
    return _get('glasslab.scene.v1.backup'.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}

bool saveScene(String text) {
  try {
    final old = _get('glasslab.scene.v1'.toJS)?.toDart;
    if (old != null && !backupScene(old)) return false;
    _set('glasslab.scene.v1'.toJS, text.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

bool backupScene(String text) {
  try {
    if (_get('glasslab.scene.v1.backup'.toJS) == null)
      _set('glasslab.scene.v1.backup'.toJS, text.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

void downloadText(String name, String text) {
  final a = Anchor(_element('a'.toJS));
  a.href =
      ('data:application/json;charset=utf-8,${Uri.encodeComponent(text)}').toJS;
  a.download = name.toJS;
  a.click();
}

void downloadProject() {
  final a = Anchor(_element('a'.toJS));
  a.href = 'playground-source.zip'.toJS;
  a.download = 'glasslab-flutter-source.zip'.toJS;
  a.click();
}
