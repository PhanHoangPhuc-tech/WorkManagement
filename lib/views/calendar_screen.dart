import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/calendar_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_view_data.dart';
import 'package:workmanagement/views/edit_task.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToEditTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<CalendarFormat, String> availableCalendarFormatsMap = const {
      CalendarFormat.month: 'Tháng',
      CalendarFormat.twoWeeks: '2 Tuần',
      CalendarFormat.week: 'Tuần',
    };

    final headerTitleStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 15.0,
          fontWeight: FontWeight.bold,
        ) ??
        const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold);

    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, child) {
        final today = DateTime.now();

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        final currentFocusedDay = viewModel.focusedDay;
                        final prevMonthDay = DateTime(
                          currentFocusedDay.year,
                          currentFocusedDay.month - 1,
                          1,
                        );
                        viewModel.onPageChanged(prevMonthDay);
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          DateFormat.yMMMM(
                            'vi_VN',
                          ).format(viewModel.focusedDay),
                          style: headerTitleStyle,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        final currentFocusedDay = viewModel.focusedDay;
                        final nextMonthDay = DateTime(
                          currentFocusedDay.year,
                          currentFocusedDay.month + 1,
                          1,
                        );
                        viewModel.onPageChanged(nextMonthDay);
                      },
                    ),
                  ],
                ),
              ),
              TableCalendar<TaskViewData>(
                locale: 'vi_VN',
                firstDay: DateTime.utc(2010, 1, 1),
                lastDay: DateTime.utc(2040, 12, 31),
                focusedDay: viewModel.focusedDay,
                selectedDayPredicate:
                    (day) => isSameDay(viewModel.selectedDay, day),
                calendarFormat: viewModel.calendarFormat,
                eventLoader: viewModel.getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableCalendarFormats: availableCalendarFormatsMap,
                calendarStyle: CalendarStyle(
                  cellPadding: const EdgeInsets.all(4.0),
                  defaultDecoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.transparent,
                  ),
                  weekendDecoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.transparent,
                  ),
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(77),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Theme.of(context).primaryColorDark,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withAlpha(179),
                    shape: BoxShape.circle,
                  ),
                  markerSize: 5.0,
                  markersMaxCount: 1,
                ),
                headerStyle: const HeaderStyle(
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  titleCentered: false,
                  titleTextStyle: TextStyle(fontSize: 0, height: 0),
                  formatButtonVisible: false,
                  headerMargin: EdgeInsets.zero,
                  headerPadding: EdgeInsets.zero,
                ),
                daysOfWeekHeight: 20.0,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(viewModel.selectedDay, selectedDay)) {
                    viewModel.onDaySelected(selectedDay, focusedDay);
                  }
                },
                onPageChanged: (focusedDay) {
                  viewModel.onPageChanged(focusedDay);
                },
                onFormatChanged: (format) {
                  if (viewModel.calendarFormat != format) {
                    viewModel.onFormatChanged(format);
                  }
                },
              ),
              if (viewModel.selectedDay != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Công việc ngày: ${DateFormat('dd/MM/yyyy', 'vi_VN').format(viewModel.selectedDay!)}",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (!isSameDay(viewModel.selectedDay, today))
                        TextButton(
                          onPressed: () {
                            context.read<CalendarViewModel>().selectToday();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: Theme.of(
                                context,
                                // ignore: deprecated_member_use
                              ).primaryColor.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            'Quay về hôm nay',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const Divider(height: 1, thickness: 1, indent: 0, endIndent: 0),
              Expanded(
                child:
                    viewModel.tasksForSelectedDay.isEmpty
                        ? Center(
                          child: Text(
                            'Không có công việc nào cho ngày này.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                        : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: viewModel.tasksForSelectedDay.length,
                          itemBuilder: (context, index) {
                            final taskData =
                                viewModel.tasksForSelectedDay[index];
                            final originalTask = taskData.originalTask;
                            return _buildCalendarTaskItem(
                              context,
                              taskData,
                              originalTask,
                            );
                          },
                          separatorBuilder:
                              (context, index) => const Divider(
                                height: 1,
                                thickness: 0.5,
                                indent: 16,
                                endIndent: 16,
                              ),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarTaskItem(
    BuildContext context,
    TaskViewData taskData,
    Task originalTask,
  ) {
    final theme = Theme.of(context);
    final bool isDone = taskData.isDone;

    return ListTile(
      leading: Icon(
        taskData.sticker ?? Icons.label_outline,
        color: isDone ? Colors.grey : theme.primaryColor,
        size: 24,
      ),
      title: Text(
        taskData.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: isDone ? TextDecoration.lineThrough : null,
          fontWeight: FontWeight.w500,
          color: isDone ? Colors.grey[600] : null,
        ),
      ),
      subtitle: Text(
        taskData.formattedDueTime.isNotEmpty
            ? "Giờ: ${taskData.formattedDueTime}"
            : (taskData.displaySubtitle.length > 40
                ? '${taskData.displaySubtitle.substring(0, 40)}...'
                : taskData.displaySubtitle),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          decoration: isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Icon(Icons.flag, color: taskData.priorityColor, size: 18),
      onTap: () {
        _navigateToEditTask(context, originalTask);
      },
      tileColor:
          isDone ? Colors.grey.shade100.withAlpha(128) : Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 2.0,
      ),
      dense: true,
    );
  }
}
