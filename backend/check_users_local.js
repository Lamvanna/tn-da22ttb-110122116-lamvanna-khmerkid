require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log('Connected to MongoDB.');
    const users = await User.find({}, 'name email stars inventory purchasedItems');
    console.log('Users:');
    users.forEach(u => {
      console.log(`- Name: ${u.name}, Email: ${u.email}, Stars: ${u.stars}, PurchasedItems: ${JSON.stringify(u.purchasedItems)}, Inventory: ${JSON.stringify(u.inventory)}`);
    });
    await mongoose.connection.close();
    process.exit(0);
  })
  .catch(err => {
    console.error('Connection error:', err);
    process.exit(1);
  });
