import { Resend } from "resend";

export class EmailService {
    // Lazy initialization — avoids crash at startup if RESEND_API_KEY is not yet loaded
    private static _resend: Resend | null = null;
    private static get resend(): Resend {
        if (!this._resend) {
            this._resend = new Resend(process.env.RESEND_API_KEY);
        }
        return this._resend;
    }

    /**
     * Sends a password reset email to the user.
     * @param email The recipient's email address.
     * @param resetLink The link to reset their password.
     */
    static async sendResetPasswordEmail(email: string, resetLink: string): Promise<boolean> {
        console.log(`[FCM EmailService] Preparing to send reset email to: ${email}`);

        // Development fallback: if no API key, log mock data
        if (!process.env.RESEND_API_KEY) {
            console.warn("[FCM EmailService] RESEND_API_KEY not set in .env. Falling back to console log.");
            console.log(`[REAL EMAIL MOCK] To: ${email}\nSubject: FCM System - Reset Your Password\nLink: ${resetLink}`);
            return true; // Simulate success for development
        }

        try {
            const { data, error } = await this.resend.emails.send({
                from: process.env.RESEND_FROM_EMAIL || "FCM Support <onboarding@resend.dev>",
                to: email,
                subject: "FCM System - Reset Your Password",
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

            if (error) {
                console.error("[FCM EmailService] Resend API error:", error);
                return false;
            }

            console.log(`[FCM EmailService] Email sent successfully. ID: ${data?.id}`);
            return true;
        } catch (error) {
            console.error("[FCM EmailService] Failed to send email:", error);
            return false;
        }
    }
}
