/// Static equations and formulas for the chatbot to use for hypothetical computations.
/// Values are sourced from app policy constants and the LakByke IMRaD study.
class FormulasContext {
  FormulasContext._();

  // System prompt and strict AI guardrails. Place this FIRST so the AI knows how to behave.
  static const String _aiPromptingRules = r'''
### AI SYSTEM INSTRUCTIONS & GUARDRAILS ###
1. STRICT ADHERENCE: You must ONLY use the exact values, constants, and formulas provided in the "COMPUTATIONAL SPECIFICATIONS" section below.
2. NO HALLUCINATION: Never invent, guess, or pull constants, conversion factors, or formulas from outside this context.
3. MISSING DATA: If a computation requires inputs not provided by the user or the context, you must explicitly ask the user for the missing value. Do not assume.
4. ESTIMATES VS. LIVE DATA: Clearly label calculated predictions as "hypothetical estimates." Never present them as live or measured current values.
5. RANGES: For range-based constants (e.g., 40–45 W or 1.5–2.0 Wh), calculate using both min and max to provide a range-based answer.
6. UNITS: Always append explicit units to your final outputs (e.g., Wh, W, km/h, km, ₱, hours, minutes).
7. SOURCE TRUTH: The data reflects a 12V 6Ah (72Wh) LiFePO4 portable battery context, LakByke CBA policy constants, and empirical LakByke IMRaD figures.

''';

  // Pure math, variables, and formulas. Cleaned up to read like strict logic.
  static const String _computationSpec = r'''
### COMPUTATIONAL SPECIFICATIONS ###

[0. SOURCE BASIS]
- App CBA policy constants: bot_instructions/cba.dart (buyback tiers and breakeven guidance used by the chatbot).
- Study document: LakByke IMRaD 2.2.1 (scope, battery specs, and empirical operating figures).

[1. CORE BATTERY & PAYOUT LOGIC]
Battery_Capacity_Wh = 72
Base_Payout_Rate_Per_100_Percent_Pesos = 30.00
rawValue_Pesos = (batteryPercent / 100) * Base_Payout_Rate_Per_100_Percent_Pesos
Payout_Rounding_Rule_Pesos = floor(rawValue_Pesos / 5) * 5

[2. ROI & EARNINGS FORMULAS]
roiProgressPercent = (totalEarnings / initialInvestment) * 100
remainingToBreakeven_Pesos = max(0, initialInvestment - totalEarnings)
dailyAverageEarnings_Pesos = totalEarnings / max(1, daysWithActivity)
projectedSemesterEarnings_Pesos = dailyAverageEarnings_Pesos * remainingSchoolDays
daysToBreakeven = ceil(remainingDebt / max(1, dailyAverageEarnings_Pesos))
breakevenDate = today + daysToBreakeven (null if remainingDebt <= 0 or dailyAverageEarnings_Pesos <= 0)

[3. BONUS FOR 15 MINUTES MORE PER DAY]
avgSessionMinutes = (totalDurationHours * 60) / totalSessions
earningRatePerMinute_Pesos = dailyAverageEarnings_Pesos / avgSessionMinutes
bonusFromExtra15Min_Pesos = earningRatePerMinute_Pesos * 15 * remainingSchoolDays

[4. SCHOOL DAYS & ROUNDING]
remainingSchoolDays = count of weekdays (Monday–Friday) from given date to semester end (inclusive)
Peso_Payout_Rounding(value) = floor(value / 5) * 5

[5. LAKBYKE CBA CONSTANTS]
Cyclist_Initial_Investment_Pesos = 3792
Cyclist_Yearly_Maintenance_Pesos = 700        // ≈ ₱1.91/day
Cyclist_Est_Breakeven_Months = 8
Station_Initial_Investment_Pesos = 10844
Station_Yearly_Maintenance_Pesos = 1360       // ≈ ₱3.72/day
Station_Est_Breakeven_Months = 4
Buyback_Tiers_Pesos = { Low: 10, Optimal: 30, High: 60 }

[6. EMPIRICAL KINETIC CONVERSIONS]
Average_Speed_Kmh = 15
Mechanical_Power_W = 70
Net_Stored_Power_W_Range = [40, 45]
Energy_Generated_Per_Hour_Wh = 40
Revenue_Per_Km_Pesos = 4.00
Max_Revenue_Per_Hour_Pesos = 60.00          // 15 km/h * ₱4/km
Revenue_From_Distance_Pesos = distanceKm * Revenue_Per_Km_Pesos

[7. CHARGING EQUIVALENTS & TIME]
Hours_To_Full_Charge = Battery_Capacity_Wh / Energy_Generated_Per_Hour_Wh   // ≈ 1.8 h or 108 min
Ten_Min_Phone_Charge_Wh_Range = [1.5, 2.0]
Phone_Charges_Per_Hour_Pedaling_Range = [20, 27]

[8. CLASSIFICATIONS]
Unit_Health_Distance_Km = {
  Excellent: totalDistanceKm < 500,
  Bolt_Check: 500 <= totalDistanceKm < 2000,
  Motor_Inspection: totalDistanceKm >= 2000
}

Rider_Persona_Avg_Hour = {
  Early_Bird:   06:00-09:59,
  Peak_Provider: 10:00-14:59,
  Sunset_Cruiser: 15:00-19:59
}
''';

  /// Returns the combined context for the chatbot: guardrails first, then computation spec.
  static String build() => _aiPromptingRules + _computationSpec;
}
