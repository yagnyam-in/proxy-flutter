package in.yagnyam.proxy.channels;

import android.util.Log;

import java.util.List;
import java.util.Map;

import in.yagnyam.proxy.ProxyId;
import io.flutter.plugin.common.MethodCall;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.NonNull;
import lombok.ToString;

public interface ChannelHelper {

    @Builder
    @NoArgsConstructor(access = AccessLevel.PRIVATE)
    @AllArgsConstructor(access = AccessLevel.PRIVATE)
    @Getter
    @ToString
    class ProxyKey {

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
    class ProxyRequest {

        @NonNull
        private String id;

        @NonNull
        private String revocationPassPhraseSha256;

        @NonNull
        private String requestEncoded;
    }


    default String stringArgument(MethodCall methodCall, String argumentName) {
        String value = methodCall.argument(argumentName);
        if (value == null) {
            throw new IllegalArgumentException("Missing " + argumentName);
        }
        return value;
    }


    default List<String> stringArrayArgument(MethodCall methodCall, String argumentName) {
        List<String> value = methodCall.argument(argumentName);
        if (value == null) {
            throw new IllegalArgumentException("Missing " + argumentName);
        }
        return value;
    }

    default Map<String, String> mapOfStringsArgument(MethodCall methodCall, String argumentName) {
        Map<String, String> value = methodCall.argument(argumentName);
        if (value == null) {
            throw new IllegalArgumentException("Missing " + argumentName);
        }
        return value;
    }



}
