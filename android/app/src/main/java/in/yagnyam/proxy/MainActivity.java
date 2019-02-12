package in.yagnyam.proxy;

import android.os.Bundle;

import in.yagnyam.proxy.channels.ProxyKeyStoreImpl;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);
        registerPlugins();
    }

    private void registerPlugins() {
        new MethodChannel(getFlutterView(), ProxyKeyStoreImpl.CHANNEL)
                .setMethodCallHandler(new ProxyKeyStoreImpl());
    }
}
