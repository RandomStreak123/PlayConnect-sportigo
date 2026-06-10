<?php

Route::get('/', function () {
    return response()->json(['message' => 'PlayConnect API is running successfully.']);
});

Route::get('/{name}', function ($name=null) {
    $data=compact('name');
    return view('home')->with($data);
});
