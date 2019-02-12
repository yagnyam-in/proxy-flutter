package in.yagnyam.proxy.channels;

import in.yagnyam.proxy.services.BcCertificateRequestService;
import in.yagnyam.proxy.services.BcCryptographyService;
import in.yagnyam.proxy.services.CertificateRequestService;
import in.yagnyam.proxy.services.CryptographyService;
import in.yagnyam.proxy.services.MessageSerializerService;
import in.yagnyam.proxy.services.PemService;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class CryptographyServiceImpl implements MethodChannel.MethodCallHandler {

    public static final String CHANNEL = "proxy.yagnyam.in/CryptographyService";

    private final MessageSerializerService messageSerializerService = MessageSerializerService.builder().build();
    private final PemService pemService = PemService.builder().build();
    private final CertificateRequestService certificateRequestService = BcCertificateRequestService.builder().pemService(pemService).build();
    private final CryptographyService cryptographyService = BcCryptographyService.builder().build();

    private String arg(MethodCall methodCall, String argumentName) {
        String value = methodCall.argument(argumentName);
        if (value == null) {
            throw new IllegalArgumentException("Missing " + argumentName);
        }
        return value;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        try {
            if (methodCall.method.equals("decrypt")) {
                result.notImplemented();
            } else {
                result.notImplemented();
            }
        } catch (IllegalArgumentException e) {
            result.error("MISSING_ARGUMENTS", e.getMessage(), null);
        } catch (Exception e) {
            result.error("UNKNOWN_ERROR", e.getMessage(), null);
        }
    }


}