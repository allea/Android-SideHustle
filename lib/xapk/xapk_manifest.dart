/// XAPK manifest.json data model
class XapkManifest {
  final String packageName;
  final String? versionName;
  final int? versionCode;
  final String? name;
  final List<String> splitApks;
  final List<XapkObbFile> obbFiles;
  final List<XapkExpansion> expansions;

  XapkManifest({
    required this.packageName,
    this.versionName,
    this.versionCode,
    this.name,
    this.splitApks = const [],
    this.obbFiles = const [],
    this.expansions = const [],
  });

  factory XapkManifest.fromJson(Map<String, dynamic> json) {
    return XapkManifest(
      packageName: json['package_name'] as String,
      versionName: json['version_name']?.toString(),
      versionCode: _parseVersionCode(json['version_code']),
      name: json['name'] as String?,
      splitApks: _parseSplitApks(json),
      obbFiles: _parseObbFiles(json),
      expansions: _parseExpansions(json),
    );
  }

  static int? _parseVersionCode(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _parseSplitApks(Map<String, dynamic> json) {
    final splitApks = json['split_apks'] as List<dynamic>?;
    if (splitApks == null) return [];
    return splitApks
        .map((e) => e is Map ? e['file'] as String? : e as String?)
        .whereType<String>()
        .toList();
  }

  static List<XapkObbFile> _parseObbFiles(Map<String, dynamic> json) {
    final obbFiles = json['obb_files'] as List<dynamic>?;
    if (obbFiles != null) {
      return obbFiles
          .map((e) => XapkObbFile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<XapkExpansion> _parseExpansions(Map<String, dynamic> json) {
    final expansions = json['expansions'] as List<dynamic>?;
    if (expansions == null) return [];
    return expansions
        .map((e) => XapkExpansion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class XapkObbFile {
  final String file;
  final String installPath;

  XapkObbFile({required this.file, required this.installPath});

  factory XapkObbFile.fromJson(Map<String, dynamic> json) {
    return XapkObbFile(
      file: json['file'] as String,
      installPath: json['install_path'] as String? ??
          json['install_location'] as String? ??
          '',
    );
  }
}

class XapkExpansion {
  final String file;
  final String installPath;

  XapkExpansion({required this.file, required this.installPath});

  factory XapkExpansion.fromJson(Map<String, dynamic> json) {
    return XapkExpansion(
      file: json['file'] as String,
      installPath: json['install_path'] as String? ?? '',
    );
  }
}
