// backend/src/services/analyticsService.js
class AnalyticsService {
  // إحصائيات الاستخدام اليومية
  async getDailyStats() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const stats = {
      activeSessions: await this.getActiveSessions(),
      totalClasses: await Class.countDocuments(),
      totalStudents: await User.countDocuments({ role: 'student' }),
      totalTeachers: await User.countDocuments({ role: 'teacher' }),
      todayClasses: await ClassReport.countDocuments({
        createdAt: { $gte: today },
      }),
      todayRecordings: await Recording.countDocuments({
        createdAt: { $gte: today },
      }),
      averageClassDuration: await this.getAverageClassDuration(),
      averageAttendance: await this.getAverageAttendance(),
    };
    
    return stats;
  }
  
  // معدل الحضور
  async getAverageAttendance() {
    const reports = await ClassReport.find()
      .limit(30)
      .sort({ createdAt: -1 });
    
    if (reports.length === 0) return 0;
    
    const totalAttendance = reports.reduce((sum, report) => {
      const classData = await Class.findById(report.classId);
      const attendanceRate = (report.attendees.length / classData.students.length) * 100;
      return sum + attendanceRate;
    }, 0);
    
    return Math.round(totalAttendance / reports.length);
  }
  
  // متوسط مدة الصفوف
  async getAverageClassDuration() {
    const result = await ClassReport.aggregate([
      {
        $group: {
          _id: null,
          avgDuration: { $avg: '$totalDuration' },
        },
      },
    ]);
    
    if (result.length === 0) return 0;
    
    return Math.round(result[0].avgDuration / 60); // بالدقائق
  }
  
  // الصفوف النشطة حالياً
  async getActiveSessions() {
    // عدد الاتصالات النشطة في Socket.io
    const io = require('../app').io;
    return io.sockets.sockets.size;
  }
  
  // تقرير شامل شهري
  async getMonthlyReport(year, month) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);
    
    const reports = await ClassReport.find({
      createdAt: { $gte: startDate, $lte: endDate },
    }).populate('classId');
    
    const teacherStats = {};
    const classStats = {};
    
    for (const report of reports) {
      const teacherId = report.classId.teacherId.toString();
      const classId = report.classId._id.toString();
      
      // إحصائيات المدرسين
      if (!teacherStats[teacherId]) {
        teacherStats[teacherId] = {
          teacherName: report.teacherName,
          totalClasses: 0,
          totalDuration: 0,
          totalStudents: new Set(),
        };
      }
      
      teacherStats[teacherId].totalClasses++;
      teacherStats[teacherId].totalDuration += report.totalDuration;
      report.attendees.forEach(a => 
        teacherStats[teacherId].totalStudents.add(a.studentId.toString())
      );
      
      // إحصائيات الصفوف
      if (!classStats[classId]) {
        classStats[classId] = {
          className: report.className,
          totalSessions: 0,
          averageAttendance: 0,
          totalDuration: 0,
        };
      }
      
      classStats[classId].totalSessions++;
      classStats[classId].totalDuration += report.totalDuration;
    }
    
    // حساب معدلات الحضور
    for (const classId in classStats) {
      const classData = await Class.findById(classId);
      const sessionsReports = reports.filter(
        r => r.classId._id.toString() === classId
      );
      
      const avgAttendance = sessionsReports.reduce((sum, r) => {
        return sum + (r.attendees.length / classData.students.length);
      }, 0) / sessionsReports.length;
      
      classStats[classId].averageAttendance = Math.round(avgAttendance * 100);
    }
    
    return {
      period: { year, month },
      totalSessions: reports.length,
      totalDuration: reports.reduce((sum, r) => sum + r.totalDuration, 0),
      teacherStats: Object.values(teacherStats).map(t => ({
        ...t,
        totalStudents: t.totalStudents.size,
      })),
      classStats: Object.values(classStats),
    };
  }
}

module.exports = new AnalyticsService();
