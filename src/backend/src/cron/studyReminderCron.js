/**
 * ========================================
 * Study Reminder Cron Scheduler
 * ========================================
 */

const cron = require('node-cron');
const studyReminderService = require('../services/studyReminderService');

/**
 * Khởi tạo toàn bộ cron jobs nhắc học
 */
const initStudyReminderCron = () => {
  console.log('⏰ [Cron] Initializing Study Reminder Schedulers...');

  // 1. Nhắc học hằng ngày lần 1 lúc 18:00
  cron.schedule('0 18 * * *', async () => {
    try {
      await studyReminderService.checkAndSendDailyReminders('daily_first');
    } catch (err) {
      console.error('❌ [Cron] Error running daily_first reminder job:', err);
    }
  }, {
    timezone: 'Asia/Ho_Chi_Minh'
  });

  // 2. Nhắc học hằng ngày lần 2 lúc 20:00
  cron.schedule('0 20 * * *', async () => {
    try {
      await studyReminderService.checkAndSendDailyReminders('daily_second');
    } catch (err) {
      console.error('❌ [Cron] Error running daily_second reminder job:', err);
    }
  }, {
    timezone: 'Asia/Ho_Chi_Minh'
  });

  // 3. Nhắc duy trì chuỗi ngày lúc 22:00
  cron.schedule('0 22 * * *', async () => {
    try {
      await studyReminderService.checkAndSendStreakReminders();
    } catch (err) {
      console.error('❌ [Cron] Error running streak reminder job:', err);
    }
  }, {
    timezone: 'Asia/Ho_Chi_Minh'
  });

  // 4. Nhắc quay lại app lúc 10:00 sáng
  cron.schedule('0 10 * * *', async () => {
    try {
      await studyReminderService.checkAndSendComebackReminders();
    } catch (err) {
      console.error('❌ [Cron] Error running comeback reminder job:', err);
    }
  }, {
    timezone: 'Asia/Ho_Chi_Minh'
  });

  console.log('✅ [Cron] Study Reminder Schedulers started successfully (Timezone: Asia/Ho_Chi_Minh)');
};

module.exports = {
  initStudyReminderCron
};
