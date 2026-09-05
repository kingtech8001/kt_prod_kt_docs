class DashboardMetricsModel {
  final int totalDocuments;
  final int totalStorageBytes;
  final int totalFolders;
  final int expiringWarrantiesCount;
  final int activeWarrantiesCount;
  final int pendingBillsCount;
  final double pendingBillsAmount;
  final int trashCount;
  final int trashSizeBytes;

  DashboardMetricsModel({
    this.totalDocuments = 0,
    this.totalStorageBytes = 0,
    this.totalFolders = 0,
    this.expiringWarrantiesCount = 0,
    this.activeWarrantiesCount = 0,
    this.pendingBillsCount = 0,
    this.pendingBillsAmount = 0.0,
    this.trashCount = 0,
    this.trashSizeBytes = 0,
  });

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricsModel(
      totalDocuments: (json['total_documents'] as num?)?.toInt() ?? 0,
      totalStorageBytes: (json['total_storage_bytes'] as num?)?.toInt() ?? 0,
      totalFolders: (json['total_folders'] as num?)?.toInt() ?? 0,
      expiringWarrantiesCount:
          (json['expiring_warranties_count'] as num?)?.toInt() ?? 0,
      activeWarrantiesCount:
          (json['active_warranties_count'] as num?)?.toInt() ?? 0,
      pendingBillsCount: (json['pending_bills_count'] as num?)?.toInt() ?? 0,
      pendingBillsAmount:
          (json['pending_bills_amount'] as num?)?.toDouble() ?? 0.0,
      trashCount: (json['trash_count'] as num?)?.toInt() ?? 0,
      trashSizeBytes: (json['trash_size_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}
