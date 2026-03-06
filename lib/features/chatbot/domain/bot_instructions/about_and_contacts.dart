/// Bot instruction strings for About LakByke, contacts, and team.
/// Data is imported from the account feature; only instruction wording lives here.

import 'package:lakbyke_mobile/features/account/domain/about_constants.dart';

/// Instruction block for the bot: about LakByke (use only this description).
String get botInstructionsAboutLakbyke => '''
ABOUT LAKBYKE (use only this description; do not invent details):
$lakbykeAboutDescription
If the user wants to read the full official description, contacts, team, and academic info inside the app, tell them to open the About screen via: Account → Support & account → About.

''';

/// Instruction block for the bot: contacts and team (cite only these; list all 8 when asked).
String get botInstructionsContactsAndTeam => '''
CONTACTS & TEAM — cite ONLY the following; do not invent any other links, emails, or names:

OFFICIAL CHANNELS:
- Facebook: $lakbykeOfficialFacebook
- Email: $lakbykeOfficialEmail
- Website: $lakbykeOfficialWebsite
- YouTube teaser: $lakbykeOfficialYoutubeTeaser

TEAM (exact names and roles only — there are exactly 8 people; when asked "who is on the team" or "list the team", you MUST include every one below; do not omit any):
- TEAM LEADER / Project Manager: $lakbykeTeamLeader
- TEAM MEMBER / Frontend Developer: $lakbykeTeamFrontend1
- TEAM MEMBER / Database Administrator: $lakbykeTeamDba
- TEAM MEMBER / App Developer: $lakbykeTeamAppDev
- TEAM MEMBER / Hardware Specialist: $lakbykeTeamHardware
- TEAM MEMBER / Frontend Developer: $lakbykeTeamFrontend2
- TEAM MEMBER / Backend Developer: $lakbykeTeamBackend
- TEAM MEMBER / Documentation Officer: $lakbykeTeamDoc

ACADEMIC AFFILIATION:
- Program: $lakbykeProgram
- Adviser: $lakbykeAdviser
- Institution: $lakbykeInstitution

If asked for contact or team info, use only the items listed above. Do not add or guess other URLs, emails, or names. When answering about the team or team members, always list all 8 people (1 team leader and 7 team members); never leave any out.

''';
