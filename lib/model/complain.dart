import 'dart:convert';
import 'dart:io';

class Complain {
  String? complaintTypeId;
  String destinationId;
  String lat;
  String lng;
  String address;
  String description;

  // ملف واحد
  File? document;

  // أكثر من ملف
  List<File> documents;

  Complain({
    required this.complaintTypeId,
    required this.destinationId,
    required this.lat,
    required this.lng,
    required this.address,
    required this.description,
    this.document,
    required this.documents,
  });

  Complain copyWith({
    String? complaintTypeId,
    String? destinationId,
    String? lat,
    String? lng,
    String? address,
    String? description,
    File? document,
    List<File>? documents,
  }) {
    return Complain(
      complaintTypeId: complaintTypeId ?? this.complaintTypeId,
      destinationId: destinationId ?? this.destinationId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      description: description ?? this.description,
      document: document ?? this.document,
      documents: documents ?? this.documents,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaint_type_id': complaintTypeId,
      'destination_id': destinationId,
      'lat': lat,
      'lng': lng,
      'address': address,
      'description': description,
      // نخزن path فقط للملفات
      'document': document?.path,
      'documents': documents.map((e) => e.path).toList(),
    };
  }

  factory Complain.fromMap(Map<String, dynamic> map) {
    return Complain(
      complaintTypeId: map['complaint_type_id'],
      destinationId: map['destination_id'],
      lat: map['lat'],
      lng: map['lng'],
      address: map['address'],
      description: map['description'],
      document: map['document'] != null ? File(map['document']) : null,
      documents: map['documents'] != null
          ? List<String>.from(
              map['documents'],
            ).map((path) => File(path)).toList()
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Complain.fromJson(String source) =>
      Complain.fromMap(json.decode(source));
}
