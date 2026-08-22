import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/users/controllers/users_controller.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UsersController>(() => UsersController(Get.find<AuthRepository>()));
  }
}
