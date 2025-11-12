// backend/src/services/whatsappService.js
const axios = require('axios');

class WhatsAppService {
  constructor() {
    this.apiKey = null;
    this.phoneNumberId = null;
  }
  
  // تهيئة API
  setCredentials(apiKey, phoneNumberId) {
    this.apiKey = apiKey;
    this.phoneNumberId = phoneNumberId;
  }
  
  // إرسال رسالة لرقم واحد
  async sendMessage(phone, message) {
    if (!this.apiKey || !this.phoneNumberId) {
      throw new Error('WhatsApp API not configured');
    }
    
    try {
      // استخدام WhatsApp Business API
      const response = await axios.post(
        `https://graph.facebook.com/v18.0/${this.phoneNumberId}/messages`,
        {
          messaging_product: 'whatsapp',
          to: this._formatPhone(phone),
          type: 'text',
          text: { body: message },
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );
      
      return {
        success: true,
        messageId: response.data.messages[0].id,
      };
      
    } catch (error) {
      console.error('WhatsApp send error:', error.response?.data || error);
      return {
        success: false,
        error: error.response?.data?.error?.message || error.message,
      };
    }
  }
  
  // إرسال رسائل جماعية
  async sendBulkMessages(phones, message) {
    const results = [];
    
    // إرسال دفعة (Batch) من 50 رسالة في المرة
    for (let i = 0; i < phones.length; i += 50) {
      const batch = phones.slice(i, i + 50);
      
      const batchPromises = batch.map(phone => 
        this.sendMessage(phone, message)
          .then(result => ({ phone, ...result }))
          .catch(error => ({ phone, success: false, error: error.message }))
      );
      
      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);
      
      // انتظار 3 ثواني بين الدفعات لتجنب Rate Limiting
      if (i + 50 < phones.length) {
        await new Promise(resolve => setTimeout(resolve, 3000));
      }
    }
    
    return results;
  }
  
  // إرسال لجميع المتابعين والطلاب
  async sendToAll(message) {
    try {
      // جلب المتابعين
      const Contact = require('../models/Contact');
      const followers = await Contact.find({ isFollower: true });
      
      // جلب أرقام الطلاب
      const User = require('../models/User');
      const students = await User.find({ role: 'student', phone: { $exists: true } });
      
      // دمج الأرقام وإزالة التكرار
      const allPhones = new Set([
        ...followers.map(f => f.phone),
        ...students.map(s => s.phone),
      ]);
      
      // إرسال الرسائل
      const results = await this.sendBulkMessages(Array.from(allPhones), message);
      
      return {
        total: results.length,
        successful: results.filter(r => r.success).length,
        failed: results.filter(r => !r.success).length,
        results,
      };
      
    } catch (error) {
      console.error('Bulk send error:', error);
      throw error;
    }
  }
  
  // تنسيق رقم الهاتف (إضافة كود الدولة إذا لزم الأمر)
  _formatPhone(phone) {
    // إزالة المسافات والرموز
    let cleaned = phone.replace(/\D/g, '');
    
    // إضافة 963 للأرقام السورية إذا لم تكن موجودة
    if (cleaned.length === 9 && !cleaned.startsWith('963')) {
      cleaned = '963' + cleaned;
    }
    
    return cleaned;
  }
}

module.exports = new WhatsAppService();
