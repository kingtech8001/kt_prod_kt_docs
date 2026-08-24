import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;

  AuthController(this._authRepository);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final lastErrorMessage = ''.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void _showDetailedErrorDialog(String title, String errorMessage, [dynamic fullError]) {
    lastErrorMessage.value = errorMessage;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An error occurred during authentication. Details are provided below:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                errorMessage,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Error Message'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '$title: $errorMessage\nFull: $fullError'));
              Get.snackbar(
                'Copied',
                'Error details copied to clipboard',
                backgroundColor: AppColors.success,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    AppLogger.debug('AUTH_CTRL', 'Signing in with email: $email');

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid work email address',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (password.isEmpty) {
      Get.snackbar(
        'Password Required',
        'Please enter your password',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      AppLogger.info('AUTH_CTRL', 'Calling authRepository.signInWithEmail...');
      await _authRepository.signInWithEmail(email: email, password: password);

      // Hydrate user profile into reactive AuthService
      AppLogger.info('AUTH_CTRL', 'Hydrating profile into AuthService...');
      if (Get.isRegistered<AuthService>()) {
        await AuthService.to.loadProfile();
      }

      Get.snackbar(
        'Welcome',
        'Successfully signed in to Kt DocHolder',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );

      Get.offAllNamed(AppRoutes.DASHBOARD);
    } on AuthException catch (ae, st) {
      AppLogger.error('AUTH_CTRL', 'AuthException caught: ${ae.message}', error: ae, stackTrace: st);
      _showDetailedErrorDialog('Authentication Error', ae.message, ae);
    } on PostgrestException catch (pe, st) {
      AppLogger.error('AUTH_CTRL', 'PostgrestException caught: ${pe.message}', error: pe, stackTrace: st);
      _showDetailedErrorDialog('Database Error (${pe.code})', pe.message, pe);
    } catch (e, st) {
      AppLogger.error('AUTH_CTRL', 'Unexpected error during signIn: $e', error: e, stackTrace: st);
      _showDetailedErrorDialog('Sign In Failed', e.toString(), e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
