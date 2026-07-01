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
        return $this->subject('Welcome to PlayConnect!')
                    ->view('emails.welcome');
    }
}
