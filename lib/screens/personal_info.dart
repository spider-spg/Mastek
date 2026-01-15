import 'package:flutter/material.dart';
import '../utils/bmi.dart';

const Color _primaryColor = Color(0xFF1F2A3D);
const Color _mutedText = Color(0xFF5E6A7D);
const Color _cardBorder = Color(0xFFE4E7EB);

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  late final TextEditingController _existingOtherController;
  late final TextEditingController _familyOtherController;

  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  double _bmi = 0;
  String _bmiLabel = '--';

  final Set<String> _existingDiseases = <String>{};
  final Set<String> _familyHistory = <String>{};
  String _existingOther = '';
  String _familyOther = '';
  String _gender = '';

  void _goToChat() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/chat',
      (Route<dynamic> route) => false,
    );
  }

  void _saveToCache() {
    final _HealthInfoCache cache = _HealthInfoCache.instance;
    cache
      ..heightText = _heightController.text
      ..weightText = _weightController.text
      ..ageText = _ageController.text
      ..heightUnit = _heightUnit
      ..weightUnit = _weightUnit
      ..gender = _gender
      ..existingDiseases = Set<String>.from(_existingDiseases)
      ..familyHistory = Set<String>.from(_familyHistory)
      ..existingOther = _existingOther
      ..familyOther = _familyOther;
  }

  void _saveAndGo() {
    _saveToCache();
    _goToChat();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _existingOtherController.dispose();
    _familyOtherController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _existingOtherController = TextEditingController(text: _existingOther);
    _familyOtherController = TextEditingController(text: _familyOther);
    _loadFromCache();
  }

  void _loadFromCache() {
    final _HealthInfoCache cache = _HealthInfoCache.instance;
    _heightUnit = cache.heightUnit;
    _weightUnit = cache.weightUnit;
    _gender = cache.gender;
    _heightController.text = cache.heightText;
    _weightController.text = cache.weightText;
    _ageController.text = cache.ageText;
    _existingDiseases
      ..clear()
      ..addAll(cache.existingDiseases);
    _familyHistory
      ..clear()
      ..addAll(cache.familyHistory);
    _existingOther = cache.existingOther;
    _familyOther = cache.familyOther;
    _existingOtherController.text = _existingOther;
    _familyOtherController.text = _familyOther;
    if (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty) {
      _updateBmi();
    }
    setState(() {});
  }

  void _updateBmi() {
    final double? rawHeight = double.tryParse(_heightController.text);
    final double? rawWeight = double.tryParse(_weightController.text);
    if (rawHeight == null ||
        rawWeight == null ||
        rawHeight <= 0 ||
        rawWeight <= 0) {
      setState(() {
        _bmi = 0;
        _bmiLabel = '--';
      });
      return;
    }

    double heightCm = rawHeight;
    double weightKg = rawWeight;

    if (_heightUnit == 'ft') {
      heightCm = rawHeight * 30.48;
    }
    if (_weightUnit == 'lb') {
      weightKg = rawWeight * 0.453592;
    }

    final double bmi = calculateBmi(weightKg: weightKg, heightCm: heightCm);

    setState(() {
      _bmi = bmi;
      _bmiLabel = _bmiCategory(bmi);
    });
  }

  String _bmiCategory(double bmi) {
    if (bmi <= 0) return '--';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  void _toggleSelection(Set<String> target, String value,
      {bool hasNone = true}) {
    setState(() {
      if (hasNone && value == 'None') {
        target
          ..clear()
          ..add('None');
      } else {
        target.remove('None');
        if (target.contains(value)) {
          target.remove(value);
        } else {
          target.add(value);
        }
      }

      if (!target.contains('Other')) {
        if (identical(target, _existingDiseases)) {
          _existingOther = '';
          _existingOtherController.clear();
        } else if (identical(target, _familyHistory)) {
          _familyOther = '';
          _familyOtherController.clear();
        }
      }
    });
  }

  void _setOther(Set<String> target, String value, bool isExisting) {
    setState(() {
      target.add('Other');
      if (isExisting) {
        _existingOther = value;
        _existingOtherController.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      } else {
        _familyOther = value;
        _familyOtherController.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 4),
              const Text(
                'Health Information',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor),
              ),
              const SizedBox(height: 20),
              _sectionCard(
                icon: Icons.straighten,
                title: 'Height & Weight',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _fieldWithUnit(
                      label: 'Height',
                      controller: _heightController,
                      unit: _heightUnit,
                      units: const <String>['cm', 'ft'],
                      onUnitChanged: (String val) {
                        setState(() => _heightUnit = val);
                        _updateBmi();
                      },
                      onChanged: (_) => _updateBmi(),
                    ),
                    const SizedBox(height: 18),
                    _fieldWithUnit(
                      label: 'Weight',
                      controller: _weightController,
                      unit: _weightUnit,
                      units: const <String>['kg', 'lb'],
                      onUnitChanged: (String val) {
                        setState(() => _weightUnit = val);
                        _updateBmi();
                      },
                      onChanged: (_) => _updateBmi(),
                    ),
                    const SizedBox(height: 18),
                    _bmiTile(),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _sectionCard(
                icon: Icons.badge_outlined,
                title: 'Basic Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Age',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration().copyWith(
                        hintText: 'Enter your age',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gender',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor),
                    ),
                    const SizedBox(height: 10),
                    _singleSelectOptions(
                      options: const <String>['Male', 'Female', 'Other'],
                      selectedValue: _gender,
                      onSelected: (String val) {
                        setState(() => _gender = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _sectionCard(
                icon: Icons.favorite_border,
                title: 'Existing Diseases',
                child: _optionGrid(
                  options: const <String>[
                    'Asthma',
                    'Diabetes',
                    'High Blood Pressure',
                    'Other',
                    'None'
                  ],
                  selected: _existingDiseases,
                  onTap: (String val) =>
                      _toggleSelection(_existingDiseases, val),
                  otherField: _buildOtherField(
                    label: 'Specify other disease',
                    controller: _existingOtherController,
                    onChanged: (String v) =>
                        _setOther(_existingDiseases, v, true),
                    visible: _existingDiseases.contains('Other'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _sectionCard(
                icon: Icons.group_outlined,
                title: 'Family Medical History',
                child: _optionGrid(
                  options: const <String>[
                    'Diabetes',
                    'Heart Disease',
                    'High Blood Pressure',
                    'Other',
                    'None'
                  ],
                  selected: _familyHistory,
                  onTap: (String val) => _toggleSelection(_familyHistory, val),
                  otherField: _buildOtherField(
                    label: 'Specify other family history',
                    controller: _familyOtherController,
                    onChanged: (String v) =>
                        _setOther(_familyHistory, v, false),
                    visible: _familyHistory.contains('Other'),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _bottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 24, color: _primaryColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _fieldWithUnit({
    required String label,
    required TextEditingController controller,
    required String unit,
    required List<String> units,
    required ValueChanged<String> onUnitChanged,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _primaryColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: onChanged,
                decoration: _inputDecoration(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _cardBorder),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unit,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: units
                        .map((String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                    onChanged: (String? val) {
                      if (val != null) onUnitChanged(val);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: _primaryColor.withOpacity(0.9), width: 1.6),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _bmiTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.balance_outlined, color: _primaryColor),
              SizedBox(width: 10),
              Text('Your BMI',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _bmi == 0 ? '--' : _bmi.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor),
              ),
              Text(
                _bmiLabel,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _singleSelectOptions({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double spacing = 12;
        final double itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options
              .map(
                (String option) => SizedBox(
                  width: itemWidth,
                  child: _OptionTile(
                    label: option,
                    selected: selectedValue == option,
                    onTap: () => onSelected(option),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _optionGrid({
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onTap,
    Widget? otherField,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double spacing = 12;
        final double itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            ...options
                .map(
                  (String option) => SizedBox(
                    width: itemWidth,
                    child: _OptionTile(
                      label: option,
                      selected: selected.contains(option),
                      onTap: () => onTap(option),
                    ),
                  ),
                )
                .toList(),
            if (otherField != null && selected.contains('Other'))
              SizedBox(
                width: constraints.maxWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: otherField,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOtherField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: _primaryColor),
        ),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChanged,
          controller: controller,
          decoration: _inputDecoration().copyWith(hintText: 'Enter here'),
        ),
      ],
    );
  }

  Widget _bottomButtons() {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: _goToChat,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: _cardBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor),
              foregroundColor: _primaryColor,
            ),
            child: const Text('Skip for now'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveAndGo,
            icon: const SizedBox.shrink(),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Text('Save'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _primaryColor : _cardBorder, width: 1.2),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? _primaryColor : _mutedText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? _primaryColor : _primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthInfoCache {
  _HealthInfoCache._();

  static final _HealthInfoCache instance = _HealthInfoCache._();

  String heightText = '';
  String weightText = '';
  String ageText = '';
  String heightUnit = 'cm';
  String weightUnit = 'kg';
  String gender = '';
  Set<String> existingDiseases = <String>{};
  Set<String> familyHistory = <String>{};
  String existingOther = '';
  String familyOther = '';
}
