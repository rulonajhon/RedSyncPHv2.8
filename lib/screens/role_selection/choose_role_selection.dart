// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class ChooseRoleSelection extends StatefulWidget {
//   const ChooseRoleSelection({super.key});

//   @override
//   State<ChooseRoleSelection> createState() => _ChooseRoleSelectionState();
// }

// class _ChooseRoleSelectionState extends State<ChooseRoleSelection> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [

//               Text(
//                 'What type of account do you want to create?',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               SizedBox(height: 24),
//               Expanded(
//                 child: ListView(
//                   physics: NeverScrollableScrollPhysics(),
//                   children: [
//                     AccountList(
//                       listIcon: FontAwesomeIcons.person,
//                       listTitle: 'I\'m a Patient',
//                       listSubtitle: 'I want to track my own health',
//                       color: Colors.redAccent,
//                       onTap: () {
//                         Navigator.pushReplacementNamed(context, '/user_screen');
//                       },
//                     ),
//                     SizedBox(height: 12),
//                     AccountList(
//                       listIcon: FontAwesomeIcons.personBreastfeeding,
//                       listTitle: 'I\'m a Caregiver',
//                       listSubtitle: 'I want to track someone else\'s health',
//                       color: Colors.orangeAccent,
//                       onTap: () {
//                         // Navigations
//                       },
//                     ),
//                     SizedBox(height: 12),
//                     AccountList(
//                       listIcon: FontAwesomeIcons.userDoctor,
//                       listTitle: 'I\'m a Medical Professional',
//                       listSubtitle: 'I want to track patients who have hemophilia',
//                       color: Colors.blueAccent,
//                       onTap: () {
//                         Navigator.pushReplacementNamed(context, '/healthcare_main');
                        
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class AccountList extends StatelessWidget {
//   final String listTitle;
//   final String listSubtitle;
//   final IconData listIcon;
//   final VoidCallback onTap;
//   final Color color;

//   const AccountList({
//     super.key,
//     required this.listTitle,
//     required this.listIcon,
//     required this.listSubtitle,
//     required this.onTap,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       // ignore: deprecated_member_use
//       tileColor: color.withOpacity(0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       leading: Icon(listIcon, size: 32, color: color),
//       title: Text(
//         listTitle,
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           color: color,
//           fontSize: 17,
//         ),
//       ),
//       subtitle: Text(
//         listSubtitle,
//         style: TextStyle(
//           color: Colors.black87,
//           fontSize: 14,
//         ),
//       ),
//       trailing: Icon(Icons.arrow_forward_ios, color: color, size: 20),
//       onTap: onTap,
//     );
//   }
// }


// // TODO: Change to apprpriate Colors