/// Static equations and formulas for the chatbot to use for hypothetical computations.
/// All values match the app's logic; use only these when answering "what if" or calculation questions.
class FormulasContext {
  FormulasContext._();

  /// Returns the full EQUATIONS & FORMULAS block (no parameters).
  static String build() {
    return r'''EQUATIONS & FORMULAS (use for hypothetical computations; use only these values):

1. Battery value (equivalent price of charge):
   rawValue = (batteryPercent / 100) × 30
   payout = round down to nearest ₱5: floor(rawValue / 5) × 5
   Constant: ₱30 per 100% charge (72 Wh).

2. ROI progress (investment recovery %):
   roiProgressPercent = (totalEarnings / initialInvestment) × 100

3. Remaining to breakeven:
   remainingToBreakeven = max(0, initialInvestment - totalEarnings)

4. Daily average earnings:
   dailyAverageEarnings = totalEarnings / daysWithActivity (0 if daysWithActivity is 0)

5. Projected semester earnings:
   projectedSemesterEarnings = dailyAverageEarnings × remainingSchoolDays

6. Bonus for 15 minutes more per day (hypothetical):
   avgSessionMinutes = (totalDurationHours × 60) / totalSessions
   earningRatePerMinute = dailyAverageEarnings / avgSessionMinutes
   bonus = earningRatePerMinute × 15 × remainingSchoolDays

7. Days to breakeven / breakeven date:
   daysToBreakeven = ceil(remainingDebt / dailyAvg)
   Breakeven date = today + daysToBreakeven (null if already recovered or dailyAvg ≤ 0).

8. Remaining school days:
   Count of weekdays (Monday–Friday) from given date to semester end (inclusive).

9. Payout rounding rule:
   All peso payouts rounded down to nearest ₱5: payout = (value / 5) rounded down, then × 5.

10. CBA constants (for hypotheticals and "is it worth it?"):
    Cyclist: initial investment ₱3,792; yearly maintenance ₱700 (~₱1.91/day); breakeven ~8 months at optimal rate.
    Station: initial investment ₱10,844; yearly maintenance ₱1,360 (~₱3.72/day); breakeven ~4 months.
    Buyback per full 72 Wh: low ₱10, optimal ₱30, high ₱60.
    Battery: 1 unit = 72 Wh.

11. Unit health classification:
    totalDistanceKm < 500 → Excellent; 500 ≤ totalDistanceKm < 2000 → Bolt check; ≥ 2000 → Motor inspection.

12. Rider persona by average ride hour:
    Average ride hour in [6, 10) → Early Bird; [10, 15) → Peak Provider; [15, 20) → Sunset Cruiser.

''';
  }
}
