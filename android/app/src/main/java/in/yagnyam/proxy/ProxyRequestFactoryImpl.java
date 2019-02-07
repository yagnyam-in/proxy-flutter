package in.yagnyam.proxy;

import android.util.Log;

import org.bouncycastle.crypto.CryptoException;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.KeyPair;
import java.util.UUID;

import in.yagnyam.proxy.services.BcCertificateRequestService;
import in.yagnyam.proxy.services.BcCryptographyService;
import in.yagnyam.proxy.services.CertificateRequestService;
import in.yagnyam.proxy.services.CryptographyService;
import in.yagnyam.proxy.services.MessageSerializerService;
import in.yagnyam.proxy.services.PemService;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ProxyRequestFactoryImpl implements MethodChannel.MethodCallHandler {
    private static final String TAG = "ProxyRequestFactoryImpl";
    public static final String CHANNEL = "proxy.yagnyam.in/ProxyRequestFactory";

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
        if (methodCall.method.equals("createProxyRequest")) {
            try {
                ProxyRequest request = createCertificateRequest(methodCall);
                result.success(messageSerializerService.serializeMessage(request));
            } catch (IllegalArgumentException e) {
                Log.e(TAG, "Error Creating Proxy Request", e);
                result.error("MISSING_ARGUMENTS", e.getMessage(), null);
            } catch (Exception e) {
                Log.e(TAG, "Error Creating Proxy Request", e);
                result.error("UNKNOWN_ERROR", e.getMessage(), null);
            }
        } else {
            result.notImplemented();
        }
    }

    private ProxyRequest createCertificateRequest(MethodCall methodCall) {
        Log.d(TAG, "createCertificateRequest(" + methodCall + ")");
        String id = arg(methodCall, "id");
        String signatureAlgorithm = arg(methodCall, "signatureAlgorithm");
        String revocationPassPhrase = arg(methodCall, "revocationPassPhrase");
        String keyGenerationAlgorithm = arg(methodCall, "keyGenerationAlgorithm");
        int keySize = Integer.valueOf(arg(methodCall, "keySize"));

        try {
            String localAlias = findLocalAlias(id);
            KeyPair keyPair = cryptographyService.generateKeyPair(keyGenerationAlgorithm, keySize);
            StringBuilder revocationPassPhraseSha256Input = new StringBuilder(id + "#" + revocationPassPhrase);
            while (revocationPassPhraseSha256Input.length() < 64) {
                revocationPassPhraseSha256Input.append("0");
            }
            String revocationPassPhraseSha256 = cryptographyService
                    .getHash(revocationPassPhraseSha256Input.toString(), "SHA-256");
            String certificateRequest = certificateRequestService
                    .createCertificateRequest(signatureAlgorithm, keyPair, certificateRequestService.subjectForProxyId(id));
            return ProxyRequest.builder()
                    .id(id)
                    .localAlias(localAlias)
                    .revocationPassPhraseSha256(revocationPassPhraseSha256)
                    .requestEncoded(certificateRequest)
                    .build();
        } catch (GeneralSecurityException | IOException | CryptoException e) {
            throw new RuntimeException("Failed to create proxy request");
        }
    }

    private String findLocalAlias(String id) throws CryptoException {
        String localAlias = id;
        for (int i=0; i<16; i++) {
            if (!UserKeyStore.containsAlias(id)) {
                return localAlias;
            }
            localAlias = UUID.randomUUID().toString();
        }
        throw new CryptoException("Unable to find local alias for proxy id " + id);
    }
}
