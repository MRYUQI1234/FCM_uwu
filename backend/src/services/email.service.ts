import nodemailer from "nodemailer";

export class EmailService {
    private static transporter = nodemailer.createTransport({
        // Default to a common setup, but allow overrides via env
        host: process.env.EMAIL_HOST || "smtp.gmail.com",
        port: parseInt(process.env.EMAIL_PORT || "587"),
        secure: process.env.EMAIL_SECURE === "true", // true for 465, false for other ports
        auth: {
            user: process.env.EMAIL_USER, // Your email
            pass: process.env.EMAIL_PASS, // Your password or app-specific password
        },
    });

    /**
     * Sends a password reset email to the user.
     * @param email The recipient's email address.
     * @param resetLink The link to reset their password.
     */
    static async sendResetPasswordEmail(email: string, resetLink: string): Promise<boolean> {
        console.log(`[FCM EmailService] Preparing to send reset email to: ${email}`);

        // Check if credentials are set
        if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
            console.warn("[FCM EmailService] EMAIL_USER or EMAIL_PASS not set in .env. Falling back to console log.");
            console.log(`[REAL EMAIL MOCK] To: ${email}\nSubject: Reset Your Password\nLink: ${resetLink}`);
            return true; // Simulate success for development
        }

        try {
            const info = await this.transporter.sendMail({
                from: `"FCM Support" <${process.env.EMAIL_USER}>`,
                to: email,
                subject: "FCM System - Reset Your Password",
                text: `You requested a password reset. Please use the following link to reset your password: ${resetLink}\n\nIf you did not request this, please ignore this email.`,
                html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 12px;">
            <h2 style="color: #C5A059;">FCM System</h2>
            <p>You requested a password reset. Please click the button below to reset your password:</p>
            <div style="text-align: center; margin: 30px 0;">
              <a href="${resetLink}" style="background-color: #C5A059; color: black; padding: 14px 24px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">
                RESET PASSWORD
              </a>
            </div>
            <p style="color: #666; font-size: 13px;">If you did not request this, please ignore this email. This link will expire shortly.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
            <p style="color: #999; font-size: 11px; text-align: center;">Enterprise Quality Management Platform</p>
          </div>
        `,
            });

            console.log(`[FCM EmailService] Email sent successfully: ${info.messageId}`);
            return true;
        } catch (error) {
            console.error("[FCM EmailService] Failed to send email:", error);
            return false;
        }
    }
}
