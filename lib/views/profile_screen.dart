import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';

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
        final start = DateTime(now.year - 1, 1, 1);
        final end = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: start, end: end);
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final theme = Theme.of(context);
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
        return Theme(data: theme, child: child!);
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
    final end = range.end.add(const Duration(microseconds: 1));

    return allTasks.where((task) {
      final relevantDate = task.completedAt ?? task.createdAt;
      return !relevantDate.isBefore(start) && relevantDate.isBefore(end);
    }).toList();
  }

  double _calculateNiceInterval(double maxVal) {
    if (maxVal <= 1) return 1.0;
    if (maxVal <= 5) return 1.0;
    if (maxVal <= 10) return 2.0;
    if (maxVal <= 20) return 5.0;
    if (maxVal <= 50) return 10.0;

    double roughInterval = maxVal / 4.0;
    double magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    double residual = roughInterval / magnitude;

    if (residual > 5) return 10 * magnitude;
    if (residual > 2) return 5 * magnitude;
    if (residual > 1) return 2 * magnitude;
    return 1 * magnitude;
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

  Widget _getBarTitles(
    double value,
    TitleMeta meta,
    ThemeData theme,
    Color axisColor,
  ) {
    final style =
        theme.textTheme.bodySmall?.copyWith(color: axisColor, fontSize: 11) ??
        TextStyle(color: axisColor, fontSize: 11);
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
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.watch<TaskViewModel>();
    final categoryViewModel = context.watch<CategoryViewModel>();
    final allTasks = taskViewModel.allRawTasks;
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

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
      categoryCounts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }

    categoryCounts.removeWhere(
      (key, value) => value == 0 && key != 'Chưa phân loại',
    );
    if (categoryCounts['Chưa phân loại'] == 0 && categoryCounts.length > 1) {
      categoryCounts.remove('Chưa phân loại');
    }

    final totalCountInPeriod = filteredTasks.length;
    double completedPercent = 0.0;
    double uncompletedPercent = 0.0;

    if (totalCountInPeriod > 0) {
      completedPercent = (completedCount / totalCountInPeriod) * 100;
      uncompletedPercent = 100.0 - completedPercent;
    } else {
      completedPercent = 0.0;
      uncompletedPercent = 0.0;
    }

    final Color completedColor = Colors.green.shade500;
    final Color pendingColor = Colors.orange.shade500;
    final Color totalTasksColor = theme.colorScheme.primary;
    final Color categoryColor1 = theme.colorScheme.secondary;
    final Color categoryColor2 = Colors.blue.shade300;

    final Color labelColor =
        theme.textTheme.bodySmall?.color?.withAlpha(180) ?? Colors.grey[600]!;
    final Color valueColor =
        theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface;
    final Color axisColor = theme.dividerColor.withAlpha(150);
    final Color gridColor = theme.dividerColor.withAlpha(100);
    final Color legendColor =
        theme.textTheme.bodySmall?.color?.withAlpha(200) ??
        theme.colorScheme.onSurface.withAlpha(200);
    final Color chartTitleColor =
        theme.textTheme.titleSmall?.color ?? theme.colorScheme.onSurface;
    final Color tooltipTextColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng Quan Công Việc'),
        centerTitle: true,
        backgroundColor:
            isDarkMode ? theme.scaffoldBackgroundColor : Colors.white,
        foregroundColor:
            isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
        elevation: isDarkMode ? 0 : 1,
        iconTheme:
            isDarkMode
                ? IconThemeData(
                  color: theme.colorScheme.onSurface.withAlpha(200),
                )
                : const IconThemeData(color: Colors.black54),
        titleTextStyle:
            isDarkMode
                ? TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                )
                : const TextStyle(
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
                  style: theme.textTheme.bodySmall?.copyWith(color: labelColor),
                ),
              ),
            const SizedBox(height: 16),
            _buildOverviewCard(
              theme,
              completedCount,
              uncompletedCount,
              totalCountInPeriod,
              completedColor,
              pendingColor,
              totalTasksColor,
              labelColor,
              valueColor,
            ),
            const SizedBox(height: 20),
            _buildChartsCard(
              theme,
              totalCountInPeriod,
              completedCount,
              uncompletedCount,
              completedPercent,
              uncompletedPercent,
              completedColor,
              pendingColor,
              axisColor,
              gridColor,
              legendColor,
              chartTitleColor,
              tooltipTextColor,
            ),
            const SizedBox(height: 20),
            _buildCategoryStatsCard(
              theme,
              categoryCounts,
              categoryColor1,
              categoryColor2,
              chartTitleColor,
              labelColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color chipBackgroundColor =
        theme.chipTheme.backgroundColor ??
        (isDarkMode ? Colors.grey[800]! : Colors.grey.shade200);
    final Color chipSelectedBackgroundColor =
        theme.chipTheme.selectedColor ?? theme.primaryColor.withAlpha(40);
    final Color unselectedBorderColor =
        isDarkMode ? theme.dividerColor : Colors.grey.shade200;
    final Color selectedBorderColor = theme.primaryColor.withAlpha(100);
    final TextStyle chipLabelStyle =
        theme.chipTheme.labelStyle ??
        TextStyle(color: theme.colorScheme.onSurface);
    final TextStyle chipSelectedLabelStyle =
        theme.chipTheme.secondaryLabelStyle ??
        TextStyle(color: theme.colorScheme.onPrimary);

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
    final double chipSpacing = 8;

    Widget buildChip(TimeRange range) {
      final bool isSelected = _selectedTimeRange == range;
      String text;
      switch (range) {
        case TimeRange.today:
          text = 'Hôm nay';
          break;
        case TimeRange.thisWeek:
          text = 'Tuần này';
          break;
        case TimeRange.thisMonth:
          text = 'Tháng này';
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
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
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
        selectedColor: chipSelectedBackgroundColor,
        labelStyle: (isSelected ? chipSelectedLabelStyle : chipLabelStyle)
            .copyWith(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
        backgroundColor: chipBackgroundColor,
        side: BorderSide(
          color: isSelected ? selectedBorderColor : unselectedBorderColor,
          width: 1,
        ),
        shape: theme.chipTheme.shape,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: chipPaddingHorizontal,
          vertical: chipPaddingVertical,
        ),
      );
    }

    Widget buildChipRow(List<TimeRange> ranges) {
      return Row(
        children:
            ranges.map((range) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: chipSpacing / 2),
                  child: buildChip(range),
                ),
              );
            }).toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDarkMode ? 30 : 13),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildChipRow(rangesRow1),
          SizedBox(height: chipSpacing),
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
    Color labelColor,
    Color valueColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withAlpha(38),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: labelColor),
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
    Color labelColor,
    Color valueColor,
  ) {
    return Card(
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
              labelColor,
              valueColor,
            ),
            _buildStatItem(
              theme,
              Icons.pending_actions_outlined,
              'Chưa xong',
              uncompleted.toString(),
              pendingColor,
              labelColor,
              valueColor,
            ),
            _buildStatItem(
              theme,
              Icons.summarize_outlined,
              'Tổng cộng',
              total.toString(),
              totalColor,
              labelColor,
              valueColor,
            ),
          ],
        ),
      ),
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
    Color axisColor,
    Color gridColor,
    Color legendColor,
    Color chartTitleColor,
    Color tooltipTextColor,
  ) {
    if (totalCount <= 0) {
      return _buildEmptyStateCard(
        theme,
        "Chưa có công việc nào trong khoảng thời gian này để vẽ biểu đồ.",
        height: 240,
      );
    }

    return Card(
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
                        axisColor,
                        gridColor,
                        chartTitleColor,
                        tooltipTextColor,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: _buildPieChart(
                        theme,
                        completedPercent,
                        uncompletedPercent,
                        completedColor,
                        pendingColor,
                        legendColor,
                        chartTitleColor,
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
                      axisColor,
                      gridColor,
                      chartTitleColor,
                      tooltipTextColor,
                    ),
                    const SizedBox(height: 24),
                    _buildPieChart(
                      theme,
                      completedPercent,
                      uncompletedPercent,
                      completedColor,
                      pendingColor,
                      legendColor,
                      chartTitleColor,
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
    Color axisColor,
    Color gridColor,
    Color chartTitleColor,
    Color tooltipTextColor,
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
      color: chartTitleColor,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Số lượng công việc',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
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
                    String label =
                        (group.x.toInt() == 0) ? 'Hoàn thành' : 'Chưa xong';
                    return BarTooltipItem(
                      '$label\n',
                      TextStyle(
                        color: tooltipTextColor,
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
                    getTitlesWidget:
                        (v, m) => _getBarTitles(v, m, theme, axisColor),
                    reservedSize: 22,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: interval,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value == 0 || value % interval != 0) {
                        if (value == meta.max && maxY > 0) {
                        } else {
                          return Container();
                        }
                      }
                      if (value == 0 && maxY <= interval * 1.5) {
                        return Container();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10, color: axisColor),
                          textAlign: TextAlign.right,
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
                    (value) => FlLine(color: gridColor, strokeWidth: 1),
              ),
              barGroups: barGroups,
            ),
            duration: const Duration(milliseconds: 250),
            curve: Curves.linear,
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
    Color legendColor,
    Color chartTitleColor,
  ) {
    bool showCompleted = completedPercent > 0.1;
    bool showPending = uncompletedPercent > 0.1;
    List<PieChartSectionData> sections = [];
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color pieTextColor = isDarkMode ? Colors.black : Colors.white;

    if (showCompleted) {
      sections.add(
        PieChartSectionData(
          color: completedColor,
          value: completedPercent,
          title: '${completedPercent.toStringAsFixed(0)}%',
          radius: 50,
          titlePositionPercentageOffset: 0.6,
          titleStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: pieTextColor,
            shadows: [Shadow(color: Colors.black.withAlpha(77), blurRadius: 2)],
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
          titleStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: pieTextColor,
            shadows: [Shadow(color: Colors.black.withAlpha(77), blurRadius: 2)],
          ),
        ),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          value: 100,
          title: '',
          radius: 50,
        ),
      );
    }

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: chartTitleColor,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Tỷ lệ hoàn thành',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
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
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.linear,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCompleted)
                    _buildLegend(completedColor, 'Hoàn thành', legendColor),
                  if (showCompleted && showPending) const SizedBox(width: 16),
                  if (showPending)
                    _buildLegend(pendingColor, 'Chưa xong', legendColor),
                  if (!showCompleted && !showPending)
                    _buildLegend(
                      Colors.grey.shade400,
                      'Chưa có dữ liệu',
                      legendColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text, Color legendColor) {
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
          Text(text, style: TextStyle(fontSize: 12, color: legendColor)),
        ],
      ),
    );
  }

  Widget _buildCategoryStatsCard(
    ThemeData theme,
    Map<String, int> categoryCounts,
    Color color1,
    Color color2,
    Color titleColor,
    Color labelColor,
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
      Colors.pink.shade200,
      Colors.lime.shade400,
    ];

    final Color categoryTextColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final Color countTextColor =
        theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600)
            .color ??
        theme.colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Theo phân loại',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            if (sortedCategories.isEmpty ||
                (sortedCategories.length == 1 &&
                    sortedCategories.first.key == 'Chưa phân loại' &&
                    sortedCategories.first.value == 0))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Chưa có công việc nào được phân loại trong khoảng thời gian này.',
                    style: TextStyle(color: labelColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length,
                separatorBuilder:
                    (_, __) => Divider(
                      height: 16,
                      thickness: 0.5,
                      indent: 26,
                      endIndent: 10,
                      color: theme.dividerColor.withAlpha(100),
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
                            style: TextStyle(
                              fontSize: 13,
                              color: categoryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: countTextColor,
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
    final Color textColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(150) ?? Colors.grey[600]!;
    return Card(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
