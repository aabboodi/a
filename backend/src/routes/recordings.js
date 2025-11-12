// backend/src/routes/recordings.js
router.get('/:id/download', authMiddleware, async (req, res) => {
  try {
    const recording = await Recording.findById(req.params.id);
    
    if (!recording) {
      return res.status(404).json({
        success: false,
        message: 'التسجيل غير موجود',
      });
    }
    
    // التحقق من الصلاحية
    const classData = await Class.findById(recording.classId);
    
    const isAuthorized = 
      req.user.role === 'admin' ||
      classData.teacherId.toString() === req.user.userId ||
      classData.students.some(s => s.toString() === req.user.userId);
    
    if (!isAuthorized) {
      return res.status(403).json({
        success: false,
        message: 'غير مصرح',
      });
    }
    
    // إرسال الملف
    const filePath = path.resolve(recording.filePath);
    
    // التحقق من وجود الملف
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        success: false,
        message: 'الملف غير موجود',
      });
    }
    
    // تسجيل التنزيل
    await Recording.findByIdAndUpdate(req.params.id, {
      $inc: { downloadCount: 1 },
    });
    
    // إرسال الملف مع دعم Range requests
    res.sendFile(filePath);
    
  } catch (error) {
    console.error('Download error:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في التنزيل',
    });
  }
});
