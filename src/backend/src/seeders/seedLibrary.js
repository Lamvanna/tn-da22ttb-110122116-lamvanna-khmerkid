const mongoose = require('mongoose');
const LibraryItem = require('../models/LibraryItem');

const items = [
  {
    title: 'Học chữ khmer',
    type: 'Sách',
    description: 'Học bảng chữ cái và cách phát âm cơ bản',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781825/khmerkid/library/eddtrctzrddpea2mtfx1.png',
    rating: 4.8,
    views: 1200
  },
  {
    title: 'TRuyện thiếu nhi',
    type: 'Sách',
    description: 'Các câu chuyện ý nghĩa cho bé học tập',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png',
    rating: 4.9,
    views: 850
  },
  {
    title: 'Bé Tập Viết Chữ Khmer',
    type: 'Sách',
    description: 'Tập tô nét chữ Khmer chuẩn tiểu học',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781835/khmerkid/library/fof6w2jwtpitzj32vqus.png',
    rating: 4.7,
    views: 950
  },
  {
    title: 'Học Từ Vựng Khmer Qua Hình Ảnh',
    type: 'Sách',
    description: 'Học từ vựng trực quan sinh động qua tranh vẽ',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781824/khmerkid/library/mtcq0mpsgjw65ey8fsbg.png',
    rating: 4.8,
    views: 1100
  },
  {
    title: 'ដំរីតូចក្លាហាន',
    type: 'Sách',
    description: 'Câu chuyện về lòng dũng cảm của chú voi nhỏ',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png',
    rating: 4.9,
    views: 720
  },
  {
    title: 'Thỏ Trắng Và Ngôi Sao May Mắn',
    type: 'Sách',
    description: 'Câu chuyện thỏ trắng tìm ngôi sao may mắn',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png',
    rating: 4.8,
    views: 640
  },
  {
    title: 'Hành Trình Tìm Cầu Vồng Của Bé Sóc',
    type: 'Sách',
    description: 'Cuộc phiêu lưu kỳ thú của chú sóc nhỏ',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781827/khmerkid/library/fytoyjalak42cfisfg3d.png',
    rating: 4.7,
    views: 580
  },
  {
    title: 'ស្វាតូចឆ្លាតវៃ',
    type: 'Sách',
    description: 'Câu chuyện thông minh dí dỏm về chú khỉ con',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781833/khmerkid/library/c42qxbcimdhz4am2ywes.png',
    rating: 4.9,
    views: 890
  },
  {
    title: 'ទន្សាយនិងអណ្តើក',
    type: 'Sách',
    description: 'Truyện ngụ ngôn Rùa và Thỏ bằng tiếng Khmer',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
    rating: 4.8,
    views: 1200
  },
  {
    title: 'Bảng Chữ Cái Khmer Vui Nhộn',
    type: 'Sách',
    description: 'Học chữ cái qua các bài hát vui nhộn',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781822/khmerkid/library/zx2pibowpd287plq34sn.png',
    rating: 4.8,
    views: 910
  },
  {
    title: 'Hành Trình 33 Chữ Cái Khmer',
    type: 'Sách',
    description: 'Khám phá thế giới 33 chữ cái phụ âm',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781823/khmerkid/library/sh5oitnbnr3hhregxnor.png',
    rating: 4.9,
    views: 1500
  },
  {
    title: 'Bé Học Từ Vựng',
    type: 'Sách',
    description: 'Phát triển vốn từ vựng Khmer cơ bản hằng ngày',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781820/khmerkid/library/dnakvq21vgkv0oabe4pw.png',
    rating: 4.7,
    views: 830
  },
  {
    title: 'ក្មេងៗ ច្រៀងលេង (Trẻ em ca hát vui đùa)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer vui nhộn dành cho bé',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png',
    rating: 4.9,
    views: 2500
  },
  {
    title: 'ដំរីតូច (Chú voi con)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer về chú voi con ngộ nghĩnh',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png',
    rating: 4.8,
    views: 1980
  },
  {
    title: 'គេងលក់ យប់នេះ (Đi ngủ nào bé ơi)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer ru bé giấc ngủ êm đềm',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png',
    rating: 4.7,
    views: 2120
  },
  {
    title: ' ខ្ញុំស្រឡាញ់គ្រួសារ (Em yêu gia đình)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer ý nghĩa ca ngợi gia đình thân thương',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781820/khmerkid/library/dnakvq21vgkv0oabe4pw.png',
    rating: 4.9,
    views: 2480
  },
  {
    title: 'Học nguyên âm tiếng Khmer',
    type: 'Video',
    description: 'Học nguyên âm qua video hoạt hình',
    image: 'image/Nguyên âm.png',
    rating: 4.7,
    views: 2100,
    duration: '08:45'
  },
  {
    title: 'Đếm số 1-10',
    type: 'Video',
    description: 'Nhận diện chữ số Khmer qua bài hát',
    image: 'image/Tập đọc.png',
    rating: 4.9,
    views: 3200,
    duration: '05:30'
  },
  {
    title: 'Giải cứu thú rừng',
    type: 'Video',
    description: 'Học từ vựng Khmer qua cuộc chiến bảo vệ rừng xanh',
    image: 'image/Giải cứu thú rừng.png',
    rating: 4.8,
    views: 1520,
    duration: '10:15'
  },
  {
    title: 'Đảo quốc Ngữ pháp',
    type: 'Video',
    description: 'Khám phá thế giới ngữ pháp Khmer qua chuyến đi phiêu lưu',
    image: 'image/Đảo quốc Ngữ pháp.png',
    rating: 4.9,
    views: 2350,
    duration: '12:40'
  },
  {
    title: 'Cờ tỷ phú Khmer kỳ thú',
    type: 'Video',
    description: 'Vừa chơi cờ vừa học giao tiếp tiếng Khmer thực tế',
    image: 'image/Cờ tỷ phú Khmer kỳ thú.png',
    rating: 4.7,
    views: 980,
    duration: '15:20'
  },
  {
    title: 'Nhà khảo cổ nhí',
    type: 'Video',
    description: 'Khám phá lịch sử cổ xưa qua các chữ cái Khmer',
    image: 'image/Nhà khảo cổ nhí.png',
    rating: 4.8,
    views: 1120,
    duration: '09:50'
  },
  {
    title: 'Bắt chữ Khmer',
    type: 'Video',
    description: 'Đố vui đoán chữ Khmer cực nhanh cho các bé học từ',
    image: 'image/Bắt chữ Khmer.png',
    rating: 4.9,
    views: 3080,
    duration: '11:05'
  }
];

const seedLibrary = async () => {
  try {
    console.log('🏁 Seeding Library items...');
    await LibraryItem.deleteMany({});
    console.log('🗑️ Cleared existing library items.');
    const result = await LibraryItem.insertMany(items);
    console.log(`✅ Successfully seeded ${result.length} library items.`);
  } catch (error) {
    console.error('❌ Seeding library items failed:', error.message);
  }
};

module.exports = seedLibrary;

if (require.main === module) {
  require('dotenv').config({ path: '../../.env' });
  const runDirectly = async () => {
    const mongoUri = process.env.MONGO_URI || 'mongodb+srv://admin:PCO6NePc2Gmcifzt@lamv.tzc1slv.mongodb.net/khmerkid';
    console.log('Connecting directly to MongoDB:', mongoUri);
    await mongoose.connect(mongoUri);
    await seedLibrary();
    await mongoose.connection.close();
    console.log('Direct execution complete.');
  };
  runDirectly();
}
