class CaseModel {
  final String patientId;
  final String patientName;
  final String age;
  final String gender;
  final String toothNumber;
  final String diagnosis;
  final String notes;
  final String imagePath;

  CaseModel({
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.toothNumber,
    required this.diagnosis,
    required this.notes,
    required this.imagePath,
  });
}