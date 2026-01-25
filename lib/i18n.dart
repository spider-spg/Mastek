// Minimal in-app translations. Replace with `intl` + ARB for production.
class L10n {
  static const Map<String, Map<String, String>> _t = {
    'en': {
      'title': 'Symptom Checker',
      'hint': 'Describe symptoms (text or use mic)',
      'settings': 'Settings',
      'profile': 'Profile',
      'language': 'Language',
      'save': 'Save',
    },
    'hi': {
      'title': 'लक्षण जाँचकर्ता',
      'hint': 'लक्षण बताइए (टेक्स्ट या माइक्रोफ़ोन)',
      'settings': 'सेटिंग्स',
      'profile': 'प्रोफ़ाइल',
      'language': 'भाषा',
      'save': 'सहेजें',
    },
    'ta': {
      'title': 'அறிகுறி செக்கர்',
      'hint': 'அறிகுறிகளை விவரிக்கவும் (உரை அல்லது மைக்)',
      'settings': 'அமைப்புகள்',
      'profile': 'சுயவிவரம்',
      'language': 'மொழி',
      'save': 'சேமிக்கவும்',
    },
    'bn': {
      'title': 'লক্ষণ পরীক্ষা',
      'hint': 'লক্ষণ ব্যাখ্যা করুন (টেক্সট বা মাইক ব্যবহার করুন)',
      'settings': 'সেটিংস',
      'profile': 'প্রোফাইল',
      'language': 'ভাষা',
      'save': 'সংরক্ষণ',
    }
  };

  static String t(String key, String langCode) {
    if (langCode == 'auto') langCode = 'en';
    final base = langCode.split('_').first;
    return _t[base]?[key] ?? _t['en']![key] ?? key;
  }
}
