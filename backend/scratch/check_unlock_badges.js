/**
 * ========================================
 * Check & Unlock All Badges
 * ========================================
 *
 * Kiểm tra và mở khóa badge cho tất cả user dựa trên progress hiện tại.
 * Chạy sau khi backfill counters để đồng bộ badge.
 *
 * Usage: node backend/scratch/check_unlock_badges.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');

const User = require('../src/models/User');
const Badge = require('../src/models/Badge');
const badgeService = require('../src/services/badgeService');

async function checkAll() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ Connected to MongoDB\n');

  const users = await User.find({}).select('_id name');
  console.log(`📋 Found ${users.length} users\n`);

  for (const u of users) {
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`👤 ${u.name || u._id}`);

    const unlocked = await badgeService.checkAndUnlockBadges(u._id);

    if (unlocked.length > 0) {
      console.log(`   🔓 Mở khóa ${unlocked.length} badge mới:`);
      for (const b of unlocked) {
        console.log(`      ✅ ${b.name}`);
      }
    } else {
      // Show current badge count
      const user = await User.findById(u._id).select('badges');
      console.log(`   📦 Đã có ${user.badges?.length || 0} badge, không mở thêm`);
    }
  }

  await mongoose.disconnect();
  console.log('\n🎉 Done!');
}

checkAll().catch((err) => {
  console.error('❌ Error:', err);
  process.exit(1);
});
