// backend/src/middleware/fileUpload.js
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');

// قائمة الامتدادات المسموحة
const ALLOWED_VIDEO_TYPES = ['video/mp4', 'video/webm'];
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png'];

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../../uploads');
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // اسم فريد للملف
    const uniqueName = crypto.randomBytes(16).toString('hex');
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueName}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = [...ALLOWED_VIDEO_TYPES, ...ALLOWED_IMAGE_TYPES];
  
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('نوع ملف غير مسموح'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 500 * 1024 * 1024, // 500 MB
  },
});

module.exports = upload;
