import 'package:lakbyke_mobile/features/chatbot/domain/bot_instructions/instructions.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/context_builder/contexts/formulas_context.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/context_builder/contexts/formulas_explanation_context.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/context_builder/contexts/home_context.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/context_builder/contexts/insights_context.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Builds context for the LakByke chatbot: app instructions and optional feature-specific user data.
/// Contexts are separated by feature (home, insights); combine with [buildFullUserContext] for the prompt.
class ChatbotContextBuilder {
  /// Returns the app-instructions and help context for the support chatbot.
  static String buildAppHelpContext() => getAppHelpContext();

  /// Equations and formulas for hypothetical computations (battery value, ROI, breakeven, etc.).
  static String buildFormulasContext() => FormulasContext.build();

  /// Narrative explanation and source mapping for the formulas context
  /// (how each constant and formula ties back to the LakByke CBA and IMRaD documents).
  static String buildFormulasExplanationContext() =>
      FormulasExplanationContext.build();

  /// Home/dashboard context: battery %, today's metrics (including live effort), totals, equivalent battery price.
  /// Returns empty string if [data] is null.
  static String buildHomeContext(HomeData? data) => HomeContext.build(data);

  /// Insights context: investment recovery progress, projected semester earnings, unit health, badge (rider persona).
  /// Returns empty string if [model] is null.
  static String buildInsightsContext(InsightsModel? model) => InsightsContext.build(model);

  /// Combined user context from home and insights. Use this in the prompt when both are available.
  /// Prefix indicates these are the only values the bot may use; never invent.
  static String buildFullUserContext({
    HomeData? homeData,
    InsightsModel? insightsModel,
  }) {
    final home = buildHomeContext(homeData);
    final insights = buildInsightsContext(insightsModel);
    if (home.isEmpty && insights.isEmpty) return '';
    return 'CURRENT USER DATA (use only these values; never invent):\n$home$insights';
  }

  /// Legacy: same as [buildFullUserContext] with only [data] (home). Prefer [buildFullUserContext] when insights are available.
  static String buildUserStatsContext(HomeData? data) {
    if (data == null) return '';
    final home = buildHomeContext(data);
    return 'CURRENT USER DATA (use only these values; never invent):\n$home';
  }
}
