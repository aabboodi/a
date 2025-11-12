// backend/src/utils/logger.js
const winston = require('winston');
const path = require('path');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'al-mahad-api' },
  transports: [
    // السجلات العادية
    new winston.transports.File({
      filename: path.join(__dirname, '../../logs/app.log'),
      level: 'info',
    }),
    
    // سجلات الأخطاء
    new winston.transports.File({
      filename: path.join(__dirname, '../../logs/error.log'),
      level: 'error',
    }),
    
    // سجلات الأمان
    new winston.transports.File({
      filename: path.join(__dirname, '../../logs/security.log'),
      level: 'warn',
    }),
  ],
});

// في بيئة التطوير
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    ),
  }));
}

// دوال مساعدة
logger.security = (message, meta) => {
  logger.warn(message, { ...meta, type: 'security' });
};

logger.audit = (action, userId, details) => {
  logger.info('Audit log', {
    type: 'audit',
    action,
    userId,
    details,
    timestamp: new Date().toISOString(),
  });
};

module.exports = logger;
// مثال في middleware
const logSecurityEvent = (req, res, next) => {
  // تسجيل محاولات الدخول الفاشلة
  const originalJson = res.json;
  
  res.json = function(data) {
    if (data.success === false && req.path.includes('login')) {
      logger.security('Failed login attempt', {
        ip: req.ip,
        userAgent: req.get('user-agent'),
        timestamp: new Date(),
      });
    }
    
    return originalJson.call(this, data);
  };
  
  next();
};

// تسجيل العمليات الحساسة
router.delete('/students/:id', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const student = await User.findByIdAndDelete(req.params.id);
    
    // تسجيل الحدث
    logger.audit('DELETE_STUDENT', req.user.userId, {
      studentId: req.params.id,
      studentName: student.fullName,
    });
    
    res.json({ success: true });
  } catch (error) {
    logger.error('Error deleting student', error);
    res.status(500).json({ success: false });
  }
});
