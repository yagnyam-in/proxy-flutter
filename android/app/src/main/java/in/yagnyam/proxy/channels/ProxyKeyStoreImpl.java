package in.yagnyam.proxy.channels;

import android.util.Log;

import org.bouncycastle.crypto.CryptoException;

import java.security.KeyPair;
import java.security.cert.X509Certificate;
import java.util.LinkedHashMap;
import java.util.Map;

import in.yagnyam.proxy.Proxy;
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


public class ProxyKeyStoreImpl implements MethodChannel.MethodCallHandler, ChannelHelper {
    public static final String CHANNEL = "proxy.yagnyam.in/ProxyKeyStore";

    private static final String TAG = "ProxyKeyStoreImpl";

    private final Map<String, KeyPair> inTransitKeys = new LinkedHashMap<String, KeyPair>(23, .75F, true) {
        public boolean removeEldestEntry(Map.Entry<String, KeyPair> eldest) {
            return size() > 16;
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
            switch (methodCall.method) {
                case "createProxyKey": {
                    ProxyKey proxyKey = createProxyKey(methodCall);
                    result.success(messageSerializerService.serializeMessage(proxyKey));
                    break;
                }
                case "createProxyRequest": {
                    ProxyRequest proxyRequest = createProxyRequest(methodCall);
                    result.success(messageSerializerService.serializeMessage(proxyRequest));
                    break;
                }
                case "saveProxy": {
                    saveProxy(methodCall);
                    result.success(null);
                    break;
                }
                case "resolveProxyKey": {
                    ProxyKey proxyKey = resolveProxyKey(methodCall);
                    result.success(messageSerializerService.serializeMessage(proxyKey));
                    break;
                }
                default:
                    result.notImplemented();
                    break;
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
        for (int i = 1; i <= 32; i++) {
            if (!UserKeyStore.containsAlias(id)) {
                return localAlias;
            }
            localAlias = id + "-" + i;
        }
        throw new CryptoException("Unable to find local alias for proxy id " + id);
    }


    private ProxyRequest createProxyRequest(MethodCall methodCall) {
        Log.d(TAG, "createProxyRequest(" + methodCall + ")");
        try {
            ProxyKey proxyKey = messageSerializerService.deserializeMessage(arg(methodCall, "proxyKey"), ProxyKey.class);
            String signatureAlgorithm = arg(methodCall, "signatureAlgorithm");
            String revocationPassPhrase = arg(methodCall, "revocationPassPhrase");

            KeyPair keyPair = inTransitKeys.get(proxyKey.getLocalAlias());
            StringBuilder revocationPassPhraseSha256Input = new StringBuilder(proxyKey.getId() + "#" + revocationPassPhrase);
            while (revocationPassPhraseSha256Input.length() < 64) {
                revocationPassPhraseSha256Input.append("0");
            }
            String revocationPassPhraseSha256 = cryptographyService
                    .getHash("SHA-256", revocationPassPhraseSha256Input.toString());
            String certificateRequest = certificateRequestService
                    .createCertificateRequest(signatureAlgorithm, keyPair,
                            certificateRequestService.subjectForProxyId(proxyKey.getId().getId())
                    );
            return ProxyRequest.builder()
                    .id(proxyKey.getId().getId())
                    .revocationPassPhraseSha256(revocationPassPhraseSha256)
                    .requestEncoded(certificateRequest)
                    .build();
        } catch (Exception e) {
            Log.e(TAG, "Failed to create proxy request", e);
            throw new RuntimeException("Failed to create proxy request");
        }
    }

    private void saveProxy(MethodCall methodCall) {
        Log.d(TAG, "saveProxy(" + methodCall + ")");
        try {
            ProxyKey proxyKey = messageSerializerService.deserializeMessage(arg(methodCall, "proxyKey"), ProxyKey.class);
            Proxy proxy = messageSerializerService.deserializeMessage(arg(methodCall, "proxy"), Proxy.class);

            KeyPair keyPair = inTransitKeys.get(proxyKey.getLocalAlias());
            UserKeyStore.addSecretKey(proxyKey.getLocalAlias(), keyPair.getPrivate(), decodeCertificate(proxy.getCertificate().getCertificateEncoded()));

            Log.i(TAG, "List of keys " + UserKeyStore.getKeyAliases());
        } catch (Exception e) {
            Log.e(TAG, "Failed to create proxy key", e);
            throw new RuntimeException("Failed to create proxy key");
        }
    }

    private ProxyKey resolveProxyKey(MethodCall methodCall) {
        Log.d(TAG, "resolveProxyKey(" + methodCall + ")");
        try {
            return messageSerializerService.deserializeMessage(arg(methodCall, "proxyKey"), ProxyKey.class);
        } catch (Exception e) {
            Log.e(TAG, "Failed to resolve proxy key", e);
            throw new RuntimeException("Failed to resolve proxy key");
        }
    }

    private X509Certificate decodeCertificate(String certificateEncoded) throws CryptoException {
        try {
            return pemService.decodeCertificate(certificateEncoded);
        } catch (Exception e) {
            Log.e(TAG, "failed to decode certificate", e);
            throw new CryptoException("failed to decode certificate", e);
        }
    }


}
