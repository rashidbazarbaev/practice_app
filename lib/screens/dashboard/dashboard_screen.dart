import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../utils/color_utils.dart';
import '../../utils/date_utils.dart';
import '../../utils/label_utils.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../profile/profile_edit_screen.dart';
import 'widgets/gpa_card.dart';
import 'widgets/subject_progress_card.dart';
import 'widgets/ai_recommendations_card.dart';
import 'widgets/analytics_preview_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProv = context.watch<StudentProvider>();
    final taskProv = context.watch<TaskProvider>();
    final student = studentProv.student;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            // App Bar with profile
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (student != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfileEditScreen(
                                            student: student),
                                      ),
                                    );
                                  }
                                },
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.3),
                                      backgroundImage: student?.avatarPath != null
                                          ? FileImage(File(student!.avatarPath!))
                                          : null,
                                      child: student?.avatarPath == null
                                          ? Text(
                                              student?.name.isNotEmpty == true
                                                  ? student!.name[0].toUpperCase()
                                                  : 'С',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          size: 10,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student?.name ?? 'Студент',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${student?.faculty ?? ''} • ${student?.course ?? 1} курс',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Дашборд',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // GPA Card
                  GpaCard(
                    gpa: student?.gpa ?? 0,
                    completedTasks: taskProv.completedCount,
                    totalTasks: taskProv.totalCount,
                    overdueTasks: taskProv.overdueTasks.length,
                  ),
                  const SizedBox(height: 16),

                  // Upcoming deadlines
                  _SectionHeader(
                    title: 'Ближайшие дедлайны',
                    onSeeAll: () =>
                        DefaultTabController.of(context).animateTo(2),
                  ),
                  const SizedBox(height: 8),
                  if (taskProv.upcomingTasks.isEmpty)
                    _EmptyCard(
                      icon: Icons.check_circle_outline,
                      message: 'Нет предстоящих задач',
                    )
                  else
                    ...taskProv.upcomingTasks
                        .map((t) => _DeadlineItem(task: t)),

                  const SizedBox(height: 16),

                  // Subject progress
                  _SectionHeader(
                    title: 'Прогресс по предметам',
                    onSeeAll: null,
                  ),
                  const SizedBox(height: 8),
                  if (studentProv.subjects.isEmpty)
                    _EmptyCard(
                      icon: Icons.school_outlined,
                      message: 'Нет предметов',
                    )
                  else
                    SubjectProgressCard(subjects: studentProv.subjects),

                  const SizedBox(height: 16),

                  // Analytics preview
                  const AnalyticsPreviewCard(),
                  const SizedBox(height: 16),

                  // AI Recommendations
                  const AiRecommendationsCard(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Задача'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Все'),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(icon,
                  size: 40,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 8),
              Text(message,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final Task task;

  const _DeadlineItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.deadlineColor(task.deadline, task.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        ),
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${task.subjectName} • ${AppDateUtils.relativeDeadline(task.deadline)}',
          style: TextStyle(fontSize: 12, color: color),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ColorUtils.taskPriorityColor(task.priority)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            LabelUtils.taskPriority(task.priority),
            style: TextStyle(
              fontSize: 11,
              color: ColorUtils.taskPriorityColor(task.priority),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
