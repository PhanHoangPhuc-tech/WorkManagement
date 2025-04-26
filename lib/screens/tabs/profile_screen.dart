import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// --- Đảm bảo bạn đã import đúng đường dẫn tới các file model và viewmodel ---
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
// -------------------------------------------------------------------------

enum TimeRange { today, thisWeek, thisMonth, thisYear, allTime, custom }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TimeRange _selectedTimeRange = TimeRange.allTime;
  DateTimeRange? _customDateRange;

  DateTimeRange _getDateTimeRange(TimeRange range) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (range) {
      case TimeRange.today:
        return DateTimeRange(
          start: todayStart,
          end: todayStart.add(const Duration(days: 1)),
        );
      case TimeRange.thisWeek:
        final daysToSubtract = (now.weekday - DateTime.monday + 7) % 7;
        final startOfWeek = todayStart.subtract(Duration(days: daysToSubtract));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case TimeRange.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth =
            (now.month < 12)
                ? DateTime(now.year, now.month + 1, 1)
                : DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case TimeRange.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case TimeRange.custom:
        return _customDateRange ??
            DateTimeRange(
              start: todayStart,
              end: todayStart.add(const Duration(days: 1)),
            );
      case TimeRange.allTime:
        final tenYearsAgo = DateTime(now.year - 10, 1, 1);
        final endOfThisYear = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: tenYearsAgo, end: endOfThisYear);
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final initialRange =
        _customDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN KHOẢNG NGÀY',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedTimeRange = TimeRange.custom;
        _customDateRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
            999,
          ),
        );
      });
    }
  }

  List<Task> _filterTasksByDate(List<Task> allTasks, DateTimeRange range) {
    final start = range.start;
    final end =
        (_selectedTimeRange == TimeRange.custom)
            ? range.end.add(const Duration(microseconds: 1))
            : range.end;

    // Giả định createdAt trong Task model là non-nullable (DateTime)
    // Nếu createdAt là nullable (DateTime?), bạn cần thêm lại kiểm tra null
    return allTasks
        .where(
          (task) =>
              !task.createdAt.isBefore(start) && task.createdAt.isBefore(end),
        )
        .toList();
  }

  double _calculateNiceInterval(double maxVal) {
    if (maxVal <= 1) return 1.0;
    if (maxVal <= 5) return 1.0;
    if (maxVal <= 10) return 2.0;

    double roughInterval = maxVal / 4.0;
    double magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    double residual = roughInterval / magnitude;

    if (residual > 5) return 10 * magnitude;
    if (residual > 2) return 5 * magnitude;
    if (residual > 1) return 2 * magnitude;
    return 1 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.watch<TaskViewModel>();
    final categoryViewModel = context.watch<CategoryViewModel>();
    final allTasks = taskViewModel.tasks;
    final theme = Theme.of(context);

    final dateTimeRange = _getDateTimeRange(_selectedTimeRange);
    final filteredTasks = _filterTasksByDate(allTasks, dateTimeRange);

    int completedCount = 0;
    int uncompletedCount = 0;
    Map<String, int> categoryCounts = {};
    List<String> categoriesFromVM = categoryViewModel.categories;

    for (var cat in categoriesFromVM) {
      categoryCounts[cat] = 0;
    }
    categoryCounts['Chưa phân loại'] = 0;

    for (var task in filteredTasks) {
      if (task.isDone) {
        completedCount++;
      } else {
        uncompletedCount++;
      }
      final category =
          (task.category?.isNotEmpty ?? false) &&
                  categoriesFromVM.contains(task.category)
              ? task.category!
              : 'Chưa phân loại';
      if (categoryCounts.containsKey(category)) {
        categoryCounts[category] = categoryCounts[category]! + 1;
      }
    }

    categoryCounts.removeWhere(
      (key, value) => value == 0 && key != 'Chưa phân loại',
    );

    final totalCount = filteredTasks.length;
    double completedPercent = 0;
    double uncompletedPercent = 0.0;

    if (totalCount > 0) {
      completedPercent = (completedCount / totalCount) * 100;
      uncompletedPercent = 100.0 - completedPercent;
    } else {
      uncompletedPercent = 0.0;
      completedPercent = 0.0;
    }

    final Color completedColor = Colors.green.shade500;
    final Color pendingColor = Colors.orange.shade500;
    final Color totalTasksColor = theme.colorScheme.primary;
    final Color categoryColor1 = theme.colorScheme.secondary;
    final Color categoryColor2 = Colors.blue.shade300;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Tổng Quan Công Việc'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black54),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: RefreshIndicator(
        onRefresh:
            () async => await Future.wait([
              context.read<TaskViewModel>().loadTasks(),
              context.read<CategoryViewModel>().loadCategories(),
            ]),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTimeRangeSelector(theme),
            if (_selectedTimeRange == TimeRange.custom &&
                _customDateRange != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: 12.0,
                  bottom: 4.0,
                  left: 4.0,
                ),
                child: Text(
                  'Khoảng đã chọn: ${DateFormat('dd/MM/yy').format(_customDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_customDateRange!.end)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildOverviewCard(
              theme,
              completedCount,
              uncompletedCount,
              totalCount,
              completedColor,
              pendingColor,
              totalTasksColor,
            ),
            const SizedBox(height: 20),
            _buildChartsCard(
              theme,
              totalCount,
              completedCount,
              uncompletedCount,
              completedPercent,
              uncompletedPercent,
              completedColor,
              pendingColor,
            ),
            const SizedBox(height: 20),
            _buildCategoryStatsCard(
              theme,
              categoryCounts,
              categoryColor1,
              categoryColor2,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    final List<TimeRange> rangesRow1 = [
      TimeRange.today,
      TimeRange.thisWeek,
      TimeRange.thisMonth,
    ];
    final List<TimeRange> rangesRow2 = [
      TimeRange.thisYear,
      TimeRange.allTime,
      TimeRange.custom,
    ];

    final double chipPaddingHorizontal = 10;
    final double chipPaddingVertical = 6;
    final double chipSpacing = 8; // Khoảng cách giữa các chip và các hàng

    // Hàm tạo một ChoiceChip chuẩn
    Widget buildChip(TimeRange range) {
      final bool isSelected = _selectedTimeRange == range;
      String text = '';

      switch (range) {
        case TimeRange.today:
          text = 'Hôm nay';
          break;
        case TimeRange.thisWeek:
          text = 'Tuần này';
          break;
        case TimeRange.thisMonth:
          text = 'Tháng­ ­này';
          break;
        case TimeRange.thisYear:
          text = 'Năm nay';
          break;
        case TimeRange.allTime:
          text = 'Tất cả    ';
          break;
        case TimeRange.custom:
          text = 'Tùy chọn  ';
          break;
      }

      return ChoiceChip(
        key: ValueKey(range),
        label: Text(
          text,
          overflow: TextOverflow.ellipsis, // Xử lý tràn chữ
          textAlign: TextAlign.center, // Canh giữa text
        ),
        // avatar: null, // Đảm bảo không có avatar
        selected: isSelected,
        onSelected: (selected) {
          if (range == TimeRange.custom) {
            _selectCustomDateRange(context);
          } else if (selected) {
            setState(() {
              _selectedTimeRange = range;
              _customDateRange = null;
            });
          }
        },
        selectedColor: theme.primaryColor.withAlpha(40),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? theme.primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color:
              isSelected
                  ? theme.primaryColor.withAlpha(100)
                  : Colors.grey.shade300,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: chipPaddingHorizontal,
          vertical: chipPaddingVertical,
        ),
      );
    }

    // Hàm tạo một hàng chip với Expanded
    Widget buildChipRow(List<TimeRange> ranges) {
      return Row(
        children:
            ranges.map((range) {
              return Expanded(
                child: Padding(
                  // Thêm padding để tạo khoảng cách giữa các chip trong Expanded
                  padding: EdgeInsets.symmetric(horizontal: chipSpacing / 2),
                  child: buildChip(range), // Đặt chip trực tiếp vào Padding
                ),
              );
            }).toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // Đã sửa deprecated
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Sử dụng Column chứa 2 Row với Expanded
      child: Column(
        mainAxisSize: MainAxisSize.min, // Co lại theo nội dung
        children: [
          buildChipRow(rangesRow1),
          SizedBox(height: chipSpacing), // Khoảng cách giữa 2 hàng
          buildChipRow(rangesRow2),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withAlpha(38), // Đã sửa deprecated
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    ThemeData theme,
    int completed,
    int uncompleted,
    int total,
    Color completedColor,
    Color pendingColor,
    Color totalColor,
  ) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              theme,
              Icons.check_circle,
              'Hoàn thành',
              completed.toString(),
              completedColor,
            ),
            _buildStatItem(
              theme,
              Icons.pending_actions_outlined,
              'Chưa xong',
              uncompleted.toString(),
              pendingColor,
            ),
            _buildStatItem(
              theme,
              Icons.summarize_outlined,
              'Tổng cộng',
              total.toString(),
              totalColor,
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _getBarTitles(double value, TitleMeta meta) {
    final style = TextStyle(color: Colors.grey[600], fontSize: 11);
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Xong';
        break;
      case 1:
        text = 'Chưa';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4.0,
      child: Text(text, style: style),
    );
  }

  Widget _buildChartsCard(
    ThemeData theme,
    int totalCount,
    int completed,
    int uncompleted,
    double completedPercent,
    double uncompletedPercent,
    Color completedColor,
    Color pendingColor,
  ) {
    if (totalCount <= 0) {
      return _buildEmptyStateCard(
        theme,
        "Chưa có công việc nào để vẽ biểu đồ.",
        height: 240,
      );
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double breakpoint = 450.0;
            bool useRow = constraints.maxWidth >= breakpoint;

            return useRow
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildBarChart(
                        theme,
                        completed,
                        uncompleted,
                        completedColor,
                        pendingColor,
                      ),
                    ),
                    const SizedBox(width: 32), // Khoảng cách giữa 2 biểu đồ
                    Expanded(
                      flex: 2,
                      child: _buildPieChart(
                        theme,
                        completedPercent,
                        uncompletedPercent,
                        completedColor,
                        pendingColor,
                      ),
                    ),
                  ],
                )
                : Column(
                  children: [
                    _buildBarChart(
                      theme,
                      completed,
                      uncompleted,
                      completedColor,
                      pendingColor,
                    ),
                    const SizedBox(height: 24),
                    _buildPieChart(
                      theme,
                      completedPercent,
                      uncompletedPercent,
                      completedColor,
                      pendingColor,
                    ),
                  ],
                );
          },
        ),
      ),
    );
  }

  Widget _buildBarChart(
    ThemeData theme,
    int completed,
    int uncompleted,
    Color completedColor,
    Color pendingColor,
  ) {
    final barGroups = [
      _makeBarGroupData(0, completed.toDouble(), completedColor),
      _makeBarGroupData(1, uncompleted.toDouble(), pendingColor),
    ];
    final maxYValue = max(completed, uncompleted).toDouble();
    final double interval = max(1.0, _calculateNiceInterval(maxYValue));
    final double niceMaxY =
        (maxYValue <= 0) ? interval : (maxYValue / interval).ceil() * interval;
    final double maxY = max(5.0, max(interval, niceMaxY));
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Biểu đồ số lượng công việc hoàn thành',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16), // Đã tăng khoảng cách
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String label;
                    switch (group.x.toInt()) {
                      case 0:
                        label = 'Hoàn thành';
                        break;
                      case 1:
                        label = 'Chưa xong';
                        break;
                      default:
                        label = '';
                        break;
                    }
                    return BarTooltipItem(
                      '$label\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: rod.toY.toInt().toString(),
                          style: TextStyle(
                            color: rod.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: _getBarTitles,
                    reservedSize: 22,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) {
                        return Container();
                      }
                      if (value != 0 && value % interval != 0) {
                        return Container();
                      }
                      if (value == 0 && maxY <= interval * 1.5) {
                        return Container();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine:
                    (value) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              barGroups: barGroups,
            ),
            swapAnimationDuration: const Duration(milliseconds: 250),
            swapAnimationCurve: Curves.linear,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(
    ThemeData theme,
    double completedPercent,
    double uncompletedPercent,
    Color completedColor,
    Color pendingColor,
  ) {
    bool showCompleted = completedPercent > 0.1;
    bool showPending = uncompletedPercent > 0.1;
    List<PieChartSectionData> sections = [];

    if (showCompleted) {
      sections.add(
        PieChartSectionData(
          color: completedColor,
          value: completedPercent,
          title: '${completedPercent.toStringAsFixed(0)}%',
          radius: 50,
          titlePositionPercentageOffset: 0.6,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      );
    }
    if (showPending) {
      sections.add(
        PieChartSectionData(
          color: pendingColor,
          value: uncompletedPercent,
          title: '${uncompletedPercent.toStringAsFixed(0)}%',
          radius: 50,
          titlePositionPercentageOffset: 0.6,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: '',
          radius: 50,
        ),
      );
    }
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Biểu đồ tỷ lệ công việc hoàn thành',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16), // Đã tăng khoảng cách
        SizedBox(
          height: 190,
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    startDegreeOffset: -90,
                    sections: sections,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 250),
                  swapAnimationCurve: Curves.linear,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCompleted) _buildLegend(completedColor, 'Hoàn thành'),
                  if (showCompleted && showPending) const SizedBox(width: 16),
                  if (showPending) _buildLegend(pendingColor, 'Chưa xong'),
                  if (!showCompleted && !showPending)
                    _buildLegend(Colors.grey.shade400, 'Chưa có dữ liệu'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStatsCard(
    ThemeData theme,
    Map<String, int> categoryCounts,
    Color color1,
    Color color2,
  ) {
    final sortedCategories =
        categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final List<Color> categoryColors = [
      color1,
      color2,
      Colors.teal.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.indigo.shade300,
      Colors.amber.shade400,
      Colors.deepOrange.shade300,
    ];

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Theo phân loại',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Sử dụng if/else với {} đúng cách
            if (sortedCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Chưa có công việc nào được phân loại.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length,
                separatorBuilder:
                    (_, __) => const Divider(
                      height: 16,
                      thickness: 0.5,
                      indent: 26,
                      endIndent: 10,
                    ),
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final itemColor =
                      categoryColors[index % categoryColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(
    ThemeData theme,
    String message, {
    double height = 150,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      ),
    );
  }
}
