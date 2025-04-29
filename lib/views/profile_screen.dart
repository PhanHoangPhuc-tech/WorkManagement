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
        // Mặc định lấy từ đầu năm trước đến cuối năm nay cho "All Time"
        final start = DateTime(now.year - 1, 1, 1);
        final end = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: start, end: end);
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
            // Tùy chỉnh thêm giao diện DatePicker nếu muốn
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: Theme.of(context).primaryColor,
              headerForegroundColor: Colors.white,
              // Các tùy chỉnh khác...
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
        // Đảm bảo end date bao gồm cả ngày cuối cùng được chọn
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
            999, // Bao gồm cả ngày cuối
          ),
        );
      });
    }
  }

  // Lọc dựa trên ngày *hoàn thành* (completedAt) nếu task đã xong,
  // hoặc ngày *tạo* (createdAt) nếu chưa xong và nằm trong khoảng thời gian
  List<Task> _filterTasksByDate(List<Task> allTasks, DateTimeRange range) {
    final start = range.start;
    // Thêm microsecond để đảm bảo so sánh `isBefore` hoạt động đúng vào cuối ngày
    final end = range.end.add(const Duration(microseconds: 1));

    return allTasks.where((task) {
      // Ưu tiên ngày hoàn thành nếu có
      final relevantDate = task.completedAt ?? task.createdAt;
      // Kiểm tra xem ngày liên quan có nằm trong khoảng không
      return !relevantDate.isBefore(start) && relevantDate.isBefore(end);
    }).toList();
  }

  double _calculateNiceInterval(double maxVal) {
    if (maxVal <= 1) return 1.0;
    if (maxVal <= 5) return 1.0;
    if (maxVal <= 10) return 2.0;
    if (maxVal <= 20) return 5.0; // Thêm bước nhảy
    if (maxVal <= 50) return 10.0; // Thêm bước nhảy

    // Tính toán khoảng cách "đẹp" dựa trên bậc 10
    double roughInterval = maxVal / 4.0; // Chia thành khoảng 4-5 mức
    double magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    double residual = roughInterval / magnitude;

    // Chọn các giá trị đẹp (1, 2, 5, 10) * bậc 10
    if (residual > 5) return 10 * magnitude;
    if (residual > 2) return 5 * magnitude;
    if (residual > 1) return 2 * magnitude;
    return 1 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.watch<TaskViewModel>();
    final categoryViewModel = context.watch<CategoryViewModel>();
    final allTasks = taskViewModel.allRawTasks;
    final theme = Theme.of(context);

    final dateTimeRange = _getDateTimeRange(_selectedTimeRange);
    // Lọc task dựa trên khoảng thời gian đã chọn
    final filteredTasks = _filterTasksByDate(allTasks, dateTimeRange);

    int completedCount = 0;
    int uncompletedCount =
        0; // Số task *chưa hoàn thành* trong khoảng thời gian
    Map<String, int> categoryCounts = {};
    List<String> categoriesFromVM = categoryViewModel.categories;

    // Khởi tạo category counts
    for (var cat in categoriesFromVM) {
      categoryCounts[cat] = 0;
    }
    categoryCounts['Chưa phân loại'] = 0;

    // Đếm task đã lọc
    for (var task in filteredTasks) {
      if (task.isDone) {
        completedCount++;
      } else {
        // Task chưa xong *trong khoảng thời gian lọc*
        uncompletedCount++;
      }
      // Tính category cho tất cả task trong khoảng thời gian
      final category =
          (task.category?.isNotEmpty ?? false) &&
                  categoriesFromVM.contains(task.category)
              ? task.category!
              : 'Chưa phân loại';
      // Đảm bảo category tồn tại trong map trước khi tăng
      categoryCounts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }

    // Xóa các category không có task nào (trừ "Chưa phân loại")
    categoryCounts.removeWhere(
      (key, value) => value == 0 && key != 'Chưa phân loại',
    );
    // Nếu "Chưa phân loại" = 0 và có các category khác, thì cũng xóa nó đi
    if (categoryCounts['Chưa phân loại'] == 0 && categoryCounts.length > 1) {
      categoryCounts.remove('Chưa phân loại');
    }

    final totalCountInPeriod =
        filteredTasks.length; // Tổng số task trong khoảng thời gian đã chọn
    double completedPercent = 0.0;
    double uncompletedPercent = 0.0;

    if (totalCountInPeriod > 0) {
      completedPercent = (completedCount / totalCountInPeriod) * 100;
      // Tính phần trăm chưa hoàn thành dựa trên tổng số task *trong kỳ*
      uncompletedPercent = 100.0 - completedPercent;
    } else {
      // Nếu không có task nào trong kỳ, cả hai là 0
      completedPercent = 0.0;
      uncompletedPercent = 0.0;
    }

    final Color completedColor = Colors.green.shade500;
    final Color pendingColor = Colors.orange.shade500;
    final Color totalTasksColor = theme.colorScheme.primary;
    final Color categoryColor1 = theme.colorScheme.secondary;
    final Color categoryColor2 = Colors.blue.shade300;

    return Scaffold(
      // <-- ĐÃ XÓA backgroundColor ở đây
      appBar: AppBar(
        title: const Text('Tổng Quan Công Việc'),
        centerTitle: true,
        backgroundColor:
            theme.appBarTheme.backgroundColor, // Sử dụng màu từ theme
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        iconTheme: theme.appBarTheme.iconTheme, // Màu icon back nếu có
        titleTextStyle: theme.appBarTheme.titleTextStyle,
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
            // Hiển thị thống kê dựa trên filteredTasks
            _buildOverviewCard(
              theme,
              completedCount,
              uncompletedCount, // Task chưa hoàn thành trong kỳ
              totalCountInPeriod, // Tổng task trong kỳ
              completedColor,
              pendingColor,
              totalTasksColor,
            ),
            const SizedBox(height: 20),
            _buildChartsCard(
              theme,
              totalCountInPeriod, // Dùng tổng trong kỳ
              completedCount,
              uncompletedCount, // Dùng số chưa hoàn thành trong kỳ
              completedPercent,
              uncompletedPercent,
              completedColor,
              pendingColor,
            ),
            const SizedBox(height: 20),
            // Biểu đồ category dựa trên filteredTasks
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
          text = 'Tất cả';
          break;
        case TimeRange.custom:
          text = 'Tùy chọn';
          break;
      }

      return ChoiceChip(
        key: ValueKey(range), // Key để Flutter biết khi nào cần rebuild
        label: Text(
          text,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (range == TimeRange.custom) {
            _selectCustomDateRange(context); // Mở DatePicker
          } else if (selected) {
            // Chỉ cập nhật state nếu chip được chọn và không phải là custom
            setState(() {
              _selectedTimeRange = range;
              _customDateRange = null; // Reset custom range khi chọn cái khác
            });
          }
        },
        selectedColor: theme.primaryColor.withAlpha(40), // Màu nền khi chọn
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
        showCheckmark: false, // Không hiển thị dấu tick
        visualDensity: VisualDensity.compact, // Làm cho chip nhỏ gọn hơn
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: chipPaddingHorizontal,
          vertical: chipPaddingVertical,
        ),
      );
    }

    // Hàm tạo một hàng các Chip
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

    // Container chứa các chip
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng cho card chứa chip
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Thêm bóng đổ nhẹ
          BoxShadow(
            color: Colors.black.withAlpha(13), // Màu bóng đổ
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Chỉ chiếm chiều cao cần thiết
        children: [
          buildChipRow(rangesRow1),
          SizedBox(height: chipSpacing), // Khoảng cách giữa 2 hàng
          buildChipRow(rangesRow2),
        ],
      ),
    );
  }

  // Widget hiển thị một mục thống kê (icon, giá trị, nhãn)
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
          backgroundColor: color.withAlpha(38), // Màu nền nhẹ cho avatar
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color, // Màu chữ từ theme
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

  // Card hiển thị tổng quan số lượng task
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
      elevation: 1, // Độ nổi của card
      margin: EdgeInsets.zero, // Không có margin ngoài
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white, // Nền trắng cho card
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround, // Phân bố đều các item
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

  // Hàm tạo dữ liệu cho một cột trong BarChart
  BarChartGroupData _makeBarGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x, // Vị trí trên trục X
      barRods: [
        BarChartRodData(
          toY: y, // Giá trị trên trục Y
          color: color, // Màu của cột
          width: 20, // Độ rộng của cột
          borderRadius: const BorderRadius.only(
            // Bo góc trên của cột
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  // Hàm tạo widget cho tiêu đề trục X của BarChart
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
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(text, style: style),
    );
  }

  // Card chứa biểu đồ cột và tròn
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
    // Nếu không có task nào trong kỳ, hiển thị thông báo
    if (totalCount <= 0) {
      return _buildEmptyStateCard(
        theme,
        "Chưa có công việc nào trong khoảng thời gian này để vẽ biểu đồ.",
        height: 240, // Chiều cao phù hợp cho card trống
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
          // Sử dụng LayoutBuilder để bố cục tùy theo chiều rộng
          builder: (context, constraints) {
            const double breakpoint = 450.0; // Ngưỡng chuyển đổi layout
            bool useRow =
                constraints.maxWidth >= breakpoint; // Dùng Row nếu đủ rộng

            return useRow
                ? Row(
                  // Layout hàng ngang cho màn hình rộng
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // Biểu đồ cột chiếm nhiều không gian hơn
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
                      // Biểu đồ tròn
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
                  // Layout cột dọc cho màn hình hẹp
                  children: [
                    _buildBarChart(
                      theme,
                      completed,
                      uncompleted,
                      completedColor,
                      pendingColor,
                    ),
                    const SizedBox(height: 24), // Khoảng cách giữa 2 biểu đồ
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

  // Widget biểu đồ cột
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
    final maxYValue =
        max(completed, uncompleted).toDouble(); // Giá trị lớn nhất
    // Tính khoảng chia trục Y "đẹp" và giá trị max "đẹp"
    final double interval = max(1.0, _calculateNiceInterval(maxYValue));
    final double niceMaxY =
        (maxYValue <= 0) ? interval : (maxYValue / interval).ceil() * interval;
    // Đảm bảo trục Y có giá trị tối thiểu để hiển thị lưới
    final double maxY = max(
      5.0,
      max(interval, niceMaxY),
    ); // Giá trị max cho trục Y
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
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
          height: 190, // Chiều cao cố định cho biểu đồ
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround, // Căn chỉnh các cột
              maxY: maxY, // Giá trị lớn nhất trục Y
              barTouchData: BarTouchData(
                // Cấu hình tooltip khi chạm vào cột
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
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: rod.toY.toInt().toString(), // Giá trị của cột
                          style: TextStyle(
                            color: rod.color, // Màu chữ trùng màu cột
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
                // Cấu hình tiêu đề các trục
                show: true,
                bottomTitles: AxisTitles(
                  // Trục X (dưới)
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: _getBarTitles, // Hàm lấy widget tiêu đề
                    reservedSize: 22, // Khoảng trống cho tiêu đề trục X
                  ),
                ),
                leftTitles: AxisTitles(
                  // Trục Y (trái)
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32, // Khoảng trống cho tiêu đề trục Y
                    interval: interval, // Khoảng chia trục Y
                    getTitlesWidget: (double value, TitleMeta meta) {
                      // Chỉ hiển thị giá trị tại các khoảng chia và không hiển thị số 0 nếu không cần thiết
                      if (value == 0 || value % interval != 0) {
                        if (value == meta.max && maxY > 0) {
                          // Vẫn hiển thị max nếu nó không chia hết
                        } else {
                          return Container(); // Không hiển thị
                        }
                      }
                      // Giảm sự lộn xộn khi maxY nhỏ
                      if (value == 0 && maxY <= interval * 1.5) {
                        return Container();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ), // Ẩn trục trên
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ), // Ẩn trục phải
              ),
              borderData: FlBorderData(
                show: false,
              ), // Không hiển thị đường viền
              gridData: FlGridData(
                // Hiển thị lưới ngang
                show: true,
                drawVerticalLine: false, // Không vẽ lưới dọc
                horizontalInterval: interval, // Khoảng cách lưới ngang
                getDrawingHorizontalLine:
                    (value) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              barGroups: barGroups, // Dữ liệu các cột
            ),
            duration: const Duration(milliseconds: 250), // Animation duration
            curve: Curves.linear, // Animation curve
          ),
        ),
      ],
    );
  }

  // Widget biểu đồ tròn
  Widget _buildPieChart(
    ThemeData theme,
    double completedPercent,
    double uncompletedPercent,
    Color completedColor,
    Color pendingColor,
  ) {
    // Chỉ hiển thị nếu tỷ lệ > 0.1% để tránh lỗi render khi quá nhỏ
    bool showCompleted = completedPercent > 0.1;
    bool showPending = uncompletedPercent > 0.1;
    List<PieChartSectionData> sections = [];

    if (showCompleted) {
      sections.add(
        PieChartSectionData(
          color: completedColor,
          value: completedPercent,
          title: '${completedPercent.toStringAsFixed(0)}%', // Hiển thị %
          radius: 50, // Bán kính phần trăm
          titlePositionPercentageOffset: 0.6, // Vị trí text %
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
    // Nếu không có dữ liệu, hiển thị một hình tròn màu xám
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: '', // Không có text
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
          'Tỷ lệ hoàn thành',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190, // Chiều cao cố định
          child: Column(
            children: [
              Expanded(
                // Biểu đồ tròn chiếm phần lớn không gian
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2, // Khoảng cách giữa các phần
                    centerSpaceRadius: 30, // Bán kính lỗ ở giữa
                    startDegreeOffset: -90, // Bắt đầu từ trên cùng
                    sections: sections, // Dữ liệu các phần
                    pieTouchData: PieTouchData(
                      // Tắt tương tác chạm
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                    ),
                  ),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.linear,
                ),
              ),
              const SizedBox(height: 16), // Khoảng cách tới chú thích
              Row(
                // Chú thích (Legend)
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCompleted) _buildLegend(completedColor, 'Hoàn thành'),
                  if (showCompleted && showPending)
                    const SizedBox(width: 16), // Khoảng cách giữa 2 chú thích
                  if (showPending) _buildLegend(pendingColor, 'Chưa xong'),
                  // Nếu không có dữ liệu nào hiển thị
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

  // Widget tạo một mục chú thích cho biểu đồ tròn
  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // Chấm màu
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

  // Card hiển thị thống kê theo từng category
  Widget _buildCategoryStatsCard(
    ThemeData theme,
    Map<String, int> categoryCounts,
    Color color1,
    Color color2,
  ) {
    // Sắp xếp category theo số lượng giảm dần
    final sortedCategories =
        categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Danh sách màu sắc cho các category
    final List<Color> categoryColors = [
      color1, color2,
      Colors.teal.shade300, Colors.purple.shade300, Colors.red.shade300,
      Colors.indigo.shade300, Colors.amber.shade400, Colors.deepOrange.shade300,
      Colors.pink.shade200, Colors.lime.shade400,
      // Thêm màu nếu cần
    ];

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Canh giữa tiêu đề
          children: [
            Text(
              'Theo phân loại',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Nếu không có category nào (hoặc chỉ có "Chưa phân loại" với 0 task)
            if (sortedCategories.isEmpty ||
                (sortedCategories.length == 1 &&
                    sortedCategories.first.key == 'Chưa phân loại' &&
                    sortedCategories.first.value == 0))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Chưa có công việc nào được phân loại trong khoảng thời gian này.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                // Hiển thị danh sách category
                shrinkWrap: true, // Chỉ chiếm chiều cao cần thiết
                physics:
                    const NeverScrollableScrollPhysics(), // Không cho cuộn riêng lẻ
                itemCount: sortedCategories.length,
                separatorBuilder:
                    (_, __) => Divider(
                      // Đường kẻ phân cách
                      height: 16,
                      thickness: 0.5,
                      indent: 26,
                      endIndent: 10,
                      color: Colors.grey[200], // Màu đường kẻ nhạt hơn
                    ),
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final itemColor =
                      categoryColors[index %
                          categoryColors.length]; // Lấy màu xoay vòng
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          // Chấm màu category
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          // Tên category
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          // Số lượng task
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

  // Widget hiển thị trạng thái trống
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
        height: height, // Chiều cao của card
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
