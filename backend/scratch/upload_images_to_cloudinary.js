const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { uploadToCloudinary } = require('../src/config/cloudinary');
const fs = require('fs');

const imageDir = path.join(__dirname, '../../image/Hình phần thư viện');

const files = [
  "Sách Bé Học Từ Vựng.png",
  "Sách Bảng Chữ Cái Khmer Vui Nhộn.png",
  "Sách Hành Trình 33 Chữ Cái Khmer.png",
  "Sách Học Từ Vựng Khmer Qua Hình Ảnh.png",
  "Sách học chữ khmer.png",
  "Truyện Hành Trình Tìm Cầu Vồng Của Bé Sóc.png",
  "Truyện Thỏ Trắng Và Ngôi Sao May Mắn.png",
  "Truyện thiếu nhi.png",
  "Truyện ដំរីតូចក្លាហាន.png",
  "Truyện ទន្សាយនិងអណ្តើក.png",
  "Truyện ស្វាតូចឆ្លាតវៃ.png",
  "sách Bé Tập Viết Chữ Khmer.png"
];

async function run() {
  console.log("Starting Cloudinary Uploads...");
  const results = {};
  for (const file of files) {
    const filePath = path.join(imageDir, file);
    if (!fs.existsSync(filePath)) {
      console.error(`File does not exist: ${filePath}`);
      continue;
    }
    console.log(`Uploading ${file}...`);
    try {
      const uploadRes = await uploadToCloudinary(filePath, { folder: 'khmerkid/library' });
      console.log(`Uploaded ${file} successfully: ${uploadRes.url}`);
      results[file] = uploadRes.url;
    } catch (err) {
      console.error(`Failed to upload ${file}:`, err);
    }
  }
  console.log("\n--- UPLOAD RESULTS ---");
  console.log(JSON.stringify(results, null, 2));
}

run();
