// backend/src/models/Recording.js
const recordingSchema = new mongoose.Schema({
  classId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: true,
  },
  sessionId: {
    type: String,
    required: true,
  },
  filename: {
    type: String,
    required: true,
  },
  filePath: {
    type: String,
    required: true,
  },
  thumbnailPath: String,
  duration: {
    type: Number, // بالثواني
    required: true,
  },
  size: {
    type: Number, // بالبايت
    required: true,
  },
  downloadCount: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

recordingSchema.index({ classId: 1, createdAt: -1 });

module.exports = mongoose.model('Recording', recordingSchema);
