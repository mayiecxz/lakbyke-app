// Maps rider persona keys to display name and advice.

(String, String) riderPersonaNameAndAdvice(String persona) {
  switch (persona) {
    case 'early_bird':
      return (
        'Early Bird',
        'Ride early to stay cool and beat the midday rush.',
      );
    case 'peak_provider':
      return (
        'Peak Provider',
        'You ride when the station is busiest—great for earning.',
      );
    case 'sunset_cruiser':
      return (
        'Sunset Cruiser',
        'Evening rides help you wind down and still contribute.',
      );
    default:
      return (
        'Unknown',
        'Complete at least 3 rides to unlock your Rider Persona.',
      );
  }
}
