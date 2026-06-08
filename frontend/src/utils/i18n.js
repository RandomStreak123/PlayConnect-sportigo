import { store } from '../store'

const translations = {
  en: {
    // Nav / General
    home: 'Home',
    explore: 'Explore',
    matches: 'Matches',
    activity: 'Activity',
    noActivityUpdates: 'No activity updates yet',
    profile: 'Profile',
    seeAll: 'See All',
    by: 'By',
    
    // Greetings / Home Page
    goodMorning: 'Good morning,',
    goodAfternoon: 'Good afternoon,',
    goodEvening: 'Good evening,',
    findPlaceholder: 'Find matches or players...',
    createMatch: 'Create Match',
    nearbyMatches: 'Nearby Matches',
    trendingMatches: 'Trending Matches',
    joinMatchBtn: 'Join Match',
    joinAMatch: 'Join a Match',
    noMatchesFound: 'No upcoming matches found.',
    beFirstToCreate: 'Be the first to create one!',
    noTrendingMatches: 'No trending matches yet',
    slotsLeft: 'slots left',
    matchFull: 'Match Full',
    womenOnly: 'Women Only',
    
    // Profile Page
    playerProfile: 'Player Profile',
    level: 'LEVEL',
    levelProgression: 'Level Progression',
    reliability: 'Reliability',
    rating: 'Rating',
    streak: 'Streak',
    achievements: 'Achievements',
    streaks: 'Streaks',
    sportsSkillProfile: 'Sports Skill Profile',
    rateSkillIn: 'Rate Skill in',
    tapStarsToRate: 'Tap stars to rate your self-assessment skill level',
    selfAssessment: 'Self-assessment profile rating',
    personalization: 'Personalization',
    elegantLavender: 'Elegant Lavender Theme',
    lavenderActive: 'Lavender palette mode active',
    switchLavender: 'Switch to elegant lavender palette',
    gameRules: 'Dynamic Game Rules',
    gameRulesSub: 'Read platform game guide',
    statsHistory: 'Platform Stats History',
    statsHistorySub: 'Full tournament logs',
    signOut: 'Sign Out',
    signOutSub: 'Exit application cleanly',
    shareProfile: 'Share Profile',
    editProfile: 'Edit Profile',
    noBioYet: 'No bio written yet. Tap Edit Profile to add one!',
    consecutiveWeekly: 'Consecutive Weekly Matches Played',
    
    // Language Settings
    selectLanguage: 'Language / भाषा',
    hindi: 'Hindi / हिंदी',
    english: 'English / अंग्रेज़ी',
    
    // Create Match
    createNewMatch: 'Create New Match',
    sportType: 'Sport Type',
    matchTitle: 'Match Title',
    dateAndTime: 'Date & Time',
    location: 'Location',
    availableSlots: 'Available Slots',
    skillLevel: 'Skill Level',
    womenOnlyMatch: 'Women-Only Match',
    onlyFemaleCanJoin: 'Only female players can join this match',
    enableRestrictWomen: 'Enable to restrict to women players',
    enterMatchTitle: 'Please enter a match title',
    chooseDateAndTime: 'Please choose a date and time',
    enterCourtLocation: 'Please enter court location',
    specifyValidSlots: 'Please specify valid available slots',
    futureDateError: 'Please select a date and time in the future',
    failedCreateMatch: 'Failed to create match. Make sure the date and time is in the future.',
    
    // Explore Screen
    nearbyPlayers: 'Nearby Players',
    refreshList: 'Refresh list',
    noPlayersRegistered: 'No players registered yet',
    
    // Matches Screen
    upcoming: 'Upcoming',
    pastMatches: 'Past Matches',
    noUpcomingMatches: 'No Upcoming Matches',
    noMatchHistory: 'No Match History',
    noUpcomingDesc: 'You have no scheduled matches. Join an existing game or create your own to start playing!',
    noPastDesc: 'You haven\'t played any matches yet. Once you complete a match, it will be saved here.'
  },
  hi: {
    // Nav / General
    home: 'होम',
    explore: 'खोजें',
    matches: 'मैच',
    activity: 'गतिविधि',
    noActivityUpdates: 'अभी कोई गतिविधि अपडेट नहीं है',
    profile: 'प्रोफ़ाइल',
    seeAll: 'सभी देखें',
    by: 'द्वारा',
    
    // Greetings / Home Page
    goodMorning: 'शुभ प्रभात,',
    goodAfternoon: 'शुभ दोपहर,',
    goodEvening: 'शुभ संध्या,',
    findPlaceholder: 'मैच या खिलाड़ी खोजें...',
    createMatch: 'मैच बनाएं',
    nearbyMatches: 'आस-पास के मैच',
    trendingMatches: 'ट्रेंडिंग मैच',
    joinMatchBtn: 'मैच में शामिल हों',
    joinAMatch: 'मैच में शामिल हों',
    noMatchesFound: 'कोई आगामी मैच नहीं मिला।',
    beFirstToCreate: 'पहला मैच बनाने वाले बनें!',
    noTrendingMatches: 'अभी कोई ट्रेंडिंग मैच नहीं हैं',
    slotsLeft: 'स्थान शेष',
    matchFull: 'मैच पूर्ण',
    womenOnly: 'केवल महिलाएं',
    
    // Profile Page
    playerProfile: 'खिलाड़ी प्रोफ़ाइल',
    level: 'स्तर',
    levelProgression: 'स्तर प्रगति',
    reliability: 'विश्वसनीयता',
    rating: 'रेटिंग',
    streak: 'लगातार',
    achievements: 'उपलब्धियां',
    streaks: 'लगातार खेल',
    sportsSkillProfile: 'खेल कौशल प्रोफ़ाइल',
    rateSkillIn: 'कौशल दर दर्ज करें',
    tapStarsToRate: 'आत्म-मूल्यांकन कौशल स्तर को रेट करने के लिए सितारों पर टैप करें',
    selfAssessment: 'आत्म-मूल्यांकन प्रोफ़ाइल रेटिंग',
    personalization: 'वैयक्तिकरण',
    elegantLavender: 'शानदार लैवेंडर थीम',
    lavenderActive: 'लैवेंडर थीम मोड सक्रिय',
    switchLavender: 'शानदार लैवेंडर थीम पर स्विच करें',
    gameRules: 'गतिशील खेल नियम',
    gameRulesSub: 'प्लेटफ़ॉर्म गेम गाइड पढ़ें',
    statsHistory: 'प्लेटफ़ॉर्म आँकड़े इतिहास',
    statsHistorySub: 'पूर्ण टूर्नामेंट लॉग',
    signOut: 'लॉग आउट करें',
    signOutSub: 'एप्लिकेशन से बाहर निकलें',
    shareProfile: 'प्रोफ़ाइल साझा करें',
    editProfile: 'प्रोफ़ाइल संपादित करें',
    noBioYet: 'अभी तक कोई परिचय नहीं लिखा है। जोड़ने के लिए प्रोफ़ाइल संपादित करें पर टैप करें!',
    consecutiveWeekly: 'लगातार साप्ताहिक मैच खेले गए',
    
    // Language Settings
    selectLanguage: 'भाषा / Language',
    hindi: 'हिंदी / Hindi',
    english: 'अंग्रेज़ी / English',
    
    // Create Match
    createNewMatch: 'नया मैच बनाएं',
    sportType: 'खेल का प्रकार',
    matchTitle: 'मैच का शीर्षक',
    dateAndTime: 'दिनांक और समय',
    location: 'स्थान',
    availableSlots: 'उपलब्ध स्थान',
    skillLevel: 'कौशल स्तर',
    womenOnlyMatch: 'महिला-विशेष मैच',
    onlyFemaleCanJoin: 'केवल महिला खिलाड़ी ही इस मैच में शामिल हो सकती हैं',
    enableRestrictWomen: 'महिला खिलाड़ियों तक सीमित करने के लिए सक्षम करें',
    enterMatchTitle: 'कृपया मैच का शीर्षक दर्ज करें',
    chooseDateAndTime: 'कृपया दिनांक और समय चुनें',
    enterCourtLocation: 'कृपया कोर्ट का स्थान दर्ज करें',
    specifyValidSlots: 'कृपया वैध उपलब्ध स्थान निर्दिष्ट करें',
    futureDateError: 'कृपया भविष्य की तारीख और समय चुनें',
    failedCreateMatch: 'मैच बनाने में विफल। सुनिश्चित करें कि दिनांक और समय भविष्य में हो।',
    
    // Explore Screen
    nearbyPlayers: 'आस-पास के खिलाड़ी',
    refreshList: 'सूची रीफ़्रेश करें',
    noPlayersRegistered: 'अभी तक कोई खिलाड़ी पंजीकृत नहीं है',
    
    // Matches Screen
    upcoming: 'आगामी',
    pastMatches: 'पिछले मैच',
    noUpcomingMatches: 'कोई आगामी मैच नहीं',
    noMatchHistory: 'कोई मैच इतिहास नहीं',
    noUpcomingDesc: 'आपके पास कोई निर्धारित मैच नहीं है। खेलना शुरू करने के लिए किसी मौजूदा गेम में शामिल हों या अपना खुद का बनाएं!',
    noPastDesc: 'आपने अभी तक कोई मैच नहीं खेला है। एक बार जब आप एक मैच पूरा कर लेते हैं, तो इसे यहाँ सहेजा जाएगा।'
  }
}

export const t = (key) => {
  const lang = store.state.language || 'en'
  return translations[lang]?.[key] || translations['en']?.[key] || key
}
