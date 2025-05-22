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
    availableDates.sort((a, b) => b.compareTo(a)); // Sort descending
    if (_selectedDate == null && availableDates.isNotEmpty) {
      _selectedDate = availableDates.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    final availableDates = gameProvider.completedByDay.keys.toList();
    availableDates.sort((a, b) => b.compareTo(a)); // Sort descending

    if (_selectedDate == null && availableDates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDate = availableDates.first;
          });
        }
      });
    } else if (_selectedDate != null && !availableDates.contains(_selectedDate) && availableDates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDate = availableDates.first;
          });
        }
      });
    } else if (availableDates.isEmpty && _selectedDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDate = null;
          });
        }
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
      final List<Color> chartColors = [
        AppTheme.fhAccentTeal, AppTheme.fhAccentOrange, AppTheme.fhAccentBrightBlue,
        AppTheme.fhAccentPurple, AppTheme.fhAccentGreen, // Re-using Orange for variety if many items
        Colors.teal, Colors.redAccent, Colors.indigoAccent
      ];
      int colorIndex = 0;
      taskTimes.forEach((taskId, time) {
        final task = gameProvider.mainTasks.firstWhere((t) => t.id == taskId, orElse: () => MainTask(id:'', name:'Unknown Quest', description:'', theme:''));
        if (task.id != '') {
          final isTouched = pieChartSections.length == _touchedPieIndex;
          final fontSize = isTouched ? 13.0 : 11.0;
          final radius = isTouched ? 60.0 : 50.0;
          final titlePercentage = totalMinutesToday > 0 ? ((time as num).toDouble() / totalMinutesToday * 100) : 0.0;

          pieChartSections.add(PieChartSectionData(
            color: chartColors[colorIndex % chartColors.length],
            value: (time).toDouble(),
            title: '${titlePercentage.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: AppTheme.fhBgDark, fontFamily: AppTheme.fontMain, shadows: const [Shadow(color: Colors.black26, blurRadius: 2)]),
            titlePositionPercentageOffset: 0.65,
          ));
          legendItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: chartColors[colorIndex % chartColors.length]),
                  const SizedBox(width: 6),
                  Text('${task.name.split(' ')[0]} ', style: const TextStyle(fontSize: 11, color: AppTheme.fhTextSecondary, fontFamily: AppTheme.fontBody)),
                ],
              ),
            )
          );
          colorIndex++;
        }
      });
    }

    // Weekly Bar Chart Data
    final List<BarChartGroupData> weeklyBarGroups = [];
    final today = DateTime.now();
    final List<String> last7DaysFormatted = [];
    for (int i = 6; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        final dayData = gameProvider.completedByDay[dateStr];
        final double dailyTotalMins = dayData != null && dayData['taskTimes'] != null
            ? (dayData['taskTimes'] as Map).values.fold(0.0, (sum, time) => sum + (time as num).toDouble())
            : 0.0;

        weeklyBarGroups.add(
            BarChartGroupData(
                x: 6 - i, // 0 for 6 days ago, 6 for today
                barRods: [
                    BarChartRodData(
                        toY: dailyTotalMins,
                        color: AppTheme.fhAccentTeal.withOpacity(0.8),
                        width: 16,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
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
                Icon(MdiIcons.bookOpenOutline, color: AppTheme.fhAccentTeal, size: 32),
                const SizedBox(width: 12),
                Text("Daily Logbook", style: theme.textTheme.headlineSmall?.copyWith(fontFamily: AppTheme.fontMain, color: AppTheme.fhAccentTeal)),
              ],
            ),
          ),

          if (availableDates.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text("No logs recorded yet.", style: TextStyle(color: AppTheme.fhTextSecondary, fontStyle: FontStyle.italic)),
            ))
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedDate,
              decoration: const InputDecoration(labelText: 'Select Date'),
              dropdownColor: AppTheme.fhBgLight,
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total Time Logged on ${DateFormat('MMMM d, yyyy').format(DateTime.parse(_selectedDate!))}: ${totalMinutesToday.toStringAsFixed(0)}m',
                    style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.fhAccentGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            if (pieChartSections.isNotEmpty) ...[
              Text("Time Distribution by Quest:", style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: pieChartSections,
                        ),
                      ),
                    ),
                  ),
                  if (legendItems.isNotEmpty)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: legendItems,
                        ),
                      )
                    )
                ],
              ),
              const SizedBox(height: 24),
            ],

            Text("Last 7 Days Activity (Total Minutes):", style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
                height: 250,
                child: BarChart(
                    BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: weeklyBarGroups.map((g) => g.barRods.first.toY).reduce((a,b) => a > b ? a : b) * 1.2 + 10, // Dynamic maxY
                        barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (BarChartGroupData group) => AppTheme.fhBgLight,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                        '${last7DaysFormatted[group.x]}\n',
                                        const TextStyle(color: AppTheme.fhTextPrimary, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontBody),
                                        children: <TextSpan>[
                                            TextSpan(
                                                text: '${rod.toY.toStringAsFixed(0)} min',
                                                style: const TextStyle(color: AppTheme.fhAccentTeal, fontWeight: FontWeight.w500, fontFamily: AppTheme.fontBody),
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
                                            space: 8.0,
                                            child: Text(last7DaysFormatted[value.toInt()].substring(0,3), style: const TextStyle(color: AppTheme.fhTextSecondary, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: AppTheme.fontMain)),
                                        );
                                    },
                                    reservedSize: 30,
                                ),
                            ),
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                            if (value == meta.max || (value == 0 && meta.max > 20)) return Container();
                                        return Text('${value.toInt()}', style: const TextStyle(color: AppTheme.fhTextSecondary, fontSize: 10, fontFamily: AppTheme.fontMain));
                                    }
                                ),
                            ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: weeklyBarGroups,
                        gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.fhBorderColor.withOpacity(0.3), strokeWidth: 0.5),
                        ),
                    ),
                ),
            ),
            const SizedBox(height: 24),

            if (_selectedDate != null) ... [
              Text('Activity Details for ${DateFormat('MMMM d').format(DateTime.parse(_selectedDate!))}:', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (taskTimes.isEmpty && subtasksCompleted.isEmpty && checkpointsCompleted.isEmpty)
                        const Text("No specific activity recorded for this day.", style: TextStyle(color: AppTheme.fhTextSecondary, fontStyle: FontStyle.italic))
                      else ...[
                        ...taskTimes.entries.map((entry) {
                          final task = gameProvider.mainTasks.firstWhere((t) => t.id == entry.key, orElse: () => MainTask(id:'', name:'Unknown Task', description:'', theme:''));
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text('${task.name}: ${entry.value}m', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhAccentOrange)),
                          );
                        }),
                        if (subtasksCompleted.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Sub-Quests Completed:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ...subtasksCompleted.map((subEntryMap) {
                              final subEntry = subEntryMap as Map<String, dynamic>;
                              final parentTask = gameProvider.mainTasks.firstWhere((t) => t.id == subEntry['parentTaskId'], orElse: () => MainTask(id:'', name:'Unknown Task', description:'', theme:''));
                              return Padding(
                               padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                               child: Text(
                                 '- ${subEntry['name']} (for ${parentTask.name}) - Logged: ${subEntry['timeLogged']}m, Count: ${subEntry['currentCount']}/${subEntry['targetCount']}',
                                 style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhTextSecondary),
                               ),
                             );
                          }),
                        ],
                        if (checkpointsCompleted.isNotEmpty) ...[
                          const SizedBox(height: 8),
                           Text('Checkpoints Completed:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ...checkpointsCompleted.map((cpEntryMap) {
                              final cpEntry = cpEntryMap as Map<String, dynamic>;
                              final String mainTaskName = cpEntry['mainTaskName'] as String? ?? 'N/A';
                              final String parentSubtaskName = cpEntry['parentSubtaskName'] as String? ?? 'N/A';
                              final String countableInfo = (cpEntry['isCountable'] as bool? ?? false)
                                ? " (${cpEntry['currentCount']}/${cpEntry['targetCount']})"
                                : "";
                              return Padding(
                               padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                               child: Text(
                                 '- ${cpEntry['name']}$countableInfo (for Sub-Quest: "$parentSubtaskName" in Quest: "$mainTaskName")',
                                 style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhAccentLightCyan.withOpacity(0.8)),
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