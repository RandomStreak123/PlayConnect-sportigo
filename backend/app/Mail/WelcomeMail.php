<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class WelcomeMail extends Mailable
{
    use Queueable, SerializesModels;

    public $userName;
    public $exploreUrl;

    /**
     * Create a new message instance.
     */
    public function __construct($userName, $exploreUrl)
    {
        $this->userName = $userName;
        $this->exploreUrl = $exploreUrl;
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
  <title>Welcome to PlayConnect!</title>
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
              <h2 style="margin-top: 0; margin-bottom: 20px; font-size: 22px; font-weight: 700; color: #1a202c;">Welcome to the Community!</h2>
              <p style="margin-bottom: 16px; font-size: 15px; color: #2d3748;">
                Hi {$this->userName},
              </p>
              <p style="margin-bottom: 20px; font-size: 15px; color: #4a5568;">
                Thank you for joining PlayConnect! We are thrilled to have you here. PlayConnect is your matchmaking platform designed to make finding sports matches, connecting with other athletes, and booking venues as easy as possible.
              </p>
              <p style="margin-bottom: 24px; font-size: 15px; color: #4a5568;">
                Ready to get started? Click the button below to explore active matches and find your first game!
              </p>
              
              <!-- CTA Button -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-bottom: 30px;">
                <tr>
                  <td align="center">
                    <a href="{$this->exploreUrl}" target="_blank" style="display: inline-block; padding: 14px 30px; background: linear-gradient(135deg, #3f51b5, #673ab7); color: #ffffff; text-decoration: none; font-size: 15px; font-weight: 600; border-radius: 8px; box-shadow: 0 4px 10px rgba(99, 102, 241, 0.3); transition: all 0.2s ease;">
                      Explore Matches
                    </a>
                  </td>
                </tr>
              </table>
              
              <div style="border-top: 1px solid #edf2f7; padding-top: 24px; margin-top: 24px;">
                <p style="font-size: 12px; color: #718096; margin-bottom: 0;">
                  If you have any questions or feedback, feel free to reply to this email. We're here to help you stay active and connected!
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

        return $this->subject('Welcome to PlayConnect!')
                    ->html($htmlContent);
    }
}
