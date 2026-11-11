import 'package:integration_test/integration_test.dart';
import '../../test/function_audit_core_test.dart' as core;
import '../../test/function_audit_desktop_test.dart' as desktop;
import '../../test/function_audit_rendering_test.dart' as rendering;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  core.main();
  rendering.main();
  desktop.main();
}
