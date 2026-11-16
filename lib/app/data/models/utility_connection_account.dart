import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

/// Represents a distinct utility connection/meter account (e.g., RK Iconic Office 1118 - PGVCL).
/// Aggregates multiple recurring monthly/bi-monthly bill cycles into a single unified account ledger.
class UtilityConnectionAccount {
  final String accountKey;
  final String consumerNumber;
  final String? meterNumber;
  final String providerName;
  final String utilityType;
  final String? premiseName;
  final String? flatHouseNo;
  final String? buildingName;
  final String? streetAddress;
  final String? areaLocality;
  final String? city;
  final String? postalCode;
  final String state;
  final String country;
  final DocumentModel latestBill;
  final List<DocumentModel> historicalBills; // All bills for this connection, sorted newest first

  const UtilityConnectionAccount({
    required this.accountKey,
    required this.consumerNumber,
    this.meterNumber,
    required this.providerName,
    required this.utilityType,
    this.premiseName,
    this.flatHouseNo,
    this.buildingName,
    this.streetAddress,
    this.areaLocality,
    this.city,
    this.postalCode,
    this.state = 'Gujarat',
    this.country = 'India',
    required this.latestBill,
    required this.historicalBills,
  });

  int get totalCyclesCount => historicalBills.length;
  bool get isPaid => latestBill.utilityMetadata?.isPaid ?? false;
  bool get isOverdue => latestBill.utilityMetadata?.isOverdue ?? false;
  double get latestBillAmount => latestBill.utilityMetadata?.billAmount ?? 0.0;
  DateTime get latestBillDate =>
      latestBill.utilityMetadata?.billDate ?? latestBill.createdAt;
  DateTime? get latestDueDate => latestBill.utilityMetadata?.dueDate;

  /// Friendly human-readable connection title (e.g., "RK Iconic, B-1118", "Corporate Office", etc.)
  String get displayName {
    if (premiseName != null && premiseName!.trim().isNotEmpty) {
      return premiseName!.trim();
    }
    if (flatHouseNo != null && flatHouseNo!.trim().isNotEmpty) {
      return flatHouseNo!.trim();
    }
    // Check if the latest bill's title has premise hints (like "Home", "Office")
    final title = latestBill.title.trim();
    if (title.toLowerCase().contains('office') ||
        title.toLowerCase().contains('home') ||
        title.toLowerCase().contains('iconic')) {
      return title;
    }
    return '$providerName ($consumerNumber)';
  }

  /// Formatted full physical address of the premises
  String get fullAddress {
    final parts = <String>[];
    if (flatHouseNo != null && flatHouseNo!.trim().isNotEmpty) {
      parts.add(flatHouseNo!.trim());
    }
    if (buildingName != null && buildingName!.trim().isNotEmpty) {
      parts.add(buildingName!.trim());
    }
    if (streetAddress != null && streetAddress!.trim().isNotEmpty) {
      parts.add(streetAddress!.trim());
    }
    if (areaLocality != null && areaLocality!.trim().isNotEmpty) {
      parts.add(areaLocality!.trim());
    }
    if (city != null && city!.trim().isNotEmpty) {
      if (postalCode != null && postalCode!.trim().isNotEmpty) {
        parts.add('${city!.trim()} - ${postalCode!.trim()}');
      } else {
        parts.add(city!.trim());
      }
    }
    if (state.trim().isNotEmpty) parts.add(state.trim());
    if (country.trim().isNotEmpty) parts.add(country.trim());
    return parts.isNotEmpty ? parts.join(', ') : (city ?? 'Rajkot, Gujarat, India');
  }

  /// Icon representing the utility category
  IconData get iconData {
    final type = utilityType.toLowerCase();
    if (type.contains('elec') || type.contains('light') || type.contains('power')) {
      return Icons.bolt_rounded;
    }
    if (type.contains('gas') || type.contains('png') || type.contains('lpg')) {
      return Icons.local_fire_department_rounded;
    }
    if (type.contains('broadband') || type.contains('internet') || type.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (type.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (type.contains('tax') || type.contains('property')) {
      return Icons.account_balance_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  /// Accent color representing the utility category
  Color get accentColor {
    final type = utilityType.toLowerCase();
    if (type.contains('elec') || type.contains('light') || type.contains('power')) {
      return const Color(0xFFD97706); // Amber / Electric
    }
    if (type.contains('gas') || type.contains('png') || type.contains('lpg')) {
      return const Color(0xFFEA580C); // Orange Flame
    }
    if (type.contains('broadband') || type.contains('internet') || type.contains('wifi')) {
      return const Color(0xFF0284C7); // Sky Blue
    }
    if (type.contains('water')) {
      return const Color(0xFF0D9488); // Teal
    }
    if (type.contains('tax') || type.contains('property')) {
      return const Color(0xFF7C3AED); // Purple
    }
    return AppColors.primary;
  }

  /// Creates a list of [UtilityConnectionAccount] from a raw flat list of documents.
  static List<UtilityConnectionAccount> groupFromDocuments(List<DocumentModel> docs) {
    final Map<String, List<DocumentModel>> groups = {};

    for (final doc in docs) {
      final meta = doc.utilityMetadata;
      if (meta == null) continue;

      // Group key: normalized consumer number, or fallback to provider+premise if consumer number is missing
      final rawConsumer = meta.consumerNumber.trim();
      final consumerKey = rawConsumer.isNotEmpty
          ? rawConsumer.toLowerCase()
          : (doc.address?.premiseName?.toLowerCase().trim() ??
              'unknown_${doc.id}');

      groups.putIfAbsent(consumerKey, () => []).add(doc);
    }

    final List<UtilityConnectionAccount> accounts = [];

    groups.forEach((key, groupDocs) {
      // Sort bills chronologically: newest bill_date or created_at first
      groupDocs.sort((a, b) {
        final aDate = a.utilityMetadata?.billDate ?? a.createdAt;
        final bDate = b.utilityMetadata?.billDate ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

      final latest = groupDocs.first;
      final meta = latest.utilityMetadata!;

      // Find the best address details among all bills in this group
      String? bestPremise;
      String? bestFlat;
      String? bestBuilding;
      String? bestStreet;
      String? bestArea;
      String? bestCity;
      String? bestPostal;
      String bestState = 'Gujarat';
      String bestCountry = 'India';
      String? bestMeter;

      for (final d in groupDocs) {
        if (bestPremise == null && d.address?.premiseName != null && d.address!.premiseName!.trim().isNotEmpty) {
          bestPremise = d.address!.premiseName!.trim();
        }
        if (bestFlat == null && d.address?.flatHouseNo != null && d.address!.flatHouseNo!.trim().isNotEmpty) {
          bestFlat = d.address!.flatHouseNo!.trim();
        }
        if (bestBuilding == null && d.address?.buildingName != null && d.address!.buildingName!.trim().isNotEmpty) {
          bestBuilding = d.address!.buildingName!.trim();
        }
        if (bestStreet == null && d.address?.streetAddress != null && d.address!.streetAddress!.trim().isNotEmpty) {
          bestStreet = d.address!.streetAddress!.trim();
        }
        if (bestArea == null && d.address?.areaLocality != null && d.address!.areaLocality.trim().isNotEmpty) {
          bestArea = d.address!.areaLocality.trim();
        }
        if (bestCity == null && d.address?.city != null && d.address!.city.trim().isNotEmpty) {
          bestCity = d.address!.city.trim();
        }
        if (bestPostal == null && d.address?.postalCode != null && d.address!.postalCode!.trim().isNotEmpty) {
          bestPostal = d.address!.postalCode!.trim();
        }
        if (d.address?.state != null && d.address!.state.trim().isNotEmpty) {
          bestState = d.address!.state.trim();
        }
        if (d.address?.country != null && d.address!.country.trim().isNotEmpty) {
          bestCountry = d.address!.country.trim();
        }
        if (bestMeter == null && d.utilityMetadata?.meterNumber != null && d.utilityMetadata!.meterNumber!.trim().isNotEmpty) {
          bestMeter = d.utilityMetadata!.meterNumber!.trim();
        }
      }

      accounts.add(
        UtilityConnectionAccount(
          accountKey: key,
          consumerNumber: meta.consumerNumber,
          meterNumber: bestMeter ?? meta.meterNumber,
          providerName: meta.providerName,
          utilityType: meta.utilityType,
          premiseName: bestPremise,
          flatHouseNo: bestFlat,
          buildingName: bestBuilding,
          streetAddress: bestStreet,
          areaLocality: bestArea,
          city: bestCity ?? latest.address?.city,
          postalCode: bestPostal ?? latest.address?.postalCode,
          state: bestState,
          country: bestCountry,
          latestBill: latest,
          historicalBills: groupDocs,
        ),
      );
    });

    // Sort accounts so pending/overdue bills are highlighted at the top, then by latest bill date
    accounts.sort((a, b) {
      if (!a.isPaid && b.isPaid) return -1;
      if (a.isPaid && !b.isPaid) return 1;
      return b.latestBillDate.compareTo(a.latestBillDate);
    });

    return accounts;
  }
}
