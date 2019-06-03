package in.yagnyam.proxy.channels;

import android.util.Log;

import org.bouncycastle.crypto.CryptoException;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.PrivateKey;
import java.security.cert.X509Certificate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import in.yagnyam.proxy.Proxy;
import in.yagnyam.proxy.UserKeyStore;
import in.yagnyam.proxy.services.AndroidCryptographyService;
import in.yagnyam.proxy.services.CryptographyService;
import in.yagnyam.proxy.services.MessageSerializerService;
import in.yagnyam.proxy.services.PemService;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class CryptographyServiceImpl implements MethodChannel.MethodCallHandler, ChannelHelper {

    private static final String TAG = "CryptographyServiceImpl";
    public static final String CHANNEL = "proxy.yagnyam.in/CryptographyService";

    private final MessageSerializerService messageSerializerService = MessageSerializerService.builder().build();
    private final PemService pemService = PemService.builder().build();
    private final CryptographyService cryptographyService = AndroidCryptographyService.builder().pemService(pemService).build();


    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        Log.d(TAG, "onMethodCall(" + methodCall + ")");
        try {
            switch (methodCall.method) {
                case "decrypt": {
                    result.success(decrypt(methodCall));
                    break;
                }
                case "encrypt": {
                    result.success(encrypt(methodCall));
                    break;
                }
                case "getSignatures": {
                    result.success(getSignatures(methodCall));
                    break;
                }
                case "verifySignatures": {
                    result.success(verifySignatures(methodCall));
                    break;
                }
                case "hash": {
                    result.success(hash(methodCall));
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

    private String decrypt(MethodCall methodCall) {
        throw new RuntimeException("Not yet implemented");
    }


    private String encrypt(MethodCall methodCall) {
        throw new RuntimeException("Not yet implemented");
    }


    private boolean verifySignatures(MethodCall methodCall) throws CryptoException {
        try {
            Proxy proxy = messageSerializerService.deserializeMessage(stringArgument(methodCall, "proxy"), Proxy.class);
            X509Certificate certificate = pemService.decodeCertificate(proxy.getCertificate().getCertificateEncoded());
            String input = stringArgument(methodCall, "input");
            Map<String, String> signatures = mapOfStringsArgument(methodCall, "signatures");
            boolean valid = true;
            for (Map.Entry<String, String> signature : signatures.entrySet()) {
                valid = valid && cryptographyService.verifySignature(signature.getKey(), certificate, input, signature.getValue());
            }
            return valid;
        } catch (IOException | GeneralSecurityException e) {
            Log.e(TAG, "failed to verify signatures", e);
            throw new CryptoException("failed to verify signatures", e);
        }
    }

    private Map<String, String> getSignatures(MethodCall methodCall) throws CryptoException {
        try {
            String input = stringArgument(methodCall, "input");
            List<String> algorithms = stringArrayArgument(methodCall, "algorithms");
            ProxyKey proxyKey = messageSerializerService.deserializeMessage(stringArgument(methodCall, "proxyKey"), ProxyKey.class);
            PrivateKey privateKey = UserKeyStore.getSecretKey(proxyKey.getLocalAlias());
            Map<String, String> signatures = new HashMap<>();
            for (String algorithm : algorithms) {
                signatures.put(algorithm, cryptographyService.getSignature(algorithm, privateKey, input));
            }
            Log.i(TAG, "getSignatures(" + algorithms + ") => " + signatures);
            return signatures;
        } catch (IOException | GeneralSecurityException e) {
            Log.e(TAG, "failed to sign message", e);
            throw new CryptoException("failed to sign message", e);
        }
    }

    private String hash(MethodCall methodCall) throws CryptoException {
        try {
            String input = stringArgument(methodCall, "input");
            String hashAlgorithm = stringArgument(methodCall, "hashAlgorithm");
            String result = cryptographyService.getHash(hashAlgorithm, input);
            Log.i(TAG, "hash(" + hashAlgorithm + ", " + input + ") => " + result);
            return result;
        } catch (GeneralSecurityException e) {
            Log.e(TAG, "failed to get hash", e);
            throw new CryptoException("failed to get hash", e);
        }
    }


}
