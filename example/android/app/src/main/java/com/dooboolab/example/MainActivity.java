package com.dooboolab.example;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
      GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

}
