class Complaint {
  final int id;
  final String identifier;
  final String description;
  final String status;
  final double lat;
  final double lng;
  final String address;
  final String? lockedAt;
  final String createdAt;

  final int complaintTypeId;
  final String complaintTypeName;

  final int destinationId;
  final String destinationName;

  final List<Document> documents;
  final List<dynamic> notes;
  final List<dynamic> extraInfo;
  final Map<String, dynamic>? employee; // إضافة الحقل لتجنب null exception

  Complaint({
    required this.id,
    required this.identifier,
    required this.description,
    required this.status,
    required this.lat,
    required this.lng,
    required this.address,
    this.lockedAt,
    required this.createdAt,
    required this.complaintTypeId,
    required this.complaintTypeName,
    required this.destinationId,
    required this.destinationName,
    required this.documents,
    required this.notes,
    required this.extraInfo,
    this.employee,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] ?? 0,
      identifier: json['identifier'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      lockedAt: json['locked_at'],
      createdAt: json['created_at'] ?? '',

      complaintTypeId: json['complaint_type']?['id'] ?? 0,
      complaintTypeName: json['complaint_type']?['name'] ?? '',

      destinationId: json['destination']?['id'] ?? 0,
      destinationName: json['destination']?['name'] ?? '',

      documents:
          (json['documents'] as List?)
              ?.map((doc) => Document.fromJson(doc))
              .toList() ??
          [],
      notes: json['notes'] ?? [],
      extraInfo: json['extraInfo'] ?? [],
      employee: json['employee'], // إضافة الحقل
    );
  }
}

class Document {
  final int id;
  final String file;

  Document({required this.id, required this.file});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(id: json['id'] ?? 0, file: json['file'] ?? '');
  }
}
