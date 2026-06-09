<?php

namespace Tests\Feature;

use App\Services\TwilioService;
use Tests\TestCase;

class OtpTest extends TestCase
{
    public function test_can_send_otp_successfully()
    {
        $twilioMock = $this->mock(TwilioService::class);
        $twilioMock->shouldReceive('sendOtp')
                   ->once()
                   ->with('+1234567890')
                   ->andReturn(true);

        $response = $this->postJson('/otp/send', [
            'phone_number' => '+1234567890'
        ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => 'OTP sent successfully!'
                 ]);
    }

    public function test_send_otp_validation_fails_for_invalid_phone()
    {
        $response = $this->postJson('/otp/send', [
            'phone_number' => 'invalid-phone'
        ]);

        $response->assertStatus(422)
                 ->assertJson([
                     'success' => false,
                     'message' => 'Invalid phone number format. Use E.164 format (e.g. +1234567890).'
                 ]);
    }

    public function test_send_otp_returns_500_if_service_fails()
    {
        $twilioMock = $this->mock(TwilioService::class);
        $twilioMock->shouldReceive('sendOtp')
                   ->once()
                   ->with('+1234567890')
                   ->andReturn(false);

        $response = $this->postJson('/otp/send', [
            'phone_number' => '+1234567890'
        ]);

        $response->assertStatus(500)
                 ->assertJson([
                     'success' => false,
                     'message' => 'Failed to send OTP. Please try again.'
                 ]);
    }

    public function test_can_verify_otp_successfully()
    {
        $twilioMock = $this->mock(TwilioService::class);
        $twilioMock->shouldReceive('verifyOtp')
                   ->once()
                   ->with('+1234567890', '123456')
                   ->andReturn(true);

        $response = $this->postJson('/otp/verify', [
            'phone_number' => '+1234567890',
            'code' => '123456'
        ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => 'OTP verified successfully!'
                 ]);
    }

    public function test_verify_otp_validation_fails_for_missing_params()
    {
        $response = $this->postJson('/otp/verify', [
            'phone_number' => '+1234567890'
            // code missing
        ]);

        $response->assertStatus(422)
                 ->assertJson([
                     'success' => false,
                     'message' => 'Invalid data provided.'
                 ]);
    }

    public function test_verify_otp_returns_401_for_invalid_code()
    {
        $twilioMock = $this->mock(TwilioService::class);
        $twilioMock->shouldReceive('verifyOtp')
                   ->once()
                   ->with('+1234567890', '000000')
                   ->andReturn(false);

        $response = $this->postJson('/otp/verify', [
            'phone_number' => '+1234567890',
            'code' => '000000'
        ]);

        $response->assertStatus(401)
                 ->assertJson([
                     'success' => false,
                     'message' => 'Invalid or expired OTP.'
                 ]);
    }
}
