package com.example.proxyflutter;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.NonNull;
import lombok.ToString;


@Builder
@NoArgsConstructor(access = AccessLevel.PRIVATE)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Getter
@ToString
public class ProxyRequest {

    @NonNull
    private String id;

    private String alias;

    @NonNull
    private String revocationPassPhraseSha256;

    @NonNull
    private String requestEncoded;
}
