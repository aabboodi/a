// backend/src/models/Message.js
const messageSchema = new mongoose.Schema({
  classId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  userName: {
    type: String,
    required: true,
  },
  content: {
    type: String,
    required: true,
    maxlength: 1000,
  },
  role: {
    type: String,
    enum: ['teacher', 'student'],
    required: true,
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

// Indexes
messageSchema.index({ classId: 1, timestamp: -1 });

// TTL Index - حذف الرسائل بعد 90 يوم
messageSchema.index({ timestamp: 1 }, { expireAfterSeconds: 7776000 });

module.exports = mongoose.model('Message', messageSchema);
