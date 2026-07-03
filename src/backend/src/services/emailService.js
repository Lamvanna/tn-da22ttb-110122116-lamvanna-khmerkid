const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.MAIL_HOST,
      port: process.env.MAIL_PORT,
      secure: false, // true for 465, false for other ports
      auth: {
        user: process.env.MAIL_USERNAME,
        pass: process.env.MAIL_PASSWORD,
      },
    });
  }

  async sendPasswordResetOTP(email, otp) {
    const mailOptions = {
      from: `"${process.env.MAIL_FROM_NAME}" <${process.env.MAIL_USERNAME}>`,
      to: email,
      subject: 'Khôi phục mật khẩu - KhmerKid',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px;">
          <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #173F9B; margin: 0;">KhmerKid</h1>
          </div>
          <h2 style="color: #0A2540; margin-bottom: 16px;">Yêu cầu khôi phục mật khẩu</h2>
          <p style="color: #374151; line-height: 1.6; margin-bottom: 20px;">
            Xin chào, chúng tôi nhận được yêu cầu khôi phục mật khẩu cho tài khoản liên kết với địa chỉ email này. 
            Vui lòng sử dụng mã xác nhận gồm 4 chữ số dưới đây để đặt lại mật khẩu của bạn. Mã này có hiệu lực trong vòng <strong>10 phút</strong>.
          </p>
          <div style="text-align: center; margin: 30px 0;">
            <span style="display: inline-block; padding: 12px 24px; background-color: #F3F4F6; border-radius: 8px; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #173F9B;">
              ${otp}
            </span>
          </div>
          <p style="color: #6B7280; font-size: 14px; line-height: 1.5; margin-top: 30px; border-top: 1px solid #e5e7eb; padding-top: 20px;">
            Nếu bạn không yêu cầu khôi phục mật khẩu, vui lòng bỏ qua email này. Tài khoản của bạn vẫn an toàn.
          </p>
        </div>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
    } catch (error) {
      console.error('Error sending email:', error);
      throw new Error('Không thể gửi email lúc này. Vui lòng thử lại sau.');
    }
  }
}

module.exports = new EmailService();
