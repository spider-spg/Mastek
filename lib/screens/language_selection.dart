import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageOption {
  const _LanguageOption(
      {required this.code,
      required this.nativeName,
      required this.englishName});

  final String code;
  final String nativeName;
  final String englishName;
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  static const List<_LanguageOption> _languages = <_LanguageOption>[
    _LanguageOption(code: 'en', nativeName: 'English', englishName: 'English'),
    _LanguageOption(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    _LanguageOption(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
    _LanguageOption(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
    _LanguageOption(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
    _LanguageOption(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
    _LanguageOption(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
    _LanguageOption(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
    _LanguageOption(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
    _LanguageOption(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi'),
    _LanguageOption(code: 'as', nativeName: 'অসমীয়া', englishName: 'Assamese'),
    _LanguageOption(code: 'or', nativeName: 'ଓଡିଆ', englishName: 'Odia'),
  ];

  late String _selectedCode;
  bool _localeInitialized = false;
  bool _hasUserSelected = true;
  final Color _primaryColor = const Color(0xFF7B828E);
  final Color _cardBorder = const Color(0xFFE4E7EB);
  final Color _ctaActiveColor = const Color(0xFF4A5568);
  final Color _ctaDisabledColor = const Color(0xFFD8DDE3);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localeInitialized) return;
    _selectedCode = 'en';
    _hasUserSelected = true;
    _localeInitialized = true;
    if (context.locale.languageCode != 'en') {
      context.setLocale(const Locale('en'));
    }
  }

  void _onContinue() {
    Navigator.pushNamed(context, '/authPhone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildLanguageCard(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 38,
          backgroundColor: _primaryColor.withOpacity(0.08),
          child: Icon(Icons.language, size: 36, color: _primaryColor),
        ),
        const SizedBox(height: 24),
        Text(
          tr('languageTitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          tr('languageSubtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildLanguageGrid(),
    );
  }

  Widget _buildLanguageGrid() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double spacing = 14;
        final double itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _languages
              .map(
                (_LanguageOption option) => SizedBox(
                  width: itemWidth,
                  child: _LanguageCard(
                    option: option,
                    selected: option.code == _selectedCode,
                    highlightColor: _primaryColor,
                    borderColor: _cardBorder,
                    onTap: () {
                      setState(() {
                        _selectedCode = option.code;
                        _hasUserSelected = true;
                      });
                      context.setLocale(Locale(option.code));
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                    _hasUserSelected ? _ctaActiveColor : _ctaDisabledColor,
                  foregroundColor:
                    _hasUserSelected ? Colors.white : Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  elevation: 0,
                ),
                onPressed: _hasUserSelected ? _onContinue : null,
                icon: const SizedBox.shrink(),
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(tr('continue')),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.selected,
    required this.highlightColor,
    required this.borderColor,
    required this.onTap,
  });

  final _LanguageOption option;
  final bool selected;
  final Color highlightColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? highlightColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? highlightColor : borderColor, width: 1.4),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                      color: highlightColor.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8)),
                ]
              : <BoxShadow>[
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 6)),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    option.nativeName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.englishName,
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: highlightColor,
              ),
          ],
        ),
      ),
    );
  }
}
