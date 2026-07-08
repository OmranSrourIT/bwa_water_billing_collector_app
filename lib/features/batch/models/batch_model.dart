class BatchModel {
  final String batchNumber;
  final DateTime assignedDate;
  final DateTime collectionDueDate;
  final String statusCode;

  BatchModel({
    required this.batchNumber,
    required this.assignedDate,
    required this.collectionDueDate,
    required this.statusCode,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      batchNumber: json['batchNumber'],
      assignedDate: DateTime.parse(json['assignedDate']),
      collectionDueDate: DateTime.parse(json['collectionDueDate']),
      statusCode: json['statusCode'],
    );
  }
}
