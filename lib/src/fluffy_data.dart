import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Data storage utility of the Fluffy library.
///
/// {@category Introduction}
class FluffyData {
  /// Creates an instance of [FluffyData] with an empty data set.
  FluffyData();

  /// Creates an instance of [FluffyData] from a given list of [data].
  ///
  /// This is particular useful when you wish to save parts of all the data using
  /// the series of local save methods provided by [FluffyData] which cannot be
  /// directly called upon by a [List].
  FluffyData.from(List<Map<String, dynamic>> data) {
    _data.addAll(data);
  }

  /// The list of stored data.
  final List<Map<String, dynamic>> _data = [];

  /// Adds data item to the end of the list of stored data.
  void addDataItem(Map<String, dynamic> item) {
    _data.add(item);
  }

  /// Get parts of all the stored data by using a custom [filter].
  ///
  /// Each piece of data is passed into [filter], and should the function return
  /// `true`, this piece of data is included in the return value of [filterData].
  List<Map<String, dynamic>> filterData({
    required bool Function(Map<String, dynamic> item) filter,
  }) {
    List<Map<String, dynamic>> filteredData = [];
    for (var item in _data) {
      if (filter(item)) {
        filteredData.add(item);
      }
    }
    return _data;
  }

  /// Returns a copy of all the data preserved.
  ///
  /// While you can make modifications to individual pieces of data, there is no
  /// way to remove an entire trial of data, i.e., calling [List.remove] on the
  /// returned list of [getAllData] will not remove that piece of data in the
  /// stored data in [FluffyData].
  List<Map<String, dynamic>> getAllData() {
    List<Map<String, dynamic>> copyOfData = [];
    for (var item in _data) {
      copyOfData.add(item);
    }
    return copyOfData;
  }

  /// Gets the data of last trial.
  ///
  /// If there is no data yet stored, this will return an empty [Map].
  Map<String, dynamic> getLastTrialData() {
    int index = _data.length - 1;
    return index >= 0 ? _data[index] : {};
  }

  /// Converts data to csv string.
  String toCsv() {
    List<String> keys = _getAllKeys();
    List<List<dynamic>> csvList = [keys];

    for (var item in _data) {
      var entry = <String>[];
      for (String key in keys) {
        entry.add(item.containsKey(key) ? item[key] : '');
      }
      csvList.add(entry);
    }

    return const ListToCsvConverter().convert(csvList);
  }

  /// Converts data to json string.
  String toJson() {
    return jsonEncode(_data);
  }

  /// Saves data as csv file.
  ///
  /// The eventual full path of the file is [directory] and [fileName] put together.
  ///
  /// If [directory] is not set, the default value is used, which is:
  ///
  ///  * Android: external storage
  ///  * iOS / Linux / macOS / Windows: downloads
  Future<File> saveAsCsv({
    required String fileName,
    String? directory,
  }) async {
    File file = await _createDataFile(fileName: fileName, directory: directory);
    return file.writeAsString(toCsv());
  }

  /// Saves data as excel file.
  ///
  /// The eventual full path of the file is [directory] and [fileName] put together.
  ///
  /// If [directory] is not set, the default value is used, which is:
  ///
  ///  * Android: external storage
  ///  * iOS / Linux / macOS / Windows: downloads
  Future<void> saveAsExcel({
    required String fileName,
    String? directory,
  }) async {}

  /// Saves data as json file.
  ///
  /// The eventual full path of the file is [directory] and [fileName] put together.
  ///
  /// If [directory] is not set, the default value is used, which is:
  ///
  ///  * Android: external storage
  ///  * iOS / Linux / macOS / Windows: downloads
  Future<File> saveAsJson({
    required String fileName,
    String? directory,
  }) async {
    File file = await _createDataFile(fileName: fileName, directory: directory);
    return file.writeAsString(toJson());
  }

  /// Creates file with the given file name and directory.
  ///
  /// By default, [directory] is set to:
  ///
  ///  * Android: external storage
  ///  * iOS / Linux / macOS / Windows: downloads
  ///
  /// See [path_provider](https://pub-web.flutter-io.cn/packages/path_provider#supported-platforms-and-paths).
  Future<File> _createDataFile({
    required String fileName,
    String? directory,
  }) async {
    Directory defaultDir;

    if (Platform.isAndroid) {
      defaultDir = (await getExternalStorageDirectory())!;
    } else {
      defaultDir = (await getDownloadsDirectory())!;
    }

    String basePath = directory ?? defaultDir.path;

    String fullPath = join(basePath, fileName);

    return File(fullPath)..createSync(recursive: true);
  }

  /// Gets all key names of the stored data.
  List<String> _getAllKeys() {
    var keys = <String>[];

    for (var item in _data) {
      for (var key in item.keys) {
        if (!keys.contains(key)) {
          keys.add(key);
        }
      }
    }

    return keys;
  }
}
