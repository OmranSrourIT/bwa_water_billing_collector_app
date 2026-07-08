class AppUpdate {
  final String apkURL;
  final bool needUpdate;

  AppUpdate({
    required this.apkURL,
    required this.needUpdate,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      apkURL: json['apkURL'],
      needUpdate: json['needUpdate'],
    );
  }
}
