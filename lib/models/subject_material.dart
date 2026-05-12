class SubjectMaterial {
  final String id;
  final String subjectId;
  final String subjectName;
  final String fileName;
  final String filePath; // local path after copying
  final String fileExtension;
  final int fileSizeBytes;
  final DateTime addedAt;

  SubjectMaterial({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.fileName,
    required this.filePath,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.addedAt,
  });

  String get displaySize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'fileName': fileName,
        'filePath': filePath,
        'fileExtension': fileExtension,
        'fileSizeBytes': fileSizeBytes,
        'addedAt': addedAt.toIso8601String(),
      };

  factory SubjectMaterial.fromJson(Map<String, dynamic> json) =>
      SubjectMaterial(
        id: json['id'],
        subjectId: json['subjectId'],
        subjectName: json['subjectName'],
        fileName: json['fileName'],
        filePath: json['filePath'],
        fileExtension: json['fileExtension'],
        fileSizeBytes: json['fileSizeBytes'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}
