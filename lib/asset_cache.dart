import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AssetCache {
  Future<Directory> applicationDocumentsDirectory = getApplicationDocumentsDirectory();

  Future<String> assetPath(String name) async {
    var docDir = await applicationDocumentsDirectory;
    return path.join(docDir.path, path.dirname(name), name);
  }

  Future<List<String>> prepareAssets(List<String> files) async {
    return Future.wait(files.map((file) => copyToDocDir(file)));
  }

  Future<String> copyToDocDir(String name) async {
    var p = await assetPath(name);
    if (!await FileSystemEntity.isFile(p)) {
      // copy asset file to local
      var data = await rootBundle.load(name);
      await Directory(path.dirname(p)).create(recursive: true);
      await new File(p).writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return p;
  }
}