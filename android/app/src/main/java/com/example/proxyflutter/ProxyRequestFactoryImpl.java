package com.example.proxyflutter;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import in.yagnyam.proxy.services.CertificateRequestService;

public class ProxyRequestFactoryImpl implements MethodChannel.MethodCallHandler {
    public static final String CHANNEL = "proxy.yagnyam.in/ProxyRequestFactory";

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.method.equals("createCertificateRequest")) {

        } else {
            result.notImplemented();
        }
    }

    private ProxyRequest createCertificateRequest(String id, String signatureAlgorithm, String revocationPassPhrase) {

    }
}
