<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Contracts\Queue\ShouldQueue;

class ResetPasswordMail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public $resetUrl;

    /**
     * Create a new message instance.
     */
    public function __construct($resetUrl)
    {
        $this->resetUrl = $resetUrl;
    }

    /**
     * Build the message.
     */
    public function build()
    {
        $currentYear = date('Y');
        
        $htmlContent = <<<HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your Password</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f6f9fc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased;">
  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="table-layout: fixed;">
    <tr>
      <td align="center" style="padding: 40px 10px;">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 520px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05); border: 1px solid #eef2f6;">
          
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, #3f51b5, #673ab7); padding: 40px 30px; text-align: center;">
              <span style="font-size: 32px; margin-right: 8px; display: inline-block; vertical-align: middle;">⚡</span>
              <div style="font-size: 24px; font-weight: 800; color: #ffffff; letter-spacing: 0.5px; display: inline-block; vertical-align: middle; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">PlayConnect</div>
            </td>
          </tr>
          
          <!-- Body Content -->
          <tr>
            <td style="padding: 40px 30px; color: #2d3748; line-height: 1.6;">
              <h2 style="margin-top: 0; margin-bottom: 20px; font-size: 22px; font-weight: 700; color: #1a202c;">Reset Your Password</h2>
              <p style="margin-bottom: 24px; font-size: 15px; color: #4a5568;">
                We received a request to reset the password for your PlayConnect account. You can reset your password by clicking the button below:
              </p>
              
              <!-- CTA Button -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-bottom: 30px;">
                <tr>
                  <td align="center">
                    <a href="{$this->resetUrl}" target="_blank" style="display: inline-block; padding: 14px 30px; background: linear-gradient(135deg, #3f51b5, #673ab7); color: #ffffff; text-decoration: none; font-size: 15px; font-weight: 600; border-radius: 8px; box-shadow: 0 4px 10px rgba(99, 102, 241, 0.3); transition: all 0.2s ease;">
                      Reset Password
                    </a>
                  </td>
                </tr>
              </table>
              
              <div style="border-top: 1px solid #edf2f7; padding-top: 24px; margin-top: 24px;">
                <p style="font-size: 12px; color: #718096; margin-bottom: 12px;">
                  This link will expire in 60 minutes. If you did not request a password reset, no further action is required.
                </p>
                <p style="font-size: 11px; color: #a0aec0; word-break: break-all; margin: 0;">
                  If the button above doesn't work, copy and paste this URL into your browser:<br>
                  <a href="{$this->resetUrl}" style="color: #6366f1; text-decoration: none;">{$this->resetUrl}</a>
                </p>
              </div>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #f7fafc; padding: 24px 30px; text-align: center; border-top: 1px solid #edf2f7;">
              <p style="font-size: 12px; color: #a0aec0; margin: 0;">
                &copy; {$currentYear} PlayConnect. All rights reserved.
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
HTML;

        return $this->subject('Reset Password Link')
                    ->html($htmlContent);
    }
}
