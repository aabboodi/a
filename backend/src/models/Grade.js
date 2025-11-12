// backend/src/models/Grade.js
const gradeSchema = new mongoose.Schema({
  classId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: true,
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  interaction: {
    type: Number,
    min: 0,
    max: 7,
    default: 0,
  },
  homework: {
    type: Number,
    min: 0,
    max: 7,
    default: 0,
  },
  oralExam: {
    type: Number,
    min: 0,
    max: 60,
    default: 0,
  },
  writtenExam: {
    type: Number,
    min: 0,
    max: 7,
    default: 0,
  },
  total: {
    type: Number,
    min: 0,
    max: 81,
    default: 0,
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, {
  timestamps: true,
});

gradeSchema.index({ classId: 1, studentId: 1 }, { unique: true });

// حساب المجموع تلقائياً
gradeSchema.pre('save', function(next) {
  this.total = this.interaction + this.homework + this.oralExam + this.writtenExam;
  next();
});

// تحديث العلامة النهائية للطالب
gradeSchema.post('save', async function(doc) {
  const User = mongoose.model('User');
  await User.findByIdAndUpdate(doc.studentId, {
    finalGrade: doc.total,
  });
});

module.exports = mongoose.model('Grade', gradeSchema);
