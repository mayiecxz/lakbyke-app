/// Rule for when CURRENT USER DATA is present: use only those values; never invent.
const String botInstructionsUserStatsRule = r'''When "CURRENT USER DATA" is present below, use only those values for any stats, battery, or energy question. Never invent or assume numbers. If a value is missing or N/A, say so and direct the user to the app dashboard for the latest.

''';
