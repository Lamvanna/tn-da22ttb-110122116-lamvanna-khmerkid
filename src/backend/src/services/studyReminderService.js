/**
 * ========================================
 * Study Reminder Service
 * ========================================
 * 
 * Quản lý gửi thông báo nhắc nhở học tập hàng ngày,
 * nhắc nhở duy trì chuỗi (streak) và nhắc nhở quay lại app.
 */

const User = require('../models/User');
const Progress = require('../models/Progress');
const Notification = require('../models/Notification');
const { NOTIFICATION_TYPES, SOCKET_EVENTS } = require('../constants');
const { emitToUser } = require('../sockets');

// 10 mẫu thông báo thân thiện cho trẻ 6-12 tuổi
const REMINDER_MESSAGES = [
  { id: 'msg1', title: '🥹 Bé ơi...', message: 'Bài học nhớ bé quá rồi nè...' },
  { id: 'msg2', title: '🐘 Bạn Voi con', message: 'Voi con đang đợi học cùng bé đó!' },
  { id: 'msg3', title: '🌟 Sao lấp lánh', message: 'Chỉ 5 phút học thôi, bé sẽ nhận được thật nhiều sao đó!' },
  { id: 'msg4', title: '💕 Mình học nhé', message: 'Bé nghỉ đủ rồi, mình học cùng nhau nha!' },
  { id: 'msg5', title: '🎈 Bắt đầu lại nào', message: 'Không sao nếu hôm qua quên học, hôm nay mình bắt đầu lại nhé!' },
  { id: 'msg6', title: '🍀 Siêu anh hùng', message: 'Mỗi ngày học một chút, bé sẽ trở thành siêu anh hùng đó!' },
  { id: 'msg7', title: '🥰 Vui quá đi', message: 'Bé xuất hiện là bài học vui hẳn lên luôn!' },
  { id: 'msg8', title: '🌞 Chào buổi sáng', message: 'Chào buổi sáng! Đến lúc khám phá điều mới rồi bé ơi!' },
  { id: 'msg9', title: '🎁 Quà bất ngờ', message: 'Hoàn thành bài học hôm nay để nhận quà bất ngờ nha!' },
  { id: 'msg10', title: '🚀 Sẵn sàng chưa?', message: 'Cuộc phiêu lưu học tập đang chờ bé đó! ✨' }
];

/**
 * Lấy thời gian bắt đầu ngày hôm nay theo múi giờ GMT+7
 */
const getStartOfTodayGMT7 = () => {
  const now = new Date();
  const gmt7Time = new Date(now.getTime() + (7 * 60 * 60 * 1000));
  gmt7Time.setUTCHours(0, 0, 0, 0);
  return new Date(gmt7Time.getTime() - (7 * 60 * 60 * 1000));
};

/**
 * Lấy 1 tin nhắn ngẫu nhiên không trùng với 3 tin nhắn gửi gần nhất của user
 */
const getRandomMessage = async (userId) => {
  // Tìm 3 thông báo gần nhất của user có liên quan đến nhắc học
  const recentNotifications = await Notification.find({
    userId,
    reminderType: { $ne: null }
  })
    .sort({ createdAt: -1 })
    .limit(3)
    .lean();

  const recentMessages = recentNotifications.map(n => n.message);

  // Lọc các tin nhắn không nằm trong danh sách đã gửi gần đây
  const availableMessages = REMINDER_MESSAGES.filter(
    item => !recentMessages.includes(item.message)
  );

  // Nếu không còn tin nhắn nào (hoặc lỗi), fallback về toàn bộ danh sách
  const choices = availableMessages.length > 0 ? availableMessages : REMINDER_MESSAGES;
  const randomIndex = Math.floor(Math.random() * choices.length);
  return choices[randomIndex];
};

/**
 * Kiểm tra xem user đã học bài hoặc chơi game hôm nay chưa
 */
const hasUserStudiedToday = async (userId) => {
  const startOfToday = getStartOfTodayGMT7();
  const progress = await Progress.findOne({ userId });
  if (!progress) return false;

  const studiedLesson = progress.completedLessons.some(
    lesson => lesson.completedAt >= startOfToday && lesson.isCompleted
  );

  const playedGame = progress.gameResults.some(
    game => game.playedAt >= startOfToday
  );

  return studiedLesson || playedGame;
};

/**
 * Gửi thông báo đến user (lưu DB & push qua Socket)
 */
const sendNotification = async (user, title, message, reminderType) => {
  const notification = await Notification.create({
    userId: user._id,
    title,
    message,
    type: NOTIFICATION_TYPES.STUDY_REMINDER,
    reminderType,
    isRead: false
  });

  console.log(`✉️ [StudyReminder] Sent '${reminderType}' reminder to user: ${user.name} (${user._id})`);

  // Gửi real-time socket
  emitToUser(user._id, SOCKET_EVENTS.NOTIFICATION, notification);
  return notification;
};

class StudyReminderService {
  /**
   * 1. Gửi thông báo nhắc học hằng ngày (chạy lúc 18:00 và 20:00)
   */
  async checkAndSendDailyReminders(reminderType) {
    console.log(`⏰ [StudyReminder] Checking daily reminders for type: ${reminderType}...`);
    const startOfToday = getStartOfTodayGMT7();
    const users = await User.find({ role: 'user' });

    for (const user of users) {
      try {
        // Kiểm tra xem bé đã học bài nào hôm nay chưa
        const studied = await hasUserStudiedToday(user._id);
        if (studied) {
          console.log(`   - User ${user.name} already studied today. Skipped.`);
          continue;
        }

        // Đếm số thông báo nhắc học đã gửi hôm nay
        const sentTodayCount = await Notification.countDocuments({
          userId: user._id,
          reminderType: { $ne: null },
          createdAt: { $gte: startOfToday }
        });

        if (sentTodayCount >= 2) {
          console.log(`   - User ${user.name} already received max 2 reminders today. Skipped.`);
          continue;
        }

        // Kiểm tra khoảng cách thời gian tối thiểu 2 giờ
        const lastReminder = await Notification.findOne({
          userId: user._id,
          reminderType: { $ne: null }
        }).sort({ createdAt: -1 });

        if (lastReminder) {
          const timeSinceLast = Date.now() - new Date(lastReminder.createdAt).getTime();
          const minGap = 2 * 60 * 60 * 1000; // 2 giờ
          if (timeSinceLast < minGap) {
            console.log(`   - User ${user.name} received a reminder less than 2 hours ago. Skipped.`);
            continue;
          }
        }

        // Chọn tin nhắn ngẫu nhiên không lặp
        const selectedMsg = await getRandomMessage(user._id);

        // Gửi thông báo
        await sendNotification(user, selectedMsg.title, selectedMsg.message, reminderType);
      } catch (err) {
        console.error(`❌ [StudyReminder] Error processing daily reminder for user ${user._id}:`, err);
      }
    }
  }

  /**
   * 2. Gửi thông báo nhắc nhở duy trì chuỗi ngày (chạy lúc 22:00)
   */
  async checkAndSendStreakReminders() {
    console.log('⏰ [StudyReminder] Checking streak warnings...');
    const users = await User.find({ role: 'user', streak: { $gt: 0 } });

    for (const user of users) {
      try {
        const studied = await hasUserStudiedToday(user._id);
        if (studied) continue;

        // Bé chưa học và có nguy cơ mất streak
        const title = '🔥 Giữ chuỗi học tập!';
        const message = `Bé ơi, học ngay để không bị mất chuỗi ${user.streak} ngày học cực đỉnh nha! 🐘`;
        
        await sendNotification(user, title, message, 'streak_warning');
      } catch (err) {
        console.error(`❌ [StudyReminder] Error checking streak for user ${user._id}:`, err);
      }
    }
  }

  /**
   * 3. Gửi thông báo nhắc nhở quay lại app khi nghỉ quá 2 ngày (chạy lúc 10:00)
   */
  async checkAndSendComebackReminders() {
    console.log('⏰ [StudyReminder] Checking comeback reminders (inactive users)...');
    const startOfToday = getStartOfTodayGMT7();
    const twoDaysAgo = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);

    // Tìm những user không hoạt động trong 2 ngày trở lên
    const users = await User.find({
      role: 'user',
      lastActiveDate: { $lt: twoDaysAgo }
    });

    for (const user of users) {
      try {
        // Kiểm tra xem đã gửi comeback reminder hôm nay chưa (tối đa 1 comeback reminder/ngày)
        const sentToday = await Notification.findOne({
          userId: user._id,
          reminderType: 'comeback',
          createdAt: { $gte: startOfToday }
        });

        if (sentToday) continue;

        // Chọn tin nhắn thân thiện
        const selectedMsg = await getRandomMessage(user._id);

        await sendNotification(
          user, 
          `👋 Nhớ bé quá!`, 
          `${selectedMsg.message} Đã 2 ngày rồi mình chưa gặp nhau đó!`, 
          'comeback'
        );
      } catch (err) {
        console.error(`❌ [StudyReminder] Error checking comeback for user ${user._id}:`, err);
      }
    }
  }
}

module.exports = new StudyReminderService();
