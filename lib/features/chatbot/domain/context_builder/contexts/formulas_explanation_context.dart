/// Natural language explanation of LakByke formulas and constants.
/// Maps computation variables in [FormulasContext] to their narrative basis
/// in the LakByke CBA and IMRaD documents so the chatbot can explain its math.
class FormulasExplanationContext {
  FormulasExplanationContext._();

  static String build() => _body;

  static const String _body = r'''FORMULAS EXPLANATION & SOURCES

This section explains where each core formula and constant in the LakByke formulas context comes from,
so the chatbot can justify its math in plain language when users ask "why" or "how" questions.

1. Core Battery & Payout Logic

- Battery_Capacity_Wh = 72:
  The portable unit uses a 12V 6Ah LiFePO4 battery. Multiplying 12V by 6Ah gives 72Wh total capacity,
  which is the working energy basis for all payout and charging computations.

- Base_Payout_Rate_Per_100_Percent_Pesos = 30.00:
  The cost–benefit analysis (CBA) modeled several buyback scenarios for a fully charged 72Wh battery.
  Scenario B at ₱30.00 per fully charged battery was identified as the optimal equilibrium between station
  profit and cyclist incentive, so ₱30.00 per 100% charge is used as the base payout rate.

- rawValue_Pesos and Payout_Rounding_Rule_Pesos:
  The raw peso value is proportional to batteryPercent (state of charge) using the ₱30.00 full-charge base.
  To keep payouts simple and cash-friendly, values are rounded down to the nearest ₱5.00, matching the station’s
  coin-based payout design.

2. ROI & Earnings Formulas

- roiProgressPercent:
  Return on investment (ROI) is modeled as earnings divided by the original investment, expressed as a percentage.
  This follows the same logic used in the IMRaD CBA tables, where percentage ROI is based on annual net income
  relative to total CAPEX.

- remainingToBreakeven_Pesos and daysToBreakeven:
  RemainingToBreakeven subtracts cumulative earnings from the initial investment to show how much is left to recover.
  DaysToBreakeven divides the remaining amount by a daily average earning rate, mirroring the payback period
  reasoning in the CBA where months to breakeven are derived from projected cash flows.

- dailyAverageEarnings_Pesos and projectedSemesterEarnings_Pesos:
  DailyAverageEarnings uses totalEarnings divided by the number of active days, then projects this forward
  across remaining school days to estimate semester earnings. This mirrors how the study extrapolates annual
  and semester revenue from observed or assumed daily demand.

3. LakByke CBA Constants (Investment & Maintenance)

- Cyclist_Initial_Investment_Pesos = 3792:
  Represents the one-time cost of the mountable unit for a cyclist to participate in the ride-to-earn model.
  This value matches the CAPEX line item for the cyclist kit in the LakByke CBA.

- Cyclist_Yearly_Maintenance_Pesos = 700 and Cyclist_Est_Breakeven_Months = 8:
  The IMRaD financial analysis amortizes battery replacement and minor maintenance into an annual maintenance cost
  of roughly ₱700, which equates to about ₱1.91 per day. At the optimal ₱30.00 buyback rate, the projected net ROI
  yields a breakeven period of around 8 months for the cyclist.

- Station_Initial_Investment_Pesos = 10844:
  Captures the initial CAPEX for the fixed station hub (kiosk hardware, solar panels, control electronics,
  lockers, and coin mechanisms) as summarized in the CAPEX breakdown table.

- Station_Yearly_Maintenance_Pesos = 1360 and Station_Est_Breakeven_Months = 4:
  The station’s annual maintenance liability (battery replacement, hardware wear, and minor repairs)
  is estimated at roughly ₱1,360 per year (~₱3.72/day). Given the modeled demand and buyback scenario,
  the CBA computes an ROI of over 200% with a payback period of about 4 months.

- Buyback_Tiers_Pesos = { 10, 30, 60 }:
  The CBA evaluates three candidate rates for buying back a fully charged battery: ₱10, ₱30, and ₱60.
  These tiers represent conservative, optimal, and aggressive incentive levels used to bound the
  financial analysis.

4. Empirical Kinetic Conversions (Energy & Speed)

- Mechanical_Power_W = 70 and Net_Stored_Power_W_Range = [40, 45]:
  Human power studies and the LakByke IMRaD context assume that a casual commuter sustaining
  60–70 W at the pedals is realistic. Accounting for drivetrain and electrical conversion losses,
  the net stored electrical power is modeled at roughly 40–45 W.

- Energy_Generated_Per_Hour_Wh = 40:
  With approximately 40 W of net stored power, one hour of steady pedaling yields about 40Wh
  of energy stored in the battery. This matches the assumed value used for hourly yield, full-charge
  time, and phone-charging equivalents.

- Average_Speed_Kmh = 15 and Revenue_Per_Km_Pesos = 4.00:
  Based on typical campus and commuter behavior, the study adopts 15 km/h as a representative average speed.
  Given the modeled demand and pricing, this translates into a realizable gross revenue rate of roughly
  ₱4.00 per kilometer of travel when the generated energy is fully monetized through the station.

- Max_Revenue_Per_Hour_Pesos = 60.00:
  At 15 km/h and ₱4.00 per kilometer, the gross earning potential is about ₱60.00 per cyclist-hour.
  The station architecture (limited simultaneous users and locker capacity) means this is treated
  as an upper-bound gross revenue rate for planning scenarios.

5. Charging Equivalents & Time

- Hours_To_Full_Charge ≈ 1.8:
  Charging a fully depleted 72Wh battery at a net rate of 40W requires about 72Wh ÷ 40W = 1.8 hours,
  or approximately 108 minutes. This connects the IMRaD battery capacity to the empirical 40Wh/hour
  energy generation assumption.

- Ten_Min_Phone_Charge_Wh_Range = [1.5, 2.0] and Phone_Charges_Per_Hour_Pedaling_Range = [20, 27]:
  A quick 10-minute smartphone top-up is estimated to consume about 1.5–2.0Wh depending on device
  and charger efficiency. Since one hour of pedaling budgets about 40Wh, the system can support roughly
  20–27 of these quick charging sessions from a single hour of pedaling energy.

6. App-Specific Classifications (Not from the Study)

- Unit_Health_Distance_Km:
  The thresholds for Excellent, Bolt Check, and Motor Inspection based on totalDistanceKm are
  an app-level heuristic for maintenance reminders. These thresholds are not part of the formal IMRaD
  study; they were introduced by the development team to give riders simple health labels for their unit.

- Rider_Persona_Avg_Hour:
  The Early Bird, Peak Provider, and Sunset Cruiser personas are gamified labels derived from
  the rider’s average pedaling hour. These are UX features added on top of the research, not claims
  from the academic evaluation.

HOW TO USE THIS EXPLANATION CONTEXT

- When users ask "why is the payout like that?" or "where did you get that number?",
  the chatbot should use this explanation block to reference the CAPEX tables, ROI discussion,
  and empirical assumptions from the LakByke study instead of inventing new justifications.
- When citing demand, ROI, or power figures, the chatbot should frame them as values based on
  the LakByke CBA and IMRaD analysis, not as live sensor readings.

''';
}

