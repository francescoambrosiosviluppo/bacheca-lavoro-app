/// Modelli dei dati scambiati con il server.
library;

DateTime _date(Object? v) => DateTime.tryParse(v as String? ?? '')?.toLocal() ?? DateTime.now();

class Company {
  const Company({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory Company.fromJson(Map<String, dynamic> j) =>
      Company(id: j['id'] as int, name: j['name'] as String, email: j['email'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class Job {
  const Job({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    this.location,
    this.contractType,
    required this.createdAt,
    required this.applicationsCount,
  });

  final int id;
  final int companyId;
  final String companyName;
  final String title;
  final String description;
  final String? location;
  final String? contractType;
  final DateTime createdAt;
  final int applicationsCount;

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    id: j['id'] as int,
    companyId: j['companyId'] as int,
    companyName: j['companyName'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    location: j['location'] as String?,
    contractType: j['contractType'] as String?,
    createdAt: _date(j['createdAt']),
    applicationsCount: (j['applicationsCount'] as int?) ?? 0,
  );
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.message,
    required this.cvFilename,
    required this.createdAt,
  });

  final int id;
  final int jobId;
  final String jobTitle;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? message;
  final String cvFilename;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';

  factory JobApplication.fromJson(Map<String, dynamic> j) => JobApplication(
    id: j['id'] as int,
    jobId: j['jobId'] as int,
    jobTitle: j['jobTitle'] as String,
    firstName: j['firstName'] as String,
    lastName: j['lastName'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String?,
    message: j['message'] as String?,
    cvFilename: j['cvFilename'] as String,
    createdAt: _date(j['createdAt']),
  );
}
