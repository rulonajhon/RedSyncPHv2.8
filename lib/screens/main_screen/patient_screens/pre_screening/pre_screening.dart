import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PreScreeningScreen extends StatefulWidget {
  const PreScreeningScreen({super.key});

  @override
  State<PreScreeningScreen> createState() => _PreScreeningScreenState();
}

class _PreScreeningScreenState extends State<PreScreeningScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _totalScore = 0;

  final Map<String, dynamic> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'gender',
      'title': 'Personal Information',
      'question': 'What is your gender?',
      'type': 'single_choice',
      'options': [
        {'text': 'Male', 'score': 0},
        {'text': 'Female', 'score': 0},
        {'text': 'Other', 'score': 0},
      ],
    },
    {
      'id': 'nosebleeds',
      'title': 'Nosebleeds (Epistaxis)',
      'question': 'What best describes your experience with nosebleeds?',
      'type': 'single_choice',
      'options': [
        {'text': 'None or trivial', 'score': 0},
        {'text': 'More than 5 per year or >10 minutes each', 'score': 1},
        {'text': 'Required medical consultation', 'score': 2},
        {
          'text': 'Needed packing, cauterization, or prescribed medication',
          'score': 3,
        },
        {'text': 'Required transfusion or clotting therapy', 'score': 4},
      ],
    },
    {
      'id': 'bruising',
      'title': 'Bruising (Cutaneous Bleeding)',
      'question': 'What best describes your bruising pattern?',
      'type': 'single_choice',
      'options': [
        {'text': 'None or trivial', 'score': 0},
        {'text': '≥5 bruises >1 cm on exposed areas', 'score': 1},
        {'text': 'Bleeding that led to medical consultation', 'score': 2},
        {'text': 'Extensive spontaneous bruising', 'score': 3},
        {'text': 'Spontaneous bruising requiring transfusion', 'score': 4},
      ],
    },
    {
      'id': 'minor_wounds',
      'title': 'Bleeding from Minor Wounds',
      'question': 'How do minor cuts or scrapes typically heal for you?',
      'type': 'single_choice',
      'options': [
        {'text': 'None or trivial bleeding', 'score': 0},
        {
          'text':
              'Bleeding from small cuts requiring more than 10 minutes to stop',
          'score': 1,
        },
        {'text': 'Bleeding leading to a medical visit', 'score': 2},
        {'text': 'Persistent bleeding >30 minutes', 'score': 3},
        {'text': 'Required transfusion or clotting therapy', 'score': 4},
      ],
    },
    {
      'id': 'oral_bleeding',
      'title': 'Oral Bleeding',
      'question': 'Have you experienced bleeding from your mouth or gums?',
      'type': 'single_choice',
      'options': [
        {'text': 'None', 'score': 0},
        {
          'text':
              'Bleeding gums lasting >10 minutes or blood in saliva more than once',
          'score': 1,
        },
        {'text': 'Needed dental care', 'score': 2},
        {'text': 'Required medical consultation or extended care', 'score': 3},
        {'text': 'Needed transfusions or clotting therapy', 'score': 4},
      ],
    },
    {
      'id': 'gastrointestinal',
      'title': 'Gastrointestinal Bleeding',
      'question':
          'Have you experienced gastrointestinal bleeding (stomach/intestinal)?',
      'type': 'single_choice',
      'options': [
        {'text': 'None', 'score': 0},
        {
          'text': 'Minor (e.g., black stools or vomiting blood once)',
          'score': 1,
        },
        {'text': 'Required outpatient evaluation', 'score': 2},
        {'text': 'Hospitalization', 'score': 3},
        {'text': 'Required transfusion or therapy', 'score': 4},
      ],
    },
    {
      'id': 'hematuria',
      'title': 'Hematuria (Urine Bleeding)',
      'question': 'Have you had blood in your urine?',
      'type': 'single_choice',
      'options': [
        {'text': 'None', 'score': 0},
        {'text': 'Visible blood in urine', 'score': 1},
        {'text': 'Medical evaluation required', 'score': 2},
        {'text': 'Hospitalized', 'score': 3},
        {'text': 'Required transfusion or therapy', 'score': 4},
      ],
    },
    {
      'id': 'tooth_extraction',
      'title': 'Bleeding After Tooth Extraction',
      'question': 'If you\'ve had teeth extracted, how was the bleeding?',
      'type': 'single_choice',
      'options': [
        {'text': 'Normal healing or no extractions', 'score': 0},
        {'text': 'Bleeding that lasted >30 minutes or re-bled', 'score': 1},
        {'text': 'Returned to dentist or medical facility', 'score': 2},
        {'text': 'Needed medical intervention', 'score': 3},
        {'text': 'Required transfusion or therapy', 'score': 4},
      ],
    },
    {
      'id': 'surgical_trauma',
      'title': 'Surgical/Major Trauma Bleeding',
      'question': 'How was bleeding during surgery or major trauma?',
      'type': 'single_choice',
      'options': [
        {'text': 'Normal surgical bleeding or no surgeries', 'score': 0},
        {'text': 'Excess bleeding requiring intervention', 'score': 1},
        {'text': 'Needed transfusion or extended care', 'score': 2},
        {'text': 'Hospitalization >1 day for bleeding', 'score': 3},
        {'text': 'Required transfusion or clotting therapy', 'score': 4},
      ],
    },
    {
      'id': 'menorrhagia',
      'title': 'Menorrhagia (Heavy Menstrual Bleeding)',
      'question':
          'How would you describe your menstrual bleeding? (Women only)',
      'type': 'single_choice',
      'options': [
        {'text': 'Normal bleeding or N/A (male)', 'score': 0},
        {'text': 'Heavy but manageable', 'score': 1},
        {'text': 'Needed treatment (e.g., iron, medications)', 'score': 2},
        {
          'text': 'Required medical/surgical intervention (e.g., ablation)',
          'score': 3,
        },
        {'text': 'Needed transfusion', 'score': 4},
      ],
    },
    {
      'id': 'postpartum',
      'title': 'Postpartum Hemorrhage',
      'question':
          'If you\'ve given birth, how was bleeding after delivery? (Women only)',
      'type': 'single_choice',
      'options': [
        {'text': 'None or N/A (male/no births)', 'score': 0},
        {'text': 'Bleeding requiring medications', 'score': 1},
        {'text': 'Needed surgical control', 'score': 2},
        {'text': 'Hospitalized for bleeding', 'score': 3},
        {'text': 'Required transfusion or therapy', 'score': 4},
      ],
    },
    {
      'id': 'muscle_hematomas',
      'title': 'Muscle Hematomas',
      'question': 'Have you experienced deep muscle bleeding or hematomas?',
      'type': 'single_choice',
      'options': [
        {'text': 'None', 'score': 0},
        {'text': 'Minor bruising/swelling', 'score': 1},
        {'text': 'Medical evaluation required', 'score': 2},
        {'text': 'Hospitalization for hematoma', 'score': 3},
        {'text': 'Required transfusion or therapy', 'score': 4},
      ],
    },
    {
      'id': 'joint_bleeds',
      'title': 'Joint Bleeds (Hemarthrosis)',
      'question': 'Have you experienced bleeding into joints?',
      'type': 'single_choice',
      'options': [
        {'text': 'None', 'score': 0},
        {'text': 'Joint pain/swelling once', 'score': 1},
        {'text': 'Required medical care', 'score': 2},
        {'text': 'Hospitalization due to bleeding', 'score': 3},
        {'text': 'Required transfusion or therapy', 'score': 4},
      ],
    },
    {
      'id': 'cns_bleeding',
      'title': 'Central Nervous System Bleeding',
      'question':
          'Have you experienced any brain or central nervous system bleeding?',
      'type': 'single_choice',
      'options': [
        {'text': 'None', 'score': 0},
        {'text': 'Serious bleeding like intracranial hemorrhage', 'score': 3},
        {'text': 'Such bleeding required therapy or transfusion', 'score': 4},
      ],
    },
    {
      'id': 'other_bleeding',
      'title': 'Other Bleeding Issues',
      'question':
          'Have you had bleeding after vaccinations or minor procedures?',
      'type': 'single_choice',
      'options': [
        {'text': 'None or trivial', 'score': 0},
        {'text': 'Mild bleeding requiring attention', 'score': 1},
        {'text': 'Required medical evaluation', 'score': 2},
        {'text': 'Needed extended care or intervention', 'score': 3},
        {'text': 'Required transfusion or clotting therapy', 'score': 4},
      ],
    },
  ];

  void _nextPage() {
    if (_currentPage < _questions.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectAnswer(String questionId, dynamic answer, int score) {
    setState(() {
      _answers[questionId] = answer;

      // Auto-fill gender-specific questions for males
      if (questionId == 'gender' && answer['text'] == 'Male') {
        // Auto-select N/A for menstrual and postpartum questions
        final menorrhagiaOption = _questions.firstWhere(
          (q) => q['id'] == 'menorrhagia',
        )['options'][0];
        final postpartumOption = _questions.firstWhere(
          (q) => q['id'] == 'postpartum',
        )['options'][0];

        _answers['menorrhagia'] = menorrhagiaOption;
        _answers['postpartum'] = postpartumOption;
      }

      // Recalculate total score
      _calculateScore();
    });
  }

  void _calculateScore() {
    _totalScore = 0;
    for (var question in _questions) {
      final answer = _answers[question['id']];
      if (answer != null) {
        if (question['type'] == 'multiple_choice') {
          for (var selectedOption in answer) {
            _totalScore += selectedOption['score'] as int;
          }
        } else {
          _totalScore += answer['score'] as int;
        }
      }
    }
  }

  void _showResults() {
    // Get gender for scoring threshold
    String selectedGender = 'Male'; // Default
    final genderAnswer = _answers['gender'];
    if (genderAnswer != null) {
      selectedGender = genderAnswer['text'];
    }

    // Determine threshold based on gender
    int abnormalThreshold = selectedGender == 'Female' ? 6 : 4;

    String riskLevel;
    String recommendation;
    Color resultColor;
    String thresholdInfo =
        'Abnormal threshold: ≥$abnormalThreshold for ${selectedGender.toLowerCase()}s';

    if (_totalScore < abnormalThreshold) {
      riskLevel = 'Normal Range';
      recommendation =
          'Your ISTH-BAT score is within the normal range. However, if you have ongoing bleeding concerns, please consult with a healthcare provider for proper evaluation.';
      resultColor = Colors.green;
    } else if (_totalScore < abnormalThreshold + 5) {
      riskLevel = 'Abnormal - Moderate Risk';
      recommendation =
          'Your score suggests possible bleeding disorder concerns. We recommend consulting with a hematologist or healthcare provider for comprehensive evaluation and appropriate testing.';
      resultColor = Colors.orange;
    } else {
      riskLevel = 'Abnormal - High Risk';
      recommendation =
          'Your score indicates significant bleeding concerns that warrant immediate medical evaluation. Please consult with a hematologist as soon as possible for comprehensive assessment and management.';
      resultColor = Colors.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.assessment, color: resultColor, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('ISTH-BAT Results', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: resultColor.withOpacity(0.3)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Result: $riskLevel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: resultColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: $_totalScore/56',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: resultColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          thresholdInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: resultColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recommendation:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(recommendation, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ISTH-BAT:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The International Society on Thrombosis and Haemostasis Bleeding Assessment Tool (ISTH-BAT) is a standardized questionnaire used to evaluate bleeding symptoms. This is a screening tool only and not a diagnostic test.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Finish'),
          ),
          if (_totalScore >= abnormalThreshold)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Account'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ISTH-BAT Screening',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Question ${_currentPage + 1} of ${_questions.length}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / _questions.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),

            // Questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return _buildQuestionPage(question);
                },
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _answers.containsKey(_questions[_currentPage]['id'])
                          ? (_currentPage == _questions.length - 1
                                ? _showResults
                                : _nextPage)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _questions.length - 1
                            ? 'Show Results'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> question) {
    String? selectedGender = _answers['gender']?['text'];
    bool isGenderSpecific =
        question['id'] == 'menorrhagia' || question['id'] == 'postpartum';
    bool showGenderNote = isGenderSpecific && selectedGender != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getQuestionIcon(question['id']),
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question['question'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                if (showGenderNote && selectedGender == 'Male') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This question is automatically set to N/A for males.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildAnswerOptions(question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(Map<String, dynamic> question) {
    // For gender-specific questions, show only relevant options
    List<dynamic> options = question['options'];
    String? selectedGender = _answers['gender']?['text'];

    // Filter options for gender-specific questions
    if (question['id'] == 'menorrhagia' || question['id'] == 'postpartum') {
      if (selectedGender == 'Male') {
        // For males, only show N/A option
        options = [options[0]]; // "Normal bleeding or N/A" option
      }
    }

    if (question['type'] == 'single_choice') {
      return Column(
        children: options.map<Widget>((option) {
          final isSelected = _answers[question['id']] == option;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () =>
                  _selectAnswer(question['id'], option, option['score']),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade300
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option['text'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // Multiple choice (kept from original code, though not used in ISTH-BAT)
      final selectedOptions = _answers[question['id']] as List? ?? [];
      return Column(
        children: question['options'].map<Widget>((option) {
          final isSelected = selectedOptions.contains(option);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                List newSelection = List.from(selectedOptions);
                if (option['text'] == 'None of the above') {
                  newSelection = [option];
                } else {
                  newSelection.removeWhere(
                    (item) => item['text'] == 'None of the above',
                  );
                  if (isSelected) {
                    newSelection.remove(option);
                  } else {
                    newSelection.add(option);
                  }
                }
                _selectAnswer(question['id'], newSelection, 0);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade300
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option['text'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  IconData _getQuestionIcon(String questionId) {
    switch (questionId) {
      case 'gender':
        return Icons.wc;
      case 'nosebleeds':
        return Icons.face;
      case 'bruising':
        return Icons.healing;
      case 'minor_wounds':
        return FontAwesomeIcons.bandage;
      case 'oral_bleeding':
        return Icons.face_outlined;
      case 'gastrointestinal':
        return Icons.local_hospital;
      case 'hematuria':
        return FontAwesomeIcons.droplet;
      case 'tooth_extraction':
        return FontAwesomeIcons.tooth;
      case 'surgical_trauma':
        return FontAwesomeIcons.userDoctor;
      case 'menorrhagia':
        return FontAwesomeIcons.venus;
      case 'postpartum':
        return FontAwesomeIcons.baby;
      case 'muscle_hematomas':
        return FontAwesomeIcons.dumbbell;
      case 'joint_bleeds':
        return FontAwesomeIcons.bone;
      case 'cns_bleeding':
        return FontAwesomeIcons.brain;
      case 'other_bleeding':
        return FontAwesomeIcons.syringe;
      default:
        return Icons.help_outline;
    }
  }
}
