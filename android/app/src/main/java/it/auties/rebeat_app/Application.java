package it.auties.rebeat_app;

import com.danielgauci.native_audio.NativeAudioPlugin;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;

public class Application extends FlutterApplication implements PluginRegistry.PluginRegistrantCallback {
    @Override
    public void registerWith(PluginRegistry registry) {
        NativeAudioPlugin.registerWith(registry.registrarFor("com.danielgauci.native_audio.NativeAudioPlugin"));
    }

    @Override
    public void onCreate() {
        super.onCreate();
        NativeAudioPlugin.setPluginRegistrantCallback(this);
    }
}
