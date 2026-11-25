import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../models/member_model.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final members = appState.members;
    final allTasks = appState.tasks;

    return Container(
      color: InstitutionalTheme.creamBackground,
      child: Column(
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: InstitutionalTheme.creamSurface,
              border: Border(bottom: BorderSide(color: InstitutionalTheme.borderLedger, width: 1.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INSTITUTIONAL MEMBERS ROSTER',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: InstitutionalTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Accredited Committee Members & Task Assignees (${members.length} Total Enrolled)',
                        style: const TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showMemberDialog(context, appState),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('ENROLL MEMBER'),
                ),
              ],
            ),
          ),

          // Members Roster List
          Expanded(
            child: members.isEmpty
                ? const Center(child: Text('No members enrolled.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final assignedCount = allTasks
                          .where((t) => !t.isDeleted && t.assignedMemberIds.contains(member.id))
                          .length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: member.isActive ? InstitutionalTheme.borderLedger : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: member.isActive ? InstitutionalTheme.primaryNavy : Colors.grey[400],
                              child: Text(
                                member.name.isNotEmpty ? member.name[0] : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        member.name,
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: member.isActive ? InstitutionalTheme.primaryNavy : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: member.isActive ? InstitutionalTheme.bgCompleted : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Text(
                                          member.isActive ? 'ACTIVE' : 'DEACTIVATED',
                                          style: TextStyle(
                                            color: member.isActive ? InstitutionalTheme.statusCompleted : Colors.grey[700],
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${member.designation} • ${member.email}',
                                    style: const TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: InstitutionalTheme.creamSurface,
                                border: Border.all(color: InstitutionalTheme.borderLedger),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '$assignedCount Tasks Assigned',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: InstitutionalTheme.primaryNavy),
                              onPressed: () => _showMemberDialog(context, appState, existing: member),
                            ),
                            IconButton(
                              tooltip: member.isActive ? 'Deactivate Member' : 'Reactivate Member',
                              icon: Icon(
                                member.isActive ? Icons.toggle_on : Icons.toggle_off,
                                size: 28,
                                color: member.isActive ? InstitutionalTheme.statusCompleted : Colors.grey,
                              ),
                              onPressed: () => appState.toggleMemberActive(member.id),
                            ),
                            IconButton(
                              tooltip: 'Remove / Delete Member',
                              icon: const Icon(Icons.delete_outline, size: 20, color: InstitutionalTheme.statusEliminated),
                              onPressed: () => _confirmDeleteMember(context, appState, member),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showMemberDialog(BuildContext context, AppState appState, {Member? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final desigController = TextEditingController(text: existing?.designation ?? 'Member');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: InstitutionalTheme.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3), side: const BorderSide(color: InstitutionalTheme.borderLedger)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'ENROLL INSTITUTIONAL MEMBER' : 'EDIT MEMBER RECORD',
                style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name with Title *', hintText: 'e.g. Dr. Arthur Pendelton'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Institutional Email', hintText: 'e.g. pendelton@institution.gov'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: desigController,
                decoration: const InputDecoration(labelText: 'Designation / Office', hintText: 'e.g. Secretary-General, Committee Chair'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        if (existing == null) {
                          appState.addMember(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            designation: desigController.text.trim(),
                          );
                        } else {
                          appState.updateMember(
                            existing.copyWith(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              designation: desigController.text.trim(),
                            ),
                          );
                        }
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(existing == null ? 'SAVE MEMBER' : 'UPDATE RECORD'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMember(BuildContext context, AppState appState, Member member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: InstitutionalTheme.creamCard,
        title: const Text(
          'REMOVE MEMBER FROM ROSTER?',
          style: TextStyle(fontFamily: 'serif', color: InstitutionalTheme.primaryNavy, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to remove "${member.name}" from the institutional registry?\n\n'
          'Their historical records and docket logs will be preserved for audit compliance, but they will no longer appear in active member rosters.',
          style: const TextStyle(fontSize: 13, color: InstitutionalTheme.textBody),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: InstitutionalTheme.statusEliminated),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.deleteMember(member.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Member "${member.name}" removed from registry.'),
                  backgroundColor: InstitutionalTheme.primaryNavy,
                ),
              );
            },
            child: const Text('CONFIRM REMOVE'),
          ),
        ],
      ),
    );
  }
}
