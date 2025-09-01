import 'package:flutter/material.dart';

class LogBleed extends StatelessWidget {
  const LogBleed({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new working implementation
    return const LogBleedNew();
  }
}

// Export the new implementation
class LogBleedNew extends StatefulWidget {
  const LogBleedNew({super.key});

  @override
  State<LogBleedNew> createState() => _LogBleedNewState();
}

class _LogBleedNewState extends State<LogBleedNew> {
  @override
  Widget build(BuildContext context) {
    // Import the actual implementation from log_bleed_new.dart
    return const LogBleed();
  }
}
