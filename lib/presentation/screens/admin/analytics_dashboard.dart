// lib/presentation/screens/admin/analytics_dashboard.dart
class AnalyticsDashboard extends StatefulWidget {
  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  Map<String, dynamic>? stats;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    try {
      final response = await ApiService().get('/analytics/daily');
      setState(() {
        stats = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ErrorHandler.handleError(e, context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'الإحصائيات اليومية',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          
          // بطاقات الإحصائيات
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'الجلسات النشطة',
                '${stats!['activeSessions']}',
                Icons.people,
                Colors.green,
              ),
              _buildStatCard(
                'إجمالي الصفوف',
                '${stats!['totalClasses']}',
                Icons.class_,
                Colors.blue,
              ),
              _buildStatCard(
                'إجمالي الطلاب',
                '${stats!['totalStudents']}',
                Icons.school,
                Colors.orange,
              ),
              _buildStatCard(
                'إجمالي المدرسين',
                '${stats!['totalTeachers']}',
                Icons.person,
                Colors.purple,
              ),
              _buildStatCard(
                'صفوف اليوم',
                '${stats!['todayClasses']}',
                Icons.today,
                Colors.teal,
              ),
              _buildStatCard(
                'تسجيلات اليوم',
                '${stats!['todayRecordings']}',
                Icons.videocam,
                Colors.red,
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // معدلات
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المعدلات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildProgressIndicator(
                    'معدل الحضور',
                    stats!['averageAttendance'],
                    Colors.green,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('متوسط مدة الصف:'),
                      Spacer(),
                      Text(
                        '${stats!['averageClassDuration']} دقيقة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // زر التقرير الشهري
          ElevatedButton.icon(
            onPressed: _showMonthlyReport,
            icon: Icon(Icons.assessment),
            label: Text('التقرير الشهري'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '$value%',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
           minHeight: 8,
        ),
      ],
    );
  }
  
  void _showMonthlyReport() {
    showDialog(
      context: context,
      builder: (context) => MonthlyReportDialog(),
    );
  }
}
