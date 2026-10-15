class PaginationInfo {
  final int number;
  final int size;
  final int totalPages;
  final int totalElements;

  PaginationInfo({
    required this.number,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      number: json['number'],
      size: json['size'],
      totalPages: json['totalPages'],
      totalElements: json['totalElements'],
    );
  }
}
