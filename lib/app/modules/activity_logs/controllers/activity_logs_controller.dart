import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/activity_log_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/activity_repository.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class ActivityLogsController extends GetxController {
  final ActivityRepository _activityRepository;

  ActivityLogsController(this._activityRepository);

  final isLoading = true.obs;
  final activities = <ActivityLogModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadActivityLogs();
  }

  Future<void> loadActivityLogs() async {
    isLoading.value = true;
    try {
      final list = await _activityRepository.getRecentActivities(limit: 100);
      activities.assignAll(list);
    } catch (e) {
      Get.snackbar('Error Loading Logs', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
