class LocationRequest {
  final String invoiceNumber;
  final String latitude;
  final String longitude;

  const LocationRequest({
    required this.invoiceNumber,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      "InvoiceNumber": invoiceNumber,
      "Coordinates": {
        "Longitude": longitude,
        "Latitude": latitude,
      },
    };
  }

  factory LocationRequest.fromJson(Map<String, dynamic> json) {
    final coordinates = json["Coordinates"] as Map<String, dynamic>?;

    return LocationRequest(
      invoiceNumber: json["InvoiceNumber"]?.toString() ?? "",
      latitude: coordinates?["Latitude"]?.toString() ?? "",
      longitude: coordinates?["Longitude"]?.toString() ?? "",
    );
  }
}
