/// Barrel for bot instruction constants and composed app-help context.
library;

import 'app_sections.dart';
import 'cba.dart';
import 'how_to_guide.dart';

export 'identity.dart';
export 'mission_and_scope.dart';
export 'response_rules.dart';
export 'user_stats_instructions.dart';
export 'app_sections.dart';
export 'how_to_guide.dart';
export 'cba.dart';

/// Returns the full app-help context string (app sections + how to guide + CBA).
String getAppHelpContext() =>
    botInstructionsAppSections + botInstructionsHowToGuide + botInstructionsCba;
