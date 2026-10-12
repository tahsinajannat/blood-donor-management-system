class BloodRequest {
  final int id;
  final int userId;
  final String? requesterFirstName;
  final String? requesterLastName;
  final String patientName;
  final String? contactNumber;
  final String bloodGroup;
  final int units;
  final String requestType; // critical, urgent, normal
  final String status; // pending, accepted, fulfilled, cancelled
  final String cause;
  final String locationDetail;
  final String requiredTime;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  final String? resolvedAt;

  BloodRequest({
    required this.id,
    required this.userId,
    this.requesterFirstName,
    this.requesterLastName,
    required this.patientName,
    this.contactNumber,
    required this.bloodGroup,
    required this.units,
    required this.requestType,
    required this.status,
    required this.cause,
    required this.locationDetail,
    required this.requiredTime,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  String get requesterName =>
      "${requesterFirstName ?? ''} ${requesterLastName ?? ''}".trim();

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      requesterFirstName: json['first_name'],
      requesterLastName: json['last_name'],
      patientName: json['patient_name'] ?? '',
      contactNumber: json['contact_number'],
      bloodGroup: json['blood_group'] ?? '',
      units: json['units'] is int
          ? json['units']
          : int.tryParse(json['units'].toString()) ?? 0,
      requestType: json['request_type'] ?? 'normal',
      status: json['status'] ?? 'pending',
      cause: json['cause'] ?? '',
      locationDetail: json['location_detail'] ?? '',
      requiredTime: json['required_time']?.toString() ?? '',
      note: json['note'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
    );
  }
}
