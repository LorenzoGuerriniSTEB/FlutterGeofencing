package io.flutter.plugins.geofencing.example

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback;
import io.flutter.plugins.geofencing.GeofencingService;

class Application : FlutterApplication(), PluginRegistrantCallback {
  override fun onCreate() {
    super.onCreate();
    GeofencingService.setPluginRegistrant(this);
  }

  override fun registerWith(registry: PluginRegistry) {
  }
}