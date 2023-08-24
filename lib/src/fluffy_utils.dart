import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:vibration/vibration.dart';

/// Utilities for users who are neither familiar with nor desirous of exploring
/// further into the flutter framework itself.
class FluffyUtils {
  /// Shows a dialog with a piece of message and a confirm button.
  ///
  /// The [context] argument is used to look up the [Navigator] and [Theme] for
  /// the dialog.
  ///
  /// The [title] argument is used to indicate the title of the dialog.
  ///
  /// The [content] argument is used to indicate the main content of the dialog.
  ///
  /// The [buttonLabel] argument is used to indicate the content of the confirm
  /// button of the dialog.
  ///
  /// Returns a [Future].
  static Future<void> alert({
    required BuildContext context,
    String title = '',
    String content = '',
    String buttonLabel = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(buttonLabel),
          )
        ],
      ),
    );
  }

  /// Plays a **short** media file.
  ///
  /// It is very important that you **SHOULD NOT** play large music files with
  /// this. Use others such as [audioplayers](https://pub.dev/packages/audioplayers)
  /// for that purpose.
  static Future<int> playSound(String soundName) async {
    return await Sound.playSound(soundName);
  }

  /// Vibrates with [duration] at [amplitude] or [pattern] at [intensities].
  ///
  /// See [the vibration package](https://pub.dev/packages/vibration#vibrate)
  /// for more details.
  ///
  /// Note that on Android, the `VIBRATION` permission is required. You should
  /// modify the `android/app/src/main/AndroidManifest.xml` file and add this
  /// line below:
  ///
  /// ```xml
  /// <uses-permission android:name="android.permission.VIBRATE"/>
  /// ```
  ///
  /// Check out this [example](https://github.com/Baseflow/flutter-permission-handler/blob/main/permission_handler/example/android/app/src/main/AndroidManifest.xml)
  /// here for where to add the line of code above.
  static Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
  }) async {
    bool hasVibrator = await Vibration.hasVibrator() ?? false;

    if (!hasVibrator) {
      return;
    }

    bool hasCustomVibrationsSupport = await Vibration.hasVibrator() ?? false;

    if (hasCustomVibrationsSupport) {
      return Vibration.vibrate(
        duration: duration,
        pattern: pattern,
        repeat: repeat,
        intensities: intensities,
        amplitude: amplitude,
      );
    } else {
      return Vibration.vibrate();
    }
  }
}

/// Manages sound pools and sound ids.
///
/// Check out [the soundpool package](https://pub.dev/packages/soundpool) for
/// details.
class Sound {
  const Sound(this.pool, this.soundId);

  final Soundpool pool;

  final int soundId;

  /// Stores the created sound pools and cached sounds here.
  static Map<String, Sound> cachedSound = {};

  static Future<int> playSound(String soundName) async {
    Sound sound;

    if (cachedSound.containsKey(soundName)) {
      sound = cachedSound[soundName]!;
    } else {
      Soundpool pool = Soundpool.fromOptions(
        options: const SoundpoolOptions(),
      );
      int soundId = await rootBundle
          .load(soundName)
          .then((ByteData soundData) => pool.load(soundData));

      sound = Sound(pool, soundId);
      cachedSound[soundName] = sound;
    }

    return await sound.pool.play(sound.soundId);
  }
}
