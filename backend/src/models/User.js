// backend/src/models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  fullName: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ['admin', 'teacher', 'student'],
    required: true,
  },
  phone: String,
  age: Number,
  currentLevel: String,
  targetLevel: String,
  isNewStudent: {
    type: Boolean,
    default: true,
  },
  finalGrade: Number,
  createdAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

// Hash code قبل الحفظ (اختياري للأمان)
userSchema.pre('save', async function(next) {
  if (this.isModified('code') && this.code !== '0000') {
    this.code = await bcrypt.hash(this.code, 10);
  }
  next();
});

module.exports = mongoose.model('User', userSchema);
