package in.yagnyam.proxy.channels;

import android.util.Log;

import org.bouncycastle.crypto.CryptoException;

import java.security.KeyPair;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import in.yagnyam.proxy.ProxyId;
import in.yagnyam.proxy.UserKeyStore;
import in.yagnyam.proxy.services.BcCertificateRequestService;
import in.yagnyam.proxy.services.BcCryptographyService;
import in.yagnyam.proxy.services.CertificateRequestService;
import in.yagnyam.proxy.services.CryptographyService;
import in.yagnyam.proxy.services.MessageSerializerService;
import in.yagnyam.proxy.services.PemService;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.NonNull;
import lombok.ToString;


public class ProxyKeyStoreImpl implements MethodChannel.MethodCallHandler {

    @Builder
    @NoArgsConstructor(access = AccessLevel.PRIVATE)
    @AllArgsConstructor(access = AccessLevel.PRIVATE)
    @Getter
    @ToString
    private static class ProxyKey {

        @NonNull
        private ProxyId id;

        @NonNull
        private String localAlias;

        private String name;
    }

    @Builder
    @NoArgsConstructor(access = AccessLevel.PRIVATE)
    @AllArgsConstructor(access = AccessLevel.PRIVATE)
    @Getter
    @ToString
    private static class ProxyRequest {

        @NonNull
        private String id;

        @NonNull
        private String revocationPassPhraseSha256;

        @NonNull
        private String requestEncoded;
    }

    private static final String TAG = "ProxyKeyStoreImpl";
    public static final String CHANNEL = "proxy.yagnyam.in/ProxyKeyStore";

    private final Map<String, KeyPair> inTransitKeys = new LinkedHashMap<String, KeyPair>(13, .75F, true) {
        public boolean removeEldestEntry(Map.Entry<String, KeyPair> eldest) {
            return size() > 7;
        }
    };
    private final MessageSerializerService messageSerializerService = MessageSerializerService.builder().build();
    private final PemService pemService = PemService.builder().build();
    private final CertificateRequestService certificateRequestService = BcCertificateRequestService.builder().pemService(pemService).build();
    private final CryptographyService cryptographyService = BcCryptographyService.builder().build();


    private String arg(MethodCall methodCall, String argumentName) {
        String value = methodCall.argument(argumentName);
        if (value == null) {
            Log.e(TAG, "Missing " + argumentName);
            throw new IllegalArgumentException("Missing " + argumentName);
        }
        return value;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        Log.d(TAG, "onMethodCall(" + methodCall + ")");
        try {
            if (methodCall.method.equals("createProxyKey")) {
                ProxyKey proxyKey = createProxyKey(methodCall);
                result.success(messageSerializerService.serializeMessage(proxyKey));
            } else if (methodCall.method.equals("createProxyRequest")) {
                ProxyRequest proxyRequest = createProxyRequest(methodCall);
                result.success(messageSerializerService.serializeMessage(proxyRequest));
            } else {
                result.notImplemented();
            }
        } catch (IllegalArgumentException e) {
            Log.e(TAG, "Missing Arguments", e);
            result.error("MISSING_ARGUMENTS", e.getMessage(), null);
        } catch (Exception e) {
            Log.e(TAG, "Unknown Error", e);
            result.error("UNKNOWN_ERROR", e.getMessage(), null);
        }
    }

    private ProxyKey createProxyKey(MethodCall methodCall) {
        Log.d(TAG, "createProxyKey(" + methodCall + ")");
        String id = arg(methodCall, "id");
        String keyGenerationAlgorithm = arg(methodCall, "keyGenerationAlgorithm");
        int keySize = Integer.valueOf(arg(methodCall, "keySize"));

        try {
            String localAlias = findLocalAlias(id);
            KeyPair keyPair = cryptographyService.generateKeyPair(keyGenerationAlgorithm, keySize);
            inTransitKeys.put(localAlias, keyPair);
            return ProxyKey.builder()
                    .localAlias(localAlias)
                    .id(ProxyId.of(id))
                    .build();
        } catch (Exception e) {
            Log.e(TAG, "Failed to create proxy key", e);
            throw new RuntimeException("Failed to create proxy key");
        }
    }

    private String findLocalAlias(String id) throws CryptoException {
        String localAlias = id;
        for (int i = 0; i < 16; i++) {
            if (!UserKeyStore.containsAlias(id)) {
                return localAlias;
            }
            localAlias = UUID.randomUUID().toString();
        }
        throw new CryptoException("Unable to find local alias for proxy id " + id);
    }


    private ProxyRequest createProxyRequest(MethodCall methodCall) {
        Log.d(TAG, "createProxyRequest(" + methodCall + ")");
        try {
            ProxyKey proxyKey = messageSerializerService.deserializeMessage(arg(methodCall, "proxyKey"), ProxyKey.class);
            String signatureAlgorithm = arg(methodCall, "signatureAlgorithm");
            String revocationPassPhrase = arg(methodCall, "revocationPassPhrase");

            KeyPair keyPair = inTransitKeys.get(proxyKey.localAlias);
            StringBuilder revocationPassPhraseSha256Input = new StringBuilder(proxyKey.id + "#" + revocationPassPhrase);
            while (revocationPassPhraseSha256Input.length() < 64) {
                revocationPassPhraseSha256Input.append("0");
            }
            String revocationPassPhraseSha256 = cryptographyService
                    .getHash(revocationPassPhraseSha256Input.toString(), "SHA-256");
            String certificateRequest = certificateRequestService
                    .createCertificateRequest(signatureAlgorithm, keyPair,
                            certificateRequestService.subjectForProxyId(proxyKey.id.getId())
                    );
            return ProxyRequest.builder()
                    .id(proxyKey.id.getId())
                    .revocationPassPhraseSha256(revocationPassPhraseSha256)
                    .requestEncoded(certificateRequest)
                    .build();
        } catch (Exception e) {
            Log.e(TAG, "Failed to create proxy request", e);
            throw new RuntimeException("Failed to create proxy request");
        }
    }

}
