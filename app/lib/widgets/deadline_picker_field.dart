import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';

class DeadlinePickerField extends StatefulWidget {
  final DateTime initiateDate;
  final DateTime? initialDeadline;
  final ValueChanged<DateTime?> onDeadlineChanged;

  const DeadlinePickerField({
    super.key,
    required this.initiateDate,
    this.initialDeadline,
    required this.onDeadlineChanged,
  });

  @override
  State<DeadlinePickerField> createState() => _DeadlinePickerFieldState();
}

class _DeadlinePickerFieldState extends State<DeadlinePickerField> {
  DateTime? _deadline;
  final TextEditingController _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deadline = widget.initialDeadline;
    if (_deadline != null) {
      final days = _deadline!.difference(widget.initiateDate).inDays;
      if (days >= 0) {
        _daysController.text = days.toString();
      }
    }
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _setDeadlineFromDays(int days) {
    final newDeadline = widget.initiateDate.add(Duration(days: days));
    setState(() {
      _deadline = newDeadline;
      _daysController.text = days.toString();
    });
    widget.onDeadlineChanged(newDeadline);
  }

  Future<void> _pickDateFromCalendar() async {
    final now = DateTime.now();
    final firstDate = widget.initiateDate.isBefore(now) ? widget.initiateDate : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? widget.initiateDate.add(const Duration(days: 7)),
      firstDate: firstDate.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
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
      final days = picked.difference(widget.initiateDate).inDays;
      setState(() {
        _deadline = picked;
        _daysController.text = days >= 0 ? days.toString() : '0';
      });
      widget.onDeadlineChanged(picked);
    }
  }

  void _clearDeadline() {
    setState(() {
      _deadline = null;
      _daysController.clear();
    });
    widget.onDeadlineChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final initiateStr = DateFormat('yyyy-MM-dd').format(widget.initiateDate);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InstitutionalTheme.creamSurface,
        border: Border.all(color: InstitutionalTheme.borderLedger),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Initiate Date row
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: InstitutionalTheme.primaryNavy),
              const SizedBox(width: 6),
              const Text(
                'TASK INITIATE DATE: ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
              ),
              Text(
                '$initiateStr (Date Entered)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: InstitutionalTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Deadline selection label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TARGET DEADLINE / DUE DATE:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
              ),
              if (_deadline != null)
                InkWell(
                  onTap: _clearDeadline,
                  child: const Text(
                    'Clear Deadline',
                    style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick days shortcut chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildDayChip(3),
              _buildDayChip(7),
              _buildDayChip(14),
              _buildDayChip(30),
              _buildDayChip(60),
              _buildDayChip(90),
            ],
          ),
          const SizedBox(height: 10),

          // Custom Days Input + Calendar Button
          Row(
            children: [
              // Days text input
              SizedBox(
                width: 130,
                height: 38,
                child: TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Or enter days',
                    hintText: 'e.g. 10',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (val) {
                    final days = int.tryParse(val.trim());
                    if (days != null && days >= 0) {
                      final newDeadline = widget.initiateDate.add(Duration(days: days));
                      setState(() => _deadline = newDeadline);
                      widget.onDeadlineChanged(newDeadline);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Calendar Picker Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: InstitutionalTheme.primaryNavy,
                  side: const BorderSide(color: InstitutionalTheme.borderLedger),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _pickDateFromCalendar,
                icon: const Icon(Icons.date_range, size: 16),
                label: const Text('CALENDAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // Deadline summary card preview
          if (_deadline != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                border: Border.all(color: const Color(0xFFEAB308)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm_on, size: 16, color: Color(0xFF854D0E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deadline: ${dateFormat.format(_deadline!)} (${_deadline!.difference(widget.initiateDate).inDays} days from initiation)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF854D0E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayChip(int days) {
    final isSelected = _deadline != null && _deadline!.difference(widget.initiateDate).inDays == days;

    return InkWell(
      onTap: () => _setDeadlineFromDays(days),
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? InstitutionalTheme.primaryNavy : Colors.white,
          border: Border.all(
            color: isSelected ? InstitutionalTheme.primaryNavy : InstitutionalTheme.borderLedger,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          '+$days Days',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : InstitutionalTheme.textDark,
          ),
        ),
      ),
    );
  }
}
