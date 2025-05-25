// lib/src/widgets/views/daily_summary_view.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class DailySummaryView extends StatefulWidget {
  const DailySummaryView({super.key});

  @override
  State<DailySummaryView> createState() => _DailySummaryViewState();
}

class _DailySummaryViewState extends State<DailySummaryView> {
  String? _selectedDate;
  int _touchedPieIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final availableDates = gameProvider.completedByDay.keys.toList();
    availableDates.sort((a, b) => b.compareTo(a)); 
    if (_selectedDate == null && availableDates.isNotEmpty) {
      _selectedDate = availableDates.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    final availableDates = gameProvider.completedByDay.keys.toList();
    availableDates.sort((a, b) => b.compareTo(a)); 

    if (_selectedDate == null && availableDates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDate = availableDates.first);
      });
    } else if (_selectedDate != null && !availableDates.contains(_selectedDate) && availableDates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDate = availableDates.first);
      });
    } else if (availableDates.isEmpty && _selectedDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDate = null);
      });
    }

    final summaryData = _selectedDate != null ? gameProvider.completedByDay[_selectedDate!] : null;
    final taskTimes = summaryData?['taskTimes'] as Map<String, dynamic>? ?? {};
    final subtasksCompleted = summaryData?['subtasksCompleted'] as List<dynamic>? ?? [];
    final checkpointsCompleted = summaryData?['checkpointsCompleted'] as List<dynamic>? ?? [];

    final double totalMinutesToday = taskTimes.values.fold(0.0, (sum, time) => sum + (time as num).toDouble());

    final List<PieChartSectionData> pieChartSections = [];
    final List<Widget> legendItems = [];
    if (taskTimes.isNotEmpty) {
      // int colorIndex = 0; // Removed unused variable
      taskTimes.forEach((taskId, time) {
        final task = gameProvider.mainTasks.firstWhere((t) => t.id == taskId, orElse: () => MainTask(id:'', name:'Unknown Quest', description:'', theme:'', colorHex: AppTheme.fhTextDisabled.value.toRadixString(16).substring(2)));
        final taskColor = task.taskColor; // Uses getter from MainTask model

        if (task.id != '') {
          final isTouched = pieChartSections.length == _touchedPieIndex;
          final fontSize = isTouched ? 13.0 : 11.0;
          final radius = isTouched ? 65.0 : 55.0; // Slightly larger pie
          final titlePercentage = totalMinutesToday > 0 ? ((time as num).toDouble() / totalMinutesToday * 100) : 0.0;

          pieChartSections.add(PieChartSectionData(
            color: taskColor, // Use task's theme color
            value: (time).toDouble(),
            title: '${titlePercentage.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: AppTheme.fhBgDark, fontFamily: AppTheme.fontDisplay, shadows: const [Shadow(color: Colors.black38, blurRadius: 2)]),
            titlePositionPercentageOffset: 0.6,
          ));
          legendItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12,
                   decoration: BoxDecoration(
                       color: taskColor,
                       border: Border.all(color: AppTheme.fhBorderColor.withOpacity(0.5), width: 0.5)
                   )),
                  const SizedBox(width: 8),
                  Text(task.name.split(' ')[0], style: TextStyle(fontSize: 12, color: AppTheme.fhTextSecondary, fontFamily: AppTheme.fontBody)),
                ],
              ),
            )
          );
          // colorIndex++; // Removed unused increment
        }
      });
    }

    final List<BarChartGroupData> weeklyBarGroups = [];
    final today = DateTime.now();
    final List<String> last7DaysFormatted = [];
    for (int i = 6; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        final dayData = gameProvider.completedByDay[dateStr];
        final Map<String, dynamic> dailyTaskTimes = dayData != null && dayData['taskTimes'] != null
            ? dayData['taskTimes'] as Map<String, dynamic>
            : {};
        
        double dailyTotalMins = 0;
        String? dominantTaskId;
        int maxTime = 0;

        dailyTaskTimes.forEach((taskId, time) {
            final int currentTime = (time as num).toInt();
            dailyTotalMins += currentTime;
            if (currentTime > maxTime) {
                maxTime = currentTime;
                dominantTaskId = taskId;
            }
        });
        
        Color barColor = AppTheme.fhAccentTeal; // Default bar color
        if (dominantTaskId != null) {
            final dominantTask = gameProvider.mainTasks.firstWhere((t) => t.id == dominantTaskId, orElse: () => MainTask(id:'', name:'', description:'', theme:'', colorHex: AppTheme.fhAccentTeal.value.toRadixString(16).substring(2)));
            barColor = dominantTask.taskColor;
        }

        weeklyBarGroups.add(
            BarChartGroupData(
                x: 6 - i, 
                barRods: [
                    BarChartRodData(
                        toY: dailyTotalMins,
                        color: barColor.withOpacity(0.85),
                        width: 18, // Wider bars
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3))
                    )
                ],
            )
        );
        last7DaysFormatted.add(DateFormat('EEE, MMM d').format(d));
    }


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.bookOpenVariant, color: AppTheme.fhAccentRed, size: 36), // Use primary accent
                const SizedBox(width: 12),
                Text("Mission Logbook", style: theme.textTheme.displaySmall?.copyWith(color: AppTheme.fhTextPrimary)),
              ],
            ),
          ),

          if (availableDates.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text("No mission logs recorded yet.", style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.fhTextSecondary, fontStyle: FontStyle.italic)),
            ))
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedDate,
              decoration: const InputDecoration(labelText: 'Select Date'),
              dropdownColor: AppTheme.fhBgMedium, // Darker dropdown
              items: availableDates.map((date) {
                return DropdownMenuItem(
                  value: date,
                  child: Text(DateFormat('MMMM d, yyyy (EEEE)').format(DateTime.parse(date))),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDate = value),
            ),
            const SizedBox(height: 24),
            if (_selectedDate != null)
              Card(
                color: AppTheme.fhBgMedium,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total Time Logged on ${DateFormat('MMMM d, yyyy').format(DateTime.parse(_selectedDate!))}: ${totalMinutesToday.toStringAsFixed(0)}m',
                    style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.fhAccentGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            if (pieChartSections.isNotEmpty) ...[
              Text("Time Distribution by Mission:", style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3, // Give more space to pie chart
                    child: SizedBox(
                      height: 220, // Larger pie chart
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1; return;
                                }
                                _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2, // Space between sections
                          centerSpaceRadius: 50, // Larger center space
                          sections: pieChartSections,
                        ),
                      ),
                    ),
                  ),
                  if (legendItems.isNotEmpty)
                    Expanded(
                      flex: 2, // More space for legend
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: legendItems,
                        ),
                      )
                    )
                ],
              ),
              const SizedBox(height: 30),
            ],

            Text("Last 7 Days Activity (Total Minutes):", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            SizedBox(
                height: 280, // Taller bar chart
                child: BarChart(
                    BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: weeklyBarGroups.map((g) => g.barRods.first.toY).reduce((a,b) => a > b ? a : b) * 1.2 + 15, 
                        barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (BarChartGroupData group) => AppTheme.fhBgMedium,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                        '${last7DaysFormatted[group.x]}\n',
                                        TextStyle(color: AppTheme.fhTextPrimary, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontDisplay),
                                        children: <TextSpan>[
                                            TextSpan(
                                                text: '${rod.toY.toStringAsFixed(0)} min',
                                                style: TextStyle(color: rod.color ?? AppTheme.fhAccentTeal, fontWeight: FontWeight.w500, fontFamily: AppTheme.fontBody),
                                            ),
                                        ],
                                    );
                                },
                            ),
                        ),
                        titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                        return SideTitleWidget(
                                            meta: meta,
                                            space: 10.0, // More space for titles
                                            child: Text(last7DaysFormatted[value.toInt()].substring(0,3).toUpperCase(), style: TextStyle(color: AppTheme.fhTextSecondary, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: AppTheme.fontDisplay)),
                                        );
                                    },
                                    reservedSize: 38, // Increased reserved size
                                ),
                            ),
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45, // Increased reserved size
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                        if (value == meta.max || (value == 0 && meta.max > 20)) {
                                          return SideTitleWidget(meta: meta, child: Container());
                                        }
                                        return SideTitleWidget(meta: meta, child: Text('${value.toInt()}', style: TextStyle(color: AppTheme.fhTextSecondary, fontSize: 11, fontFamily: AppTheme.fontBody)));
                                    }
                                ),
                            ),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.fhBorderColor.withOpacity(0.2), width:1)),
                        barGroups: weeklyBarGroups,
                        gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true, // Show vertical grid lines
                            verticalInterval: 1,
                            horizontalInterval: (weeklyBarGroups.map((g) => g.barRods.first.toY).reduce((a,b) => a > b ? a : b) / 5).clamp(10, 1000), // Dynamic horizontal interval
                            getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.fhBorderColor.withOpacity(0.1), strokeWidth: 0.8),
                            getDrawingVerticalLine: (value) => FlLine(color: AppTheme.fhBorderColor.withOpacity(0.1), strokeWidth: 0.8),
                        ),
                    ),
                ),
            ),
            const SizedBox(height: 30),

            if (_selectedDate != null) ... [
              Text('Activity Details for ${DateFormat('MMMM d').format(DateTime.parse(_selectedDate!))}:', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Card(
                color: AppTheme.fhBgMedium,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (taskTimes.isEmpty && subtasksCompleted.isEmpty && checkpointsCompleted.isEmpty)
                        Text("No specific activity recorded for this day.", style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fhTextSecondary, fontStyle: FontStyle.italic))
                      else ...[
                        ...taskTimes.entries.map((entry) {
                          final task = gameProvider.mainTasks.firstWhere((t) => t.id == entry.key, orElse: () => MainTask(id:'', name:'Unknown Task', description:'', theme:'', colorHex: AppTheme.fhTextDisabled.value.toRadixString(16).substring(2)));
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Text('${task.name}: ${entry.value}m', style: theme.textTheme.bodyMedium?.copyWith(color: task.taskColor)),
                          );
                        }),
                        if (subtasksCompleted.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('Sub-Missions Completed:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ...subtasksCompleted.map((subEntryMap) {
                              final subEntry = subEntryMap as Map<String, dynamic>;
                              final parentTask = gameProvider.mainTasks.firstWhere((t) => t.id == subEntry['parentTaskId'], orElse: () => MainTask(id:'', name:'Unknown Task', description:'', theme:''));
                              return Padding(
                               padding: const EdgeInsets.only(left: 16.0, top: 3.0),
                               child: Text(
                                 '- ${subEntry['name']} (for ${parentTask.name}) - Logged: ${subEntry['timeLogged']}m, Count: ${subEntry['currentCount']}/${subEntry['targetCount']}',
                                 style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhTextSecondary),
                               ),
                             );
                          }),
                        ],
                        if (checkpointsCompleted.isNotEmpty) ...[
                          const SizedBox(height: 10),
                           Text('Checkpoints Completed:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ...checkpointsCompleted.map((cpEntryMap) {
                              final cpEntry = cpEntryMap as Map<String, dynamic>;
                              final String mainTaskName = cpEntry['mainTaskName'] as String? ?? 'N/A';
                              final String parentSubtaskName = cpEntry['parentSubtaskName'] as String? ?? 'N/A';
                              final String countableInfo = (cpEntry['isCountable'] as bool? ?? false)
                                ? " (${cpEntry['currentCount']}/${cpEntry['targetCount']})"
                                : "";
                              return Padding(
                               padding: const EdgeInsets.only(left: 16.0, top: 3.0),
                               child: Text(
                                 '- ${cpEntry['name']}$countableInfo (Sub-Mission: "$parentSubtaskName" in "$mainTaskName")',
                                 style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhAccentTeal.withOpacity(0.85)),
                               ),
                             );
                          }),
                        ]
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}