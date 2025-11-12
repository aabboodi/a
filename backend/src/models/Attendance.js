// backend/src/models/Attendance.js
const attendanceSchema = new mongoose.Schema({
  classId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: true,
  },
  sessionId: {
    type: String,
    required: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  joinedAt: {
    type: Date,
    required: true,
  },
  leftAt: Date,
  totalDuration: {
    type: Number, // بالثواني
    default: 0,
  },
  isPresent: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
});

attendanceSchema.index({ classId: 1, sessionId: 1, userId: 1 }, { unique: true });

// حساب المدة الإجمالية عند المغادرة
attendanceSchema.pre('save', function(next) {
  if (this.leftAt && this.joinedAt) {
    const duration = (this.leftAt - this.joinedAt) / 1000; // بالثواني
    this.totalDuration = Math.floor(duration);
  }
  next();
});

module.exports = mongoose.model('Attendance', attendanceSchema);
