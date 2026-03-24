// Provide human-friendly labels and descriptions for unit health statuses.

(String, String) unitHealthLabelAndDescription(String status) {
  switch (status) {
    case 'excellent':
      return ('Condition: Excellent', 'No maintenance actions needed.');
    case 'bolt_check':
      return (
        'Maintenance Due: Check Mounting Bolts',
        'Have a technician verify mounting bolts for safety.',
      );
    case 'motor_inspection':
      return (
        'Maintenance Due: Inspect Motor Brushes',
        'Schedule motor brush inspection to maintain performance.',
      );
    default:
      return ('Condition: Unknown', 'No maintenance actions needed.');
  }
}
