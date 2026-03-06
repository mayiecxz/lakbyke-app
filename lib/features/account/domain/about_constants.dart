/// Single source of truth for LakByke about, contacts, team, and academic info.
/// Used by the Account About screen and by the chatbot instructions.

// ——— Official channels ———
const String lakbykeOfficialFacebook = 'https://www.facebook.com/taralakbyke';
const String lakbykeOfficialEmail = 'tara.lakbyke@gmail.com';
const String lakbykeOfficialWebsite = 'https://lakbyke.com';
const String lakbykeOfficialYoutubeTeaser =
    'https://www.youtube.com/watch?v=tloeMqhHa5s';

// ——— Academic affiliation ———
const String lakbykeProgram = 'Bachelor of Science in Information Technology';
const String lakbykeAdviser =
    'Professor Jayson P. Joble, Coordinator, Computer Studies Department';
const String lakbykeInstitution = 'University of Caloocan City';

// ——— About description (shared by About screen and bot instructions) ———
const String lakbykeAboutDescription = r'''
LakByke is an IoT-integrated pedal energy conversion system that turns human pedaling into electrical energy using a PMDC motor, with energy stored in LiFePO4 and lead-acid batteries and supported by off-grid solar-powered stations. It was designed as a sustainable, campus-ready charging solution that lets cyclists harvest pedal power, store it in batteries, and redeem value at LakByke charging kiosks through a ride-to-earn model.
The system combines hardware (mountable bike unit and station), infrastructure (solar-supported kiosks with lockers and coin dispensers), and software (mobile app and admin web dashboard) to help users track energy, navigate to stations via maps, and support decentralized, community-based charging.
''';

// ——— Team (1 leader + 7 members) ———
const String lakbykeTeamLeader = 'Nacional, Jhon Patrick S.';
const String lakbykeTeamFrontend1 = 'Contalba, Jenny Rose C.';
const String lakbykeTeamDba = 'Empas, Jannah Shin V.';
const String lakbykeTeamAppDev = 'Laguilles, Rizza Mae M.';
const String lakbykeTeamHardware = 'Montefrio, Francine Gail G.';
const String lakbykeTeamFrontend2 = 'Taneo, Uriel Isaac P.';
const String lakbykeTeamBackend = 'Tapang, Curl Romulo';
const String lakbykeTeamDoc = 'Temones, John Simone A.';

/// Full About screen body text (description + channels + team + affiliation + nav hint).
String get lakbykeAboutFullText => '''
LakByke app overview

$lakbykeAboutDescription
OFFICIAL CHANNELS:
- Facebook: $lakbykeOfficialFacebook
- Email: $lakbykeOfficialEmail
- Website: $lakbykeOfficialWebsite
- YouTube teaser: $lakbykeOfficialYoutubeTeaser

TEAM (1 leader and 7 members — all must be listed):
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

To view this information in the app at any time, go to:
Account  →  Support & account  →  About.
''';
