const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
require('dotenv').config();

console.log('JWT_EXPIRES_IN:', process.env.JWT_EXPIRES_IN);

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const User = require('./src/models/User');
  const admin = await User.findOne({email: 'admin@khmerkid.com'});
  
  if (admin) {
    console.log('Admin found, generating new tokens...');
    const { generateTokenPair } = require('./src/utils/token');
    const tokens = generateTokenPair(admin);
    admin.refreshToken = tokens.refreshToken;
    await admin.save();
    console.log('New access token (first 50):', tokens.accessToken.substring(0,50));
    console.log('Refresh token saved to DB');
    const decoded = jwt.decode(tokens.accessToken);
    console.log('Token expires:', new Date(decoded.exp * 1000).toISOString());
  } else {
    console.log('Admin not found!');
  }
  
  mongoose.disconnect();
}).catch(e => console.error(e));
