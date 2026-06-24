<?php

Route::get('/', function () {
    return response()->json(['message' => 'PlayConnect API is running successfully.']);
});

// Bridge page: email clients only make http/https links tappable.
// This page receives the token and email from the reset email, then
// immediately redirects the browser to the sportigo:// deep-link so
// Android hands it off to the Flutter app.
Route::get('/reset-password', function (\Illuminate\Http\Request $request) {
    $token = $request->query('token', '');
    $email = $request->query('email', '');
    $deepLink = 'sportigo://reset-password?token=' . urlencode($token) . '&email=' . urlencode($email);

    $html = <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Opening PlayConnect…</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #3f51b5, #673ab7);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: #fff;
      border-radius: 16px;
      padding: 40px 32px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      box-shadow: 0 8px 32px rgba(0,0,0,0.15);
    }
    .logo { font-size: 40px; margin-bottom: 8px; }
    h1 { font-size: 22px; font-weight: 700; color: #1a202c; margin-bottom: 8px; }
    p  { font-size: 14px; color: #718096; margin-bottom: 28px; line-height: 1.6; }
    .btn {
      display: inline-block;
      padding: 14px 32px;
      background: linear-gradient(135deg, #3f51b5, #673ab7);
      color: #fff;
      font-size: 15px;
      font-weight: 600;
      border-radius: 8px;
      text-decoration: none;
    }
    .spinner {
      width: 36px; height: 36px;
      border: 4px solid #e2e8f0;
      border-top-color: #3f51b5;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      margin: 0 auto 20px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">⚡</div>
    <h1>PlayConnect</h1>
    <div class="spinner" id="spinner"></div>
    <p id="msg">Opening the app to reset your password…</p>
    <a href="{$deepLink}" class="btn" id="openBtn" style="display:none;">Open PlayConnect</a>
  </div>
  <script>
    // Attempt automatic redirect to the app deep link
    window.location.href = "{$deepLink}";

    // After 2 seconds, if still on this page, show the manual button
    setTimeout(function () {
      document.getElementById('spinner').style.display = 'none';
      document.getElementById('msg').textContent =
        "Tap the button below if the app didn't open automatically.";
      document.getElementById('openBtn').style.display = 'inline-block';
    }, 2000);
  </script>
</body>
</html>
HTML;

    return response($html, 200)->header('Content-Type', 'text/html');
});

Route::get('/{name}', function ($name=null) {
    $data=compact('name');
    return view('home')->with($data);
});
