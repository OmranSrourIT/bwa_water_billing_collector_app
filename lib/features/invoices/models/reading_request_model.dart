class ReadingRequest {
  final String invoiceNumber;
  final double previousReading;
  final double currentReading;
  final String currentReadDateTime;
  final String previousReadingDateTime;
  final bool isMeterRollover;

  final String latitude;
  final String longitude;

  final String? base64;

  ReadingRequest({
    required this.invoiceNumber,
    required this.previousReading,
    required this.currentReading,
    required this.currentReadDateTime,
    required this.previousReadingDateTime,
    required this.isMeterRollover,
    required this.latitude,
    required this.longitude,
    this.base64,
  });
}
