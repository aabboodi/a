// lib/presentation/screens/admin/admin_dashboard_screen.dart
class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم المدير'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
     body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            title: 'إدارة المدرسين',
            icon: Icons.school,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/admin/teachers'),
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة الصفوف',
            icon: Icons.class_,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/admin/classes'),
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة الطلاب',
            icon: Icons.people,
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/admin/students'),
          ),
          _buildDashboardCard(
            context,
            title: 'الأرشيف',
            icon: Icons.archive,
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/admin/archive'),
          ),
          _buildDashboardCard(
            context,
            title: 'البيئة المستهدفة',
            icon: Icons.message,
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, '/admin/messaging'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
