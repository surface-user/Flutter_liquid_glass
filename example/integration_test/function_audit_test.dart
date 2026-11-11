import 'package:integration_test/integration_test.dart';
import '../../test/bug_01_paint_test.dart' as bug01;
import '../../test/bug_02_selected_style_test.dart' as bug02;
import '../../test/bug_03_dialog_constraints_test.dart' as bug03;
import '../../test/bug_04_inherited_contrast_test.dart' as bug04;
import '../../test/bug_05_menu_focus_test.dart' as bug05;
import '../../test/function_audit_core_test.dart' as core;
import '../../test/function_audit_desktop_test.dart' as desktop;
import '../../test/function_audit_rendering_test.dart' as rendering;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  core.main();
  rendering.main();
  desktop.main();
  bug01.main();
  bug02.main();
  bug03.main();
  bug04.main();
  bug05.main();
}
