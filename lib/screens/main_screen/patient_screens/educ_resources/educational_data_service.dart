import 'package:flutter/material.dart';

class EducationalDataService {
  static Map<String, List<Map<String, dynamic>>> getEducationalTopics() {
    return {
      'Understanding Hemophilia': [
        {
          'id': 'what-is-hemophilia',
          'title': 'What is Hemophilia?',
          'description':
              'Learn the basics about hemophilia, its types, and how it affects blood clotting.',
          'readTime': 5,
          'difficulty': 'Beginner',
          'icon': 'droplet',
          'content': [
            {
              'title': 'What is Hemophilia?',
              'content':
                  'Hemophilia is a rare bleeding disorder in which the blood doesn\'t clot properly. This happens because the person doesn\'t have enough of certain blood clotting proteins, called clotting factors.',
            },
            {
              'title': 'Types of Hemophilia',
              'bulletPoints': [
                'Hemophilia A: Missing or low levels of clotting factor VIII (8)',
                'Hemophilia B: Missing or low levels of clotting factor IX (9)',
                'Hemophilia C: Missing or low levels of clotting factor XI (11) - very rare',
              ],
            },
            {
              'title': 'How Common is Hemophilia?',
              'content':
                  'Hemophilia A occurs in about 1 in 5,000 male births. Hemophilia B occurs in about 1 in 25,000 male births. The condition mainly affects males because the genes for clotting factors VIII and IX are located on the X chromosome.',
            },
            {
              'warning':
                  'Always consult with your healthcare provider for personalized medical advice. This information is for educational purposes only.',
            },
          ],
          'additionalResources': [
            {
              'type': 'video',
              'title': 'Hemophilia Explained (Animation)',
              'description':
                  'Visual explanation of how hemophilia affects blood clotting',
            },
            {
              'type': 'pdf',
              'title': 'Hemophilia Quick Facts Sheet',
              'description': 'Downloadable fact sheet about hemophilia basics',
            },
          ],
        },
        {
          'id': 'inheritance-patterns',
          'title': 'How is Hemophilia Inherited?',
          'description':
              'Understand the genetic patterns and inheritance of hemophilia.',
          'readTime': 7,
          'difficulty': 'Intermediate',
          'icon': 'heart',
          'content': [
            {
              'title': 'X-linked Inheritance',
              'content':
                  'Hemophilia A and B are X-linked recessive disorders. This means the genes are located on the X chromosome, and males are more likely to be affected because they have only one X chromosome.',
            },
            {
              'title': 'Inheritance Patterns',
              'bulletPoints': [
                'Affected father + Carrier mother: 25% chance of affected sons, 25% chance of carrier daughters',
                'Affected father + Non-carrier mother: All daughters are carriers, no affected children',
                'Non-affected father + Carrier mother: 50% chance of affected sons, 50% chance of carrier daughters',
              ],
            },
            {
              'title': 'Genetic Counseling',
              'content':
                  'Families affected by hemophilia should consider genetic counseling to understand risks and family planning options. Genetic testing can help identify carriers and affected individuals.',
            },
          ],
        },
        {
          'id': 'severity-levels',
          'title': 'Severity Levels of Hemophilia',
          'description':
              'Learn about mild, moderate, and severe hemophilia classifications.',
          'readTime': 6,
          'difficulty': 'Beginner',
          'icon': 'microscope',
          'content': [
            {
              'title': 'Classification by Factor Levels',
              'content':
                  'Hemophilia severity is classified based on the percentage of normal clotting factor activity in the blood.',
            },
            {
              'title': 'Severity Categories',
              'bulletPoints': [
                'Severe (less than 1%): Spontaneous bleeding, especially into joints and muscles',
                'Moderate (1-5%): Bleeding after mild trauma, some spontaneous bleeding',
                'Mild (5-40%): Bleeding mainly after surgery, dental procedures, or major trauma',
              ],
            },
            {
              'title': 'Clinical Implications',
              'content':
                  'The severity level helps determine treatment plans, activity restrictions, and frequency of bleeding episodes. People with severe hemophilia may need regular preventive treatment.',
            },
          ],
        },
        {
          'id': 'signs-symptoms',
          'title': 'Signs and Symptoms',
          'description':
              'Recognize the common signs and symptoms of hemophilia.',
          'readTime': 8,
          'difficulty': 'Beginner',
          'icon': 'heart',
          'content': [
            {
              'title': 'Common Bleeding Symptoms',
              'bulletPoints': [
                'Excessive bleeding after cuts, dental work, or surgery',
                'Large or deep bruises',
                'Unusual bleeding after vaccinations',
                'Nosebleeds without known cause',
                'Blood in urine or stool',
                'Tight joints and joint pain from internal bleeding',
              ],
            },
            {
              'title': 'Emergency Warning Signs',
              'content':
                  'Seek immediate medical attention if you experience severe headaches, repeated vomiting, neck pain, double vision, extreme fatigue, weakness, or difficulty walking.',
              'warning':
                  'These symptoms could indicate bleeding in the brain, which is a medical emergency.',
            },
            {
              'title': 'Joint Bleeding (Hemarthrosis)',
              'content':
                  'Joint bleeding is common in severe hemophilia. Early signs include tingling, tightness, or warmth in the joint. Prompt treatment can prevent joint damage.',
            },
          ],
        },
        {
          'id': 'diagnosis-testing',
          'title': 'Diagnosis and Testing',
          'description':
              'Learn about how hemophilia is diagnosed and monitored.',
          'readTime': 6,
          'difficulty': 'Intermediate',
          'icon': 'microscope',
          'content': [
            {
              'title': 'Initial Screening Tests',
              'bulletPoints': [
                'Complete Blood Count (CBC)',
                'Activated Partial Thromboplastin Time (aPTT)',
                'Prothrombin Time (PT)',
                'Platelet count and function',
              ],
            },
            {
              'title': 'Specific Factor Tests',
              'content':
                  'If initial tests suggest a bleeding disorder, specific factor assays are performed to measure the activity levels of factors VIII, IX, and other clotting factors.',
            },
            {
              'title': 'Genetic Testing',
              'content':
                  'Genetic testing can identify specific mutations and help with family planning. It\'s particularly useful for identifying female carriers.',
            },
          ],
        },
      ],
      'Treatment & Management': [
        {
          'id': 'factor-replacement',
          'title': 'Factor Replacement Therapy',
          'description': 'Learn about the main treatment for hemophilia.',
          'readTime': 10,
          'difficulty': 'Intermediate',
          'icon': 'syringe',
          'content': [
            {
              'title': 'What is Factor Replacement?',
              'content':
                  'Factor replacement therapy involves injecting clotting factor concentrates into a vein to temporarily replace the missing clotting factor.',
            },
            {
              'title': 'Types of Factor Products',
              'bulletPoints': [
                'Plasma-derived factors: Made from donated human blood plasma',
                'Recombinant factors: Made in laboratory using genetic engineering',
                'Extended half-life factors: Last longer in the body, requiring fewer injections',
              ],
            },
            {
              'title': 'Treatment Approaches',
              'content':
                  'Treatment can be on-demand (when bleeding occurs) or prophylactic (regular preventive infusions). Prophylaxis is recommended for people with severe hemophilia.',
            },
          ],
        },
        {
          'id': 'prophylaxis-vs-demand',
          'title': 'Prophylaxis vs On-Demand Treatment',
          'description':
              'Compare different treatment strategies for hemophilia.',
          'readTime': 8,
          'difficulty': 'Intermediate',
          'icon': 'pills',
          'content': [
            {
              'title': 'Prophylactic Treatment',
              'content':
                  'Regular infusions of clotting factor to prevent bleeding episodes. This approach helps maintain factor levels above 1% and significantly reduces spontaneous bleeding.',
              'bulletPoints': [
                'Typically given 2-3 times per week',
                'Prevents joint damage and other complications',
                'Allows for more normal activity levels',
                'Requires more frequent injections and higher costs',
              ],
            },
            {
              'title': 'On-Demand Treatment',
              'content':
                  'Treatment given only when bleeding occurs. While less expensive, it may result in more joint damage over time.',
              'bulletPoints': [
                'Treatment given at first sign of bleeding',
                'Less expensive than prophylaxis',
                'Higher risk of joint damage',
                'May limit activity participation',
              ],
            },
          ],
        },
        {
          'id': 'infusion-techniques',
          'title': 'Infusion Techniques and Safety',
          'description': 'Learn proper techniques for safe factor infusion.',
          'readTime': 12,
          'difficulty': 'Advanced',
          'icon': 'userDoctor',
          'content': [
            {
              'title': 'Preparation Steps',
              'bulletPoints': [
                'Wash hands thoroughly',
                'Check factor concentrate expiration date',
                'Allow factor to reach room temperature',
                'Prepare all supplies in clean area',
                'Mix factor concentrate according to instructions',
              ],
            },
            {
              'title': 'Infusion Process',
              'content':
                  'The infusion should be given slowly, typically over 5-10 minutes. Monitor for any adverse reactions during and after the infusion.',
            },
            {
              'warning':
                  'Always follow your healthcare team\'s specific instructions. Never share needles or infusion equipment.',
            },
          ],
        },
        {
          'id': 'alternative-treatments',
          'title': 'Alternative and Emerging Treatments',
          'description': 'Explore new treatment options for hemophilia.',
          'readTime': 9,
          'difficulty': 'Advanced',
          'icon': 'pills',
          'content': [
            {
              'title': 'Non-Factor Therapies',
              'bulletPoints': [
                'Emicizumab (Hemlibra): Mimics factor VIII function',
                'Antifibrinolytic agents: Help prevent clot breakdown',
                'Desmopressin (DDAVP): Can increase factor VIII levels in mild hemophilia A',
              ],
            },
            {
              'title': 'Gene Therapy',
              'content':
                  'Gene therapy research aims to provide a long-term or permanent treatment by introducing functional genes to produce clotting factors.',
            },
            {
              'title': 'Clinical Trials',
              'content':
                  'New treatments are constantly being developed. Ask your healthcare team about clinical trial opportunities.',
            },
          ],
        },
        {
          'id': 'treatment-complications',
          'title': 'Treatment Complications',
          'description':
              'Understand potential complications and how to manage them.',
          'readTime': 7,
          'difficulty': 'Intermediate',
          'icon': 'triangleExclamation',
          'content': [
            {
              'title': 'Inhibitor Development',
              'content':
                  'Some people develop antibodies (inhibitors) that neutralize clotting factor. This occurs in about 25-30% of people with severe hemophilia A.',
              'warning':
                  'Inhibitors make standard treatment less effective and require specialized management.',
            },
            {
              'title': 'Allergic Reactions',
              'content':
                  'Rarely, people may experience allergic reactions to factor concentrates. Signs include rash, difficulty breathing, or swelling.',
            },
            {
              'title': 'Transmission of Infections',
              'content':
                  'Modern factor concentrates are very safe, but there was historical risk of viral transmission from plasma-derived products.',
            },
          ],
        },
        {
          'id': 'medication-management',
          'title': 'Medication Management',
          'description':
              'Learn about medications to avoid and safe alternatives.',
          'readTime': 6,
          'difficulty': 'Beginner',
          'icon': 'pills',
          'content': [
            {
              'title': 'Medications to Avoid',
              'bulletPoints': [
                'Aspirin and aspirin-containing products',
                'Non-steroidal anti-inflammatory drugs (NSAIDs) like ibuprofen',
                'Blood thinners (unless specifically prescribed)',
                'Some herbal supplements that affect bleeding',
              ],
              'warning':
                  'Always check with your healthcare provider before taking any new medications or supplements.',
            },
            {
              'title': 'Safe Pain Relief Options',
              'content':
                  'Acetaminophen (paracetamol) is generally safe for people with hemophilia. For stronger pain relief, consult your healthcare team.',
            },
          ],
        },
        {
          'id': 'treatment-planning',
          'title': 'Creating Your Treatment Plan',
          'description':
              'Work with your healthcare team to develop a personalized plan.',
          'readTime': 8,
          'difficulty': 'Intermediate',
          'icon': 'notesMedical',
          'content': [
            {
              'title': 'Components of a Treatment Plan',
              'bulletPoints': [
                'Regular factor infusion schedule',
                'Emergency treatment protocols',
                'Activity guidelines and restrictions',
                'Regular monitoring and check-ups',
                'Vaccination schedules',
                'Dental care plans',
              ],
            },
            {
              'title': 'Working with Your Healthcare Team',
              'content':
                  'Your team may include hematologists, nurses, physical therapists, social workers, and genetic counselors. Regular communication is key to successful management.',
            },
          ],
        },
      ],
      'Self-Care & Monitoring': [
        {
          'id': 'daily-care-routine',
          'title': 'Daily Care Routine',
          'description':
              'Establish healthy daily habits for managing hemophilia.',
          'readTime': 6,
          'difficulty': 'Beginner',
          'icon': 'heart',
          'content': [
            {
              'title': 'Morning Routine',
              'bulletPoints': [
                'Check for any new bruises or bleeding',
                'Take any scheduled medications',
                'Plan physical activities safely',
                'Prepare factor concentrate if needed',
              ],
            },
            {
              'title': 'Evening Routine',
              'bulletPoints': [
                'Review the day for any bleeding episodes',
                'Check injection sites for complications',
                'Plan for next day\'s activities',
                'Maintain treatment diary',
              ],
            },
          ],
        },
        // Add more topics as needed...
      ],
      'Common Complications': [
        {
          'id': 'joint-bleeding',
          'title': 'Joint Bleeding (Hemarthrosis)',
          'description':
              'Learn to recognize, treat, and prevent joint bleeding.',
          'readTime': 10,
          'difficulty': 'Intermediate',
          'icon': 'triangleExclamation',
          'content': [
            {
              'title': 'What is Joint Bleeding?',
              'content':
                  'Joint bleeding occurs when blood leaks into the joint space. It\'s one of the most common and serious complications of hemophilia.',
            },
            {
              'title': 'Early Warning Signs',
              'bulletPoints': [
                'Tingling or "funny feeling" in the joint',
                'Mild pain or discomfort',
                'Stiffness or decreased range of motion',
                'Warmth around the joint',
              ],
            },
            {
              'title': 'Treatment Steps',
              'content':
                  'Early treatment is crucial. Follow the RICE protocol (Rest, Ice, Compression, Elevation) and administer factor concentrate as prescribed.',
              'warning':
                  'Never ignore early signs of joint bleeding. Early treatment prevents long-term joint damage.',
            },
          ],
        },
        // Add more complications topics...
      ],
      'For Parents and Caregivers': [
        {
          'id': 'parenting-child-hemophilia',
          'title': 'Parenting a Child with Hemophilia',
          'description': 'Essential guidance for parents and caregivers.',
          'readTime': 12,
          'difficulty': 'Beginner',
          'icon': 'baby',
          'content': [
            {
              'title': 'Creating a Safe Environment',
              'bulletPoints': [
                'Use padding on sharp furniture corners',
                'Ensure playground equipment is age-appropriate',
                'Keep first aid supplies readily available',
                'Establish clear safety rules',
              ],
            },
            {
              'title': 'Emotional Support',
              'content':
                  'Children with hemophilia may feel different from their peers. Provide emotional support while encouraging independence and normal childhood experiences.',
            },
          ],
        },
        // Add more parenting topics...
      ],
      'Emergency Instructions': [
        {
          'id': 'emergency-protocols',
          'title': 'Emergency Response Protocols',
          'description': 'Know what to do in bleeding emergencies.',
          'readTime': 8,
          'difficulty': 'Beginner',
          'icon': 'phone',
          'content': [
            {
              'title': 'When to Seek Emergency Care',
              'bulletPoints': [
                'Head injury or severe headache',
                'Trauma to neck, throat, or abdomen',
                'Severe bleeding that won\'t stop',
                'Signs of internal bleeding',
                'Loss of consciousness',
              ],
              'warning':
                  'In emergencies, call 911 immediately. Don\'t wait to give factor concentrate first.',
            },
            {
              'title': 'Emergency Kit Contents',
              'content':
                  'Always carry an emergency kit with factor concentrate, medical alert information, emergency contacts, and basic first aid supplies.',
            },
          ],
        },
        // Add more emergency topics...
      ],
      'Learning Material for all Ages': [
        {
          'id': 'games-activities',
          'title': 'Educational Games and Activities',
          'description': 'Fun ways to learn about hemophilia management.',
          'readTime': 5,
          'difficulty': 'Beginner',
          'icon': 'gamepad',
          'content': [
            {
              'title': 'Interactive Learning',
              'content':
                  'Games and activities can make learning about hemophilia more engaging for children and families.',
              'bulletPoints': [
                'Blood clotting simulation games',
                'Factor replacement practice with toys',
                'Safety scenario role-playing',
                'Treatment diary sticker charts',
              ],
            },
          ],
        },
        // Add more learning materials...
      ],
      'Official Guidelines & Resources': [
        {
          'id': 'wfh-guidelines',
          'title': 'WFH Treatment Guidelines',
          'description':
              'Official treatment guidelines from the World Federation of Hemophilia.',
          'readTime': 15,
          'difficulty': 'Advanced',
          'icon': 'globe',
          'content': [
            {
              'title': 'World Federation of Hemophilia (WFH)',
              'content':
                  'The WFH is the global hemophilia organization, representing patients with hemophilia and related bleeding disorders in over 140 countries worldwide.',
            },
            {
              'title': 'WFH Guidelines for Management of Hemophilia',
              'bulletPoints': [
                'Comprehensive care approach involving multidisciplinary teams',
                'Regular prophylaxis with factor concentrates for severe hemophilia',
                'On-demand treatment for bleeding episodes',
                'Home treatment programs for appropriate patients',
                'Regular monitoring and assessment of joint health',
                'Physical therapy and exercise recommendations',
                'Psychosocial support and counseling',
              ],
            },
            {
              'title': 'Key WFH Recommendations',
              'content':
                  'The WFH recommends prophylactic treatment starting in early childhood (before age 2-3) to prevent joint bleeding and damage. Regular comprehensive care visits every 6-12 months are essential.',
              'warning':
                  'These are general guidelines. Always follow your local healthcare provider\'s specific recommendations.',
            },
            {
              'title': 'WFH Severity Classification',
              'bulletPoints': [
                'Severe: <1% factor activity (frequent spontaneous bleeding)',
                'Moderate: 1-5% factor activity (bleeding after mild trauma)',
                'Mild: 5-40% factor activity (bleeding after major trauma/surgery)',
              ],
            },
          ],
          'additionalResources': [
            {
              'type': 'pdf',
              'title':
                  'WFH Guidelines for Management of Hemophilia (3rd Edition)',
              'description':
                  'Comprehensive treatment guidelines from WFH experts',
            },
            {
              'type': 'website',
              'title': 'WFH Official Website',
              'description': 'Visit wfh.org for latest updates and resources',
            },
          ],
        },
        {
          'id': 'national-organizations',
          'title': 'National Hemophilia Organizations',
          'description':
              'Resources from recognized national hemophilia foundations.',
          'readTime': 10,
          'difficulty': 'Beginner',
          'icon': 'flag',
          'content': [
            {
              'title': 'National Hemophilia Foundation (USA)',
              'content':
                  'The NHF is the leading organization in the U.S. dedicated to finding better treatments and cures for bleeding and clotting disorders.',
              'bulletPoints': [
                'MASAC (Medical and Scientific Advisory Council) recommendations',
                'Treatment center directory and accreditation',
                'Educational materials and webinars',
                'Research funding and advocacy',
                'Patient support programs',
              ],
            },
            {
              'title': 'Hemophilia Federation of America (HFA)',
              'content':
                  'Community-based organization providing education, advocacy, and support services.',
              'bulletPoints': [
                'Symposium educational programs',
                'Legislative advocacy initiatives',
                'Research grant programs',
                'Community support networks',
              ],
            },
            {
              'title': 'European Haemophilia Consortium (EHC)',
              'content':
                  'The EHC represents 45 national hemophilia organizations across Europe, advocating for optimal treatment and care.',
              'bulletPoints': [
                'European treatment guidelines',
                'Quality of life research',
                'Access to care initiatives',
                'Educational conferences and materials',
              ],
            },
            {
              'title': 'Other Regional Organizations',
              'bulletPoints': [
                'Hemophilia Foundation Australia',
                'Canadian Hemophilia Society',
                'Latin American Federation of Hemophilia (FLAHN)',
                'Asian Federation for Hemophilia (AFH)',
              ],
            },
          ],
        },
        {
          'id': 'clinical-guidelines',
          'title': 'International Clinical Guidelines',
          'description':
              'Evidence-based clinical practice guidelines from medical societies.',
          'readTime': 12,
          'difficulty': 'Advanced',
          'icon': 'stethoscope',
          'content': [
            {
              'title':
                  'International Society on Thrombosis and Haemostasis (ISTH)',
              'content':
                  'ISTH provides scientific guidance on bleeding and thrombotic disorders.',
              'bulletPoints': [
                'Standardized laboratory testing procedures',
                'Diagnostic criteria for bleeding disorders',
                'Treatment outcome measurement standards',
                'Research methodology guidelines',
              ],
            },
            {
              'title': 'American Society of Hematology (ASH) Guidelines',
              'bulletPoints': [
                'Evidence-based treatment recommendations',
                'Management of inhibitors',
                'Perioperative care protocols',
                'Prophylaxis versus on-demand treatment',
              ],
            },
            {
              'title': 'Nordic Hemophilia Council Guidelines',
              'content':
                  'Comprehensive Nordic guidelines for hemophilia care, widely adopted in Scandinavian countries.',
              'bulletPoints': [
                'Prophylaxis protocols by age group',
                'Physical activity recommendations',
                'Long-term joint health monitoring',
                'Home treatment programs',
              ],
            },
          ],
        },
        {
          'id': 'research-publications',
          'title': 'Key Research Publications',
          'description':
              'Important scientific studies and publications in hemophilia research.',
          'readTime': 8,
          'difficulty': 'Advanced',
          'icon': 'microscope',
          'content': [
            {
              'title': 'Landmark Studies in Hemophilia',
              'bulletPoints': [
                'Joint Outcome Study (JOS): Long-term outcomes of prophylaxis vs on-demand',
                'ESPRIT Study: Extended half-life factors efficacy',
                'HAVEN Studies: Emicizumab (Hemlibra) clinical trials',
                'Gene therapy trials: AAV-based gene transfer studies',
              ],
            },
            {
              'title': 'Key Journals for Hemophilia Research',
              'bulletPoints': [
                'Haemophilia (Wiley) - Official journal of WFH',
                'Blood (American Society of Hematology)',
                'Journal of Thrombosis and Haemostasis',
                'Thrombosis Research',
                'Blood Coagulation & Fibrinolysis',
              ],
            },
            {
              'title': 'Recent Breakthrough Research',
              'content':
                  'Recent advances include gene therapy achieving sustained factor levels, novel non-factor therapies, and improved prophylaxis protocols.',
            },
          ],
        },
        {
          'id': 'quality-life-measures',
          'title': 'Quality of Life Assessment Tools',
          'description':
              'Standardized tools used by healthcare providers to assess patient outcomes.',
          'readTime': 7,
          'difficulty': 'Intermediate',
          'icon': 'chartLine',
          'content': [
            {
              'title': 'WFH-Validated Assessment Tools',
              'bulletPoints': [
                'Hemophilia Joint Health Score (HJHS) - Version 2.1',
                'Gilbert Score - Joint assessment for adults',
                'Hemophilia Activities List (HAL) - Functional assessment',
                'Canadian Hemophilia Outcome - Kids Life Assessment Tool (CHO-KLAT)',
              ],
            },
            {
              'title': 'Quality of Life Questionnaires',
              'bulletPoints': [
                'Haemo-QoL (Hemophilia Quality of Life questionnaire)',
                'EQ-5D (European Quality of Life instrument)',
                'SF-36 (Short Form Health Survey)',
                'VERITAS-Pro/VERITAS-PRN (Treatment adherence scales)',
              ],
            },
            {
              'title': 'Patient-Reported Outcomes',
              'content':
                  'These tools help healthcare providers understand the real-world impact of hemophilia and treatment effectiveness from the patient\'s perspective.',
            },
          ],
        },
        {
          'id': 'international-standards',
          'title': 'International Treatment Standards',
          'description':
              'Global standards for hemophilia care and treatment quality.',
          'readTime': 9,
          'difficulty': 'Advanced',
          'icon': 'award',
          'content': [
            {
              'title': 'WFH Global Standards',
              'bulletPoints': [
                'Comprehensive care model with multidisciplinary teams',
                'Access to safe clotting factor concentrates',
                'Regular monitoring and assessment protocols',
                'Patient and family education programs',
                'Psychosocial support services',
                'Emergency care protocols',
              ],
            },
            {
              'title': 'Treatment Center Accreditation',
              'content':
                  'Many countries have accreditation programs for hemophilia treatment centers to ensure quality of care standards.',
              'bulletPoints': [
                'Minimum staffing requirements (hematologist, nurse, social worker)',
                'Comprehensive care service requirements',
                'Data collection and outcome tracking',
                'Patient education and support services',
                'Research and clinical trial participation',
              ],
            },
            {
              'title': 'International Collaboration',
              'content':
                  'Global initiatives include the WFH Humanitarian Aid Program, providing factor concentrates and training to developing countries.',
            },
          ],
        },
      ],
    };
  }

  static List<Map<String, dynamic>> getCategoryData() {
    return [
      {
        'title': 'Understanding Hemophilia',
        'icon': 'dna',
        'color': 'deepPurple',
        'subtitle': '5 Topics',
      },
      {
        'title': 'Treatment & Management',
        'icon': 'syringe',
        'color': 'green',
        'subtitle': '7 Topics',
      },
      {
        'title': 'Self-Care & Monitoring',
        'icon': 'notesMedical',
        'color': 'blueAccent',
        'subtitle': '15 Topics',
      },
      {
        'title': 'Common Complications',
        'icon': 'triangleExclamation',
        'color': 'redAccent',
        'subtitle': '10 Topics',
      },
      {
        'title': 'For Parents and Caregivers',
        'icon': 'users',
        'color': 'orangeAccent',
        'subtitle': '10 Topics',
      },
      {
        'title': 'Emergency Instructions',
        'icon': 'truckMedical',
        'color': 'pinkAccent',
        'subtitle': '10 Topics',
      },
      {
        'title': 'Learning Material for all Ages',
        'icon': 'bookOpenReader',
        'color': 'yellow',
        'subtitle': '10 Topics',
      },
      {
        'title': 'Official Guidelines & Resources',
        'icon': 'certificateMedical',
        'color': 'teal',
        'subtitle': '6 Topics',
      },
    ];
  }

  static Color getColorFromString(String colorName) {
    switch (colorName) {
      case 'deepPurple':
        return Colors.deepPurple;
      case 'green':
        return Colors.green;
      case 'blueAccent':
        return Colors.blueAccent;
      case 'redAccent':
        return Colors.redAccent;
      case 'orangeAccent':
        return Colors.orangeAccent;
      case 'pinkAccent':
        return Colors.pinkAccent;
      case 'yellow':
        return Colors
            .amber; // Using amber instead of yellow for better visibility
      case 'teal':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}
