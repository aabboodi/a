// lib/presentation/screens/admin/students_management_screen.dart
class StudentsManagementScreen extends StatefulWidget {
  @override
  _StudentsManagementScreenState createState() => _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  List<StudentModel> students = [];
  List<StudentModel> filteredStudents = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
    searchController.addListener(_filterStudents);
  }
  
  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    
    try {
      final response = await context.read<ApiService>().getStudents();
      setState(() {
        students = response;
        filteredStudents = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات')),
      );
    }
  }
  
  void _filterStudents() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredStudents = students.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
               student.code.contains(query) ||
               (student.phone?.contains(query) ?? false);
      }).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الطلاب'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddStudentDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'البحث بالاسم، الكود، أو رقم الهاتف...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // عداد الطلاب
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'إجمالي الطلاب: ${students.length}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'جدد: ${students.where((s) => s.isNewStudent).length}',
                        style: TextStyle(color: Colors.green[800]),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'قدامى: ${students.where((s) => !s.isNewStudent).length}',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // جدول الطلاب
          Expanded(
            child: isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: _buildStudentsTable(),
                  ),
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentsTable() {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
      columns: [
        DataColumn(label: Text('الاسم الثلاثي', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('الكود', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('العمر', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('المستوى الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('المستوى المطلوب', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('العلامة النهائية', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: filteredStudents.map((student) {
        final textColor = student.isNewStudent ? Colors.green : Colors.red;
        
        return DataRow(
          cells: [
            DataCell(Text(student.fullName, style: TextStyle(color: textColor))),
            DataCell(Text(student.code, style: TextStyle(color: textColor))),
            DataCell(Text(student.phone ?? '-', style: TextStyle(color: textColor))),
            DataCell(Text('${student.age ?? '-'}', style: TextStyle(color: textColor))),
            DataCell(Text(student.currentLevel ?? '-', style: TextStyle(color: textColor))),
            DataCell(Text(student.targetLevel ?? '-', style: TextStyle(color: textColor))),
            DataCell(Text(
              student.finalGrade != null ? '${student.finalGrade}' : '-',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            )),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditStudentDialog(student),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteStudent(student),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStudentDialog(
        onSave: (student) async {
          try {
            await context.read<ApiService>().addStudent(student);
            _loadStudents();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم إضافة الطالب بنجاح')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ في إضافة الطالب')),
            );
          }
        },
      ),
    );
  }
}
