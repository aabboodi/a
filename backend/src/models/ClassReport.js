// backend/src/models/ClassReport.js
const classReportSchema = new mongoose.Schema({
  classId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: true,
  },
  sessionId: {
    type: String,
    required: true,
    unique: true,
  },
  className: {
    type: String,
    required: true,
  },
  teacherName: {
    type: String,
    required: true,
  },
  startTime: {
    type: Date,
    required: true,
  },
  endTime: {
    type: Date,
    required: true,
  },
  totalDuration: {
    type: Number, // بالثواني
    required: true,
  },
  attendees: [{
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    studentName: String,
    studentCode: String,
    duration: Number, // بالثواني
    joinedAt: Date,
    leftAt: Date,
  }],
  recordingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Recording',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

classReportSchema.index({ classId: 1, createdAt: -1 });
classReportSchema.index({ sessionId: 1 }, { unique: true });

module.exports = mongoose.model('ClassReport', classReportSchema);
