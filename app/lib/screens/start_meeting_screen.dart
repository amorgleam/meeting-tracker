import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';

class StartMeetingScreen extends StatefulWidget {
  const StartMeetingScreen({super.key});

  @override
  State<StartMeetingScreen> createState() => _StartMeetingScreenState();
}

class _StartMeetingScreenState extends State<StartMeetingScreen> {
  DateTime _selectedDate = DateTime.now();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final Set<String> _selectedAttendeeIds = {};

  @override
  void initState() {
    super.initState();
    // Default to all active members selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final members = context.read<AppState>().members;
      setState(() {
        _selectedAttendeeIds.addAll(members.where((m) => m.isActive).map((m) => m.id));
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: InstitutionalTheme.primaryNavy,
              onPrimary: Colors.white,
              surface: InstitutionalTheme.creamCard,
              onSurface: InstitutionalTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final members = appState.members.where((m) => m.isActive).toList();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 780),
          decoration: BoxDecoration(
            color: InstitutionalTheme.creamCard,
            border: Border.all(color: InstitutionalTheme.borderLedger, width: 1.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Institutional Header Ribbon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: InstitutionalTheme.primaryNavy,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x33B8923A),
                        border: Border.all(color: InstitutionalTheme.goldAccent, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(Icons.event_note, color: InstitutionalTheme.goldAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONVENE FORMAL INSTITUTIONAL SESSION',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: InstitutionalTheme.creamBackground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Official Record of Meeting Proceedings and Docket Management',
                          style: TextStyle(
                            fontSize: 12,
                            color: InstitutionalTheme.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // REQUIREMENT 1: "select the meeting date first (title and attendees optional)"
                    const Text(
                      'STEP 1: MANDATORY MEETING DATE SELECTION',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: InstitutionalTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'All carried-forward items from earlier sessions will be anchored to this date.',
                      style: TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _pickDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: InstitutionalTheme.creamSurface,
                          border: Border.all(color: InstitutionalTheme.goldAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: InstitutionalTheme.primaryNavy, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SELECTED CONVOCATION DATE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: InstitutionalTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateFormat.format(_selectedDate),
                                    style: const TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: InstitutionalTheme.primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: InstitutionalTheme.primaryNavy,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'CHANGE DATE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 24),

                    // STEP 2: Optional Title
                    const Text(
                      'STEP 2: SESSION TITLE (OPTIONAL)',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: InstitutionalTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Regular Session of the Executive Committee, Annual Statutory Review...',
                        prefixIcon: Icon(Icons.edit_note, color: InstitutionalTheme.primaryNavy),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 24),

                    // STEP 3: Optional Attendees
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'STEP 3: ATTENDING MEMBERS (OPTIONAL)',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: InstitutionalTheme.primaryNavy,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedAttendeeIds.addAll(members.map((m) => m.id));
                                });
                              },
                              child: const Text('SELECT ALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedAttendeeIds.clear();
                                });
                              },
                              child: const Text('CLEAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: InstitutionalTheme.borderLedger),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: members.map((member) {
                          final isSelected = _selectedAttendeeIds.contains(member.id);
                          return FilterChip(
                            label: Text('${member.name} (${member.designation})'),
                            selected: isSelected,
                            selectedColor: const Color(0x33B8923A),
                            checkmarkColor: InstitutionalTheme.primaryNavy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                              side: BorderSide(
                                color: isSelected ? InstitutionalTheme.goldAccent : InstitutionalTheme.borderLedger,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? InstitutionalTheme.primaryNavy : InstitutionalTheme.textDark,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAttendeeIds.add(member.id);
                                } else {
                                  _selectedAttendeeIds.remove(member.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: InstitutionalTheme.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: () {
                          appState.startMeeting(
                            _selectedDate,
                            title: _titleController.text.trim(),
                            attendeeIds: _selectedAttendeeIds.toList(),
                          );
                        },
                        icon: const Icon(Icons.gavel, color: InstitutionalTheme.goldAccent, size: 20),
                        label: const Text(
                          'CONVENE MEETING & OPEN DOCKET',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
