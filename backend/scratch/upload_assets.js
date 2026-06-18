require('dotenv').config();
const { uploadToCloudinary } = require('../src/config/cloudinary');
const path = require('path');
const fs = require('fs');

const images = [
  "C:\\Users\\ASUS\\Desktop\\KHOALUAN\\image\\Hình phần thư viện\\Truyện.png",
  "C:\\Users\\ASUS\\Desktop\\KHOALUAN\\image\\Hình phần thư viện\\video.png",
  "C:\\Users\\ASUS\\Desktop\\KHOALUAN\\image\\Hình phần thư viện\\Yêu thích.png",
  "C:\\Users\\ASUS\\Desktop\\KHOALUAN\\image\\Hình phần thư viện\\Bài hát.png",
  "C:\\Users\\ASUS\\Desktop\\KHOALUAN\\image\\Hình phần thư viện\\Kiến thức.png",
  "C:\\Users\\ASUS\\Desktop\\KHOALUAN\\image\\Hình phần thư viện\\Sách.png"
];

async function main() {
  console.log("Starting Cloudinary upload for library categories...");
  for (const imgPath of images) {
    if (!fs.existsSync(imgPath)) {
      console.error(`File does not exist: ${imgPath}`);
      continue;
    }
    try {
      console.log(`Uploading: ${path.basename(imgPath)}...`);
      const res = await uploadToCloudinary(imgPath, {
        folder: 'khmerkid/library',
        use_filename: true,
        unique_filename: false,
        overwrite: true
      });
      console.log(`Success! URL: ${res.url}`);
    } catch (err) {
      console.error(`Failed to upload ${imgPath}: ${err.message}`);
    }
  }
  console.log("All uploads complete!");
}

main();
