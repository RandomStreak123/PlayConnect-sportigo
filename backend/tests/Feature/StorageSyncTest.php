<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\StorageSync;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StorageSyncTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_set_storage_sync_value()
    {
        $user = User::factory()->create();
 
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/storage/sync-set', [
            'key' => 'app_settings_theme',
            'value' => 'dark_mode'
        ]);
 
        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Storage synchronized successfully',
                     'key' => 'app_settings_theme'
                 ]);
 
        $this->assertDatabaseHas('storage_syncs', [
            'user_id' => $user->id,
            'key' => 'app_settings_theme',
            'value' => 'dark_mode'
        ]);
    }
 
    public function test_can_get_specific_keys()
    {
        $user = User::factory()->create();
        StorageSync::create(['user_id' => $user->id, 'key' => 'key1', 'value' => 'val1']);
        StorageSync::create(['user_id' => $user->id, 'key' => 'key2', 'value' => 'val2']);
        StorageSync::create(['user_id' => $user->id, 'key' => 'key3', 'value' => 'val3']);
 
        // Test getting multiple specific keys
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/storage/sync-get', [
            'keys' => ['key1', 'key3']
        ]);
 
        $response->assertStatus(200)
                 ->assertExactJson([
                     'key1' => 'val1',
                     'key3' => 'val3'
                 ]);
 
        // Test getting a single key
        $responseSingle = $this->actingAs($user, 'sanctum')->postJson('/api/storage/sync-get', [
            'key' => 'key2'
        ]);
 
        $responseSingle->assertStatus(200)
                       ->assertExactJson([
                           'key2' => 'val2'
                       ]);
     }
 
     public function test_can_get_all_keys_when_none_specified()
     {
         $user = User::factory()->create();
         StorageSync::create(['user_id' => $user->id, 'key' => 'key1', 'value' => 'val1']);
         StorageSync::create(['user_id' => $user->id, 'key' => 'key2', 'value' => 'val2']);
 
         $response = $this->actingAs($user, 'sanctum')->postJson('/api/storage/sync-get');
 
         $response->assertStatus(200)
                  ->assertExactJson([
                      'key1' => 'val1',
                      'key2' => 'val2'
                  ]);
     }

     public function test_user_cannot_access_other_users_keys_idor()
     {
         $userA = User::factory()->create();
         $userB = User::factory()->create();

         StorageSync::create(['user_id' => $userA->id, 'key' => 'secret_key', 'value' => 'userA_secret']);

         // User B requests user A's key
         $response = $this->actingAs($userB, 'sanctum')->postJson('/api/storage/sync-get', [
             'key' => 'secret_key'
         ]);

         $response->assertStatus(200)
                  ->assertExactJson([]);
     }
}
