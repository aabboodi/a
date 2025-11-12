// backend/src/services/chatService.js
const jwt = require('jsonwebtoken');

class ChatService {
  initialize(io) {
    // Middleware للمصادقة
    io.use((socket, next) => {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication error'));
      }
      
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decoded.userId;
        socket.role = decoded.role;
        next();
      } catch (err) {
        next(new Error('Authentication error'));
      }
    });
    
    io.on('connection', (socket) => {
      console.log('User connected:', socket.userId);
      
      // التحقق من صلاحية الانضمام للصف
      socket.on('join-class', async ({ classId }) => {
        try {
          // التحقق من أن المستخدم مسجل في الصف
          const isAuthorized = await this.checkClassAuthorization(
            socket.userId,
            classId,
            socket.role
          );
          
          if (!isAuthorized) {
            socket.emit('error', { message: 'غير مصرح' });
            return;
          }
          
          socket.join(classId);
          // ... بقية الكود
        } catch (error) {
          socket.emit('error', { message: 'خطأ في الانضمام' });
        }
      });
      
      // التحقق من الرسائل
      socket.on('send-message', async (data) => {
        // تنظيف المحتوى من XSS
        const sanitizedContent = this.sanitizeMessage(data.content);
        
        // التحقق من الطول
        if (sanitizedContent.length > 1000) {
          socket.emit('error', { message: 'رسالة طويلة جداً' });
          return;
        }
        
        // Rate limiting للرسائل
        const canSend = await this.checkMessageRateLimit(socket.userId);
        if (!canSend) {
          socket.emit('error', { message: 'رسائل كثيرة جداً' });
          return;
        }
        
        // ... حفظ وبث الرسالة
      });
    });
  }
  
  sanitizeMessage(content) {
    // إزالة HTML tags
    const stripped = content.replace(/<[^>]*>/g, '');
    // إزالة JavaScript
    const cleaned = stripped.replace(/javascript:/gi, '');
    return cleaned.trim();
  }
  
  async checkMessageRateLimit(userId) {
    const key = `msg_limit:${userId}`;
    const count = await redis.incr(key);
    
    if (count === 1) {
      await redis.expire(key, 60); // دقيقة واحدة
    }
    
    return count <= 20; // 20 رسالة في الدقيقة
  }
  
  async checkClassAuthorization(userId, classId, role) {
    if (role === 'admin') return true;
    
    const classData = await Class.findById(classId);
    if (!classData) return false;
    
    if (role === 'teacher') {
      return classData.teacherId.toString() === userId;
    }
    
    if (role === 'student') {
      return classData.students.some(s => s.toString() === userId);
    }
    
    return false;
  }
}

module.exports = new ChatService();
