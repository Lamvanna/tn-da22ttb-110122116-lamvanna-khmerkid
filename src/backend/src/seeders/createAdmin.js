require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

const createAdmin = async () => {
  try {
    console.log('Connecting to database...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB.');

    const email = 'admin@khmerkid.com';
    const name = 'KhmerKid Admin';
    const password = 'admin123456';
    const role = 'admin';

    let user = await User.findOne({ email });
    if (user) {
      console.log(`User with email ${email} already exists. Updating role to admin and resetting password...`);
      user.role = role;
      user.password = password; // Pre-save hook will hash this automatically
      user.name = name;
      await user.save();
      console.log('Admin user updated successfully.');
    } else {
      console.log(`Creating new admin user: ${email}...`);
      user = await User.create({
        name,
        email,
        password,
        role,
        isEmailVerified: true
      });
      console.log('Admin user created successfully.');
    }

    console.log('-----------------------------');
    console.log('Login credentials:');
    console.log(`Email: ${email}`);
    console.log(`Password: ${password}`);
    console.log('-----------------------------');

    await mongoose.connection.close();
    console.log('Database connection closed.');
    process.exit(0);
  } catch (error) {
    console.error('Error creating admin user:', error);
    process.exit(1);
  }
};

createAdmin();
