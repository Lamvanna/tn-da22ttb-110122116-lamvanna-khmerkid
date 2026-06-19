/**
 * ========================================================
 * Cloudinary Image Uploader for Badge Assets
 * ========================================================
 */

const fs = require('fs');
const path = require('path');
require('dotenv').config();
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary from environment variables
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

const IMAGES_DIR = 'C:\\Users\\ASUS\\Desktop\\KHOALUAN\\image\\Ảnh nhiệm vụ';

const uploadAll = async () => {
  try {
    if (!fs.existsSync(IMAGES_DIR)) {
      console.error(`❌ Source directory does not exist: ${IMAGES_DIR}`);
      process.exit(1);
    }

    console.log(`⏳ Scanning image directory: ${IMAGES_DIR}`);
    const files = fs.readdirSync(IMAGES_DIR);
    const results = {};

    console.log(`🚀 Found ${files.length} items. Uploading to Cloudinary folder "khmerkid/badges"...`);
    
    for (const file of files) {
      const ext = path.extname(file).toLowerCase();
      if (ext === '.png' || ext === '.jpg' || ext === '.jpeg') {
        const filePath = path.join(IMAGES_DIR, file);
        // Use the filename (without extension) as the public ID
        const publicId = path.basename(file, ext);
        
        console.log(`📤 Uploading: "${file}"...`);
        try {
          const uploadResult = await cloudinary.uploader.upload(filePath, {
            folder: 'khmerkid/badges',
            public_id: publicId,
            overwrite: true,
            resource_type: 'image'
          });
          
          console.log(`   ✅ Success! URL: ${uploadResult.secure_url}`);
          results[file] = uploadResult.secure_url;
        } catch (uploadErr) {
          console.error(`   ❌ Failed uploading "${file}":`, uploadErr.message);
        }
      }
    }

    const outputPath = path.join(__dirname, 'uploaded_badges.json');
    fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));
    
    console.log(`\n🎉 Complete! Successfully uploaded ${Object.keys(results).length} images.`);
    console.log(`💾 Secure URLs mapped and saved to: ${outputPath}`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Fatal error during upload script execution:', error);
    process.exit(1);
  }
};

uploadAll();
