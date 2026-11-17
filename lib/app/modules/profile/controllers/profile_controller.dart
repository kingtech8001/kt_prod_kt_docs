import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepository;
  final AuthService _authService;

  ProfileController(this._authRepository, this._authService);

  final isLoading = false.obs;
  final isSavingProfile = false.obs;
  final isChangingPassword = false.obs;

  final profile = Rxn<ProfileModel>();

  // Profile Form Controllers
  final fullNameController = TextEditingController();
  final departmentController = TextEditingController();
  final phoneController = TextEditingController();

  // Password Change Form Controllers
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfileData();
  }

  void loadProfileData() {
    final current = _authService.currentProfile.value;
    if (current != null) {
      profile.value = current;
      fullNameController.text = current.fullName;
      departmentController.text = current.department ?? '';
      phoneController.text = current.phoneNumber ?? '';
    } else {
      fetchFreshProfile();
    }
  }

  Future<void> fetchFreshProfile() async {
    isLoading.value = true;
    try {
      final p = await _authRepository.getCurrentProfile();
      if (p != null) {
        profile.value = p;
        fullNameController.text = p.fullName;
        departmentController.text = p.department ?? '';
        phoneController.text = p.phoneNumber ?? '';
        _authService.updateProfile(p);
      }
    } catch (e, st) {
      AppLogger.error('PROFILE_CTRL', 'Error fetching profile: $e', error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    final current = profile.value;
    if (current == null) return;

    final name = fullNameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.showWarning(
        'Name Required',
        'Please enter your full name.',
      );
      return;
    }

    isSavingProfile.value = true;
    try {
      await _authRepository.updateStaffProfile(
        id: current.id,
        fullName: name,
        department: departmentController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        isActive: current.isActive,
      );

      final updated = current.copyWith(
        fullName: name,
        department: departmentController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );

      profile.value = updated;
      _authService.updateProfile(updated);

      AppSnackbar.showSuccess(
        'Profile Updated',
        'Your profile changes have been saved successfully.',
      );
    } catch (e, st) {
      AppLogger.error('PROFILE_CTRL', 'Error saving profile: $e', error: e, stackTrace: st);
      AppSnackbar.showError(
        'Update Failed',
        e.toString(),
      );
    } finally {
      isSavingProfile.value = false;
    }
  }

  Future<void> changePassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || newPassword.length < 6) {
      AppSnackbar.showWarning(
        'Invalid Password',
        'Password must be at least 6 characters.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppSnackbar.showWarning(
        'Password Mismatch',
        'The password confirmation does not match.',
      );
      return;
    }

    if (DemoDataService.isDemoMode) {
      newPasswordController.clear();
      confirmPasswordController.clear();
      AppSnackbar.showSuccess(
        'Password Changed (Demo)',
        'Simulated password update successfully in demo mode.',
      );
      return;
    }

    isChangingPassword.value = true;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      newPasswordController.clear();
      confirmPasswordController.clear();

      AppSnackbar.showSuccess(
        'Password Changed',
        'Your account password has been updated securely.',
      );
    } catch (e, st) {
      AppLogger.error('PROFILE_CTRL', 'Error updating password: $e', error: e, stackTrace: st);
      AppSnackbar.showError(
        'Password Update Failed',
        e.toString(),
      );
    } finally {
      isChangingPassword.value = false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    departmentController.dispose();
    phoneController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
