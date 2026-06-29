require('dotenv').config();
const { uploadToCloudinary } = require('../src/config/cloudinary');
const path = require('path');
const fs = require('fs');

const libImgDir = path.join(__dirname, '..', '..', 'client', 'image', 'Hình phần thư viện');
const images = [
  path.join(libImgDir, "Truyện.png"),
  path.join(libImgDir, "video.png"),
  path.join(libImgDir, "Yêu thích.png"),
  path.join(libImgDir, "Bài hát.png"),
  path.join(libImgDir, "Kiến thức.png"),
  path.join(libImgDir, "Sách.png")
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
