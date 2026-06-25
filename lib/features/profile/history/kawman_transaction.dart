class KawmanTransaction {
  final String id;
  final String serviceName;
  final String title;
  final String subtitle;
  final DateTime date;
  final String status;
  final double? amount;
  final dynamic originalData;

  KawmanTransaction({
    required this.id,
    required this.serviceName,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    this.amount,
    this.originalData,
  });
}

class ServiceLinkStatus {
  final String serviceName;
  final bool isLinked;

  ServiceLinkStatus({
    required this.serviceName,
    required this.isLinked,
  });
}
