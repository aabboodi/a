// backend/src/middleware/auth.js
const jwt = require('jsonwebtoken');
const redis = require('../config/redis');

const authMiddleware = async (req, res, next) => {
  try {
    // استخراج التوكن
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'غير مصرح',
      });
    }
    
    // التحقق من التوكن
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // التحقق من الجلسة في Redis
    const session = await redis.get(`session:${decoded.userId}`);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        message: 'جلسة منتهية',
      });
    }
    
    // إضافة معلومات المستخدم للطلب
    req.user = decoded;
    next();
    
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'جلسة منتهية',
      });
    }
    
    return res.status(401).json({
      success: false,
      message: 'توكن غير صالح',
    });
  }
};

// التحقق من الأدوار
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'غير مصرح',
      });
    }
    
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'غير مسموح',
      });
    }
    
    next();
  };
};

module.exports = { authMiddleware, requireRole };
