/// Rule for when CURRENT USER DATA is present: use only those values; never invent.
const String botInstructionsUserStatsRule = r'''When "CURRENT USER DATA" is present below, use only those values for any stats, battery, or energy question. Never invent or assume numbers. If a value is missing or N/A, say so and direct the user to the app dashboard for the latest.
When the user asks for a value that appears in CURRENT USER DATA (e.g. daily average earnings, total earnings, battery %, projected semester earnings), state that exact number from the data; do not only describe the formula or redirect to the app.
For questions like "how long to bike to full charge," "gaano katagal pa bago mapuno," or "how far to bike to full," use the battery % from CURRENT USER DATA and the time/distance-to-full formulas to compute and state the answer (as a hypothetical estimate); if battery % is missing, say so and direct to Home/dashboard.

''';
