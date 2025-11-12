// lib/presentation/widgets/grades_dialog.dart
class GradesDialog extends StatefulWidget {
  final ClassModel classData;
  final List<StudentModel> students;
  
  const GradesDialog({
    required this.classData,
    required this.students,
  });
  
  @override
  _GradesDialogState createState() => _GradesDialogState();
}

class _GradesDialogState extends State<GradesDialog> {
  Map<String, GradeEntry> grades = {};
  
  @override
  void initState() {
    super.initState();
    // تحميل العلامات المحفوظة
    _loadGrades();
  }
  
  Future<void> _loadGrades() async {
    try {
      final response = await ApiService().get(
        '/classes/${widget.classData.id}/grades'
      );
      
      setState(() {
        grades = Map.fromEntries(
          (response['grades'] as List).map((g) {
            final entry = GradeEntry.fromJson(g);
            return MapEntry(entry.studentId, entry);
          }),
        );
      });
    } catch (e) {
      print('Error loading grades: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // عنوان
            Row(
              children: [
                Text(
                  'إدخال العلامات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            Divider(),
            
            // جدول العلامات
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: _buildGradesTable(),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // أزرار الحفظ
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveGrades,
                  icon: Icon(Icons.save),
                  label: Text('حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGradesTable() {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
      columnSpacing: 20,
      columns: [
        DataColumn(label: Text('الاسم الثلاثي')),
        DataColumn(label: Text('الكود')),
        DataColumn(label: Text('التفاعل\n(7)')),
        DataColumn(label: Text('التمارين\n(7)')),
        DataColumn(label: Text('الشفهي\n(60)')),
        DataColumn(label: Text('الخطي\n(7)')),
        DataColumn(label: Text('النهائية\n(81)')),
      ],
      rows: widget.students.map((student) {
        final grade = grades[student.id] ?? GradeEntry(studentId: student.id);
        
        return DataRow(
          cells: [
            DataCell(Text(student.fullName)),
            DataCell(Text(student.code)),
            DataCell(_buildGradeField(
              studentId: student.id,
              field: 'interaction',
              max: 7,
              current: grade.interaction,
            )),
            DataCell(_buildGradeField(
              studentId: student.id,
              field: 'homework',
              max: 7,
              current: grade.homework,
            )),
            DataCell(_buildGradeField(
              studentId: student.id,
              field: 'oralExam',
              max: 60,
              current: grade.oralExam,
            )),
            DataCell(_buildGradeField(
              studentId: student.id,
              field: 'writtenExam',
              max: 7,
              current: grade.writtenExam,
            )),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGradeColor(grade.total),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${grade.total.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildGradeField({
    required String studentId,
    required String field,
    required int max,
    required double current,
  }) {
    return Container(
      width: 60,
      child: TextField(
        controller: TextEditingController(
          text: current > 0 ? current.toString() : '',
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.all(8),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          final grade = double.tryParse(value) ?? 0;
          
          if (grade > max) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('الحد الأقصى: $max')),
            );
            return;
          }
          
          setState(() {
            if (grades[studentId] == null) {
              grades[studentId] = GradeEntry(studentId: studentId);
            }
            
            switch (field) {
              case 'interaction':
                grades[studentId]!.interaction = grade;
                break;
              case 'homework':
                grades[studentId]!.homework = grade;
                break;
              case 'oralExam':
                grades[studentId]!.oralExam = grade;
                break;
              case 'writtenExam':
                grades[studentId]!.writtenExam = grade;
                break;
            }
          });
        },
      ),
    );
  }
  
  Color _getGradeColor(double grade) {
    if (grade >= 70) return Colors.green;
    if (grade >= 50) return Colors.orange;
    return Colors.red;
  }
  
  Future<void> _saveGrades() async {
    try {
      await ApiService().post('/classes/${widget.classData.id}/grades', {
        'grades': grades.values.map((g) => g.toJson()).toList(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ العلامات بنجاح')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ العلامات')),
      );
    }
  }
}

class GradeEntry {
  final String studentId;
  double interaction;
  double homework;
  double oralExam;
  double writtenExam;
  
  GradeEntry({
    required this.studentId,
    this.interaction = 0,
    this.homework = 0,
    this.oralExam = 0,
    this.writtenExam = 0,
  });
  
  double get total => interaction + homework + oralExam + writtenExam;
  
  factory GradeEntry.fromJson(Map<String, dynamic> json) {
    return GradeEntry(
      studentId: json['studentId'],
      interaction: json['interaction']?.toDouble() ?? 0,
      homework: json['homework']?.toDouble() ?? 0,
      oralExam: json['oralExam']?.toDouble() ?? 0,
      writtenExam: json['writtenExam']?.toDouble() ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'interaction': interaction,
      'homework': homework,
      'oralExam': oralExam,
      'writtenExam': writtenExam,
      'total': total,
    };
  }
}
