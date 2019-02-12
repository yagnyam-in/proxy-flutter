package in.yagnyam.proxy;

import android.util.Log;

import org.bouncycastle.crypto.CryptoException;

import java.io.IOException;
import java.math.BigInteger;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import in.yagnyam.proxy.services.PemService;

/**
 * Easier interface to generate keys
 */
public class UserKeyStore {

    public static final String PROVIDER = "AndroidKeyStore";
    private static final String TAG = "UserKeyStore";

    private static final Object keyStoreLock = new Object();
    private static AtomicReference<KeyStore> keyStoreRef = new AtomicReference<>();

    public static KeyStore getKeyStore() throws CryptoException {
        KeyStore keyStore = keyStoreRef.get();
        if (keyStore == null) {
            synchronized (keyStoreLock) {
                keyStore = bootstrap();
                keyStoreRef.set(keyStore);
            }
        }
        return keyStore;
    }

    private static KeyStore bootstrap() throws CryptoException {
        String caSerial = "1646464037041216499760";
        String caSha256Thumbprint = "wEj0uicGyQftTlcFXPoV66p4SwvuCoN3fK94cDVz1O0";
        String caCertificateEncoded = "-----BEGIN CERTIFICATE-----\n" +
                "MIIDrTCCApWgAwIBAgIJWUFHTllBTTAwMA0GCSqGSIb3DQEBCwUAMGgxGDAWBgNV\n" +
                "BAMMD1lhZ255YW0gcm9vdCBDQTEeMBwGA1UECgwVWWFnbnlhbSBFY29tbWVyY2Ug\n" +
                "TExQMRIwEAYDVQQHDAlCYW5nYWxvcmUxCzAJBgNVBAgMAktBMQswCQYDVQQGEwJJ\n" +
                "TjAeFw0xODAxMDYxOTM2MTdaFw00MzAxMDYxOTM2MTdaMGgxGDAWBgNVBAMMD1lh\n" +
                "Z255YW0gcm9vdCBDQTEeMBwGA1UECgwVWWFnbnlhbSBFY29tbWVyY2UgTExQMRIw\n" +
                "EAYDVQQHDAlCYW5nYWxvcmUxCzAJBgNVBAgMAktBMQswCQYDVQQGEwJJTjCCASIw\n" +
                "DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKLcZk7iYTVP3EcpdiH3FhmOAzdb\n" +
                "eim4aOwZws72z7MbKM55gUVRxOoUpcSg5l0O7BbSNLQ30/6r5Y2wX0GWaXVIvfr1\n" +
                "eIfd+R91EaVjJkiG1WtMLOfd0po4zsXbecAAGGY1XpBSbQ4gAOqdlMYXzMplvp7p\n" +
                "Sj8CEKR8hLEGsIPPaEFf8LSPscPKoxoeubJVpc4WXjZF+GJz/ye9PTQutW5VY0VB\n" +
                "7UeZbSyN6NIjSamtlGl5Ow1OPmx0Svj1yQ5ZgnsnogU4nm3hjeijHr96A1Y7BhB8\n" +
                "rRC0HKGji6LcVb8HnecfruUnTb5fLb9sA9O2nHKovf2oVzQLONCIyNVOjJMCAwEA\n" +
                "AaNaMFgwHQYDVR0OBBYEFAN+/B4BibY86lHAxRMyZFtumyFPMA8GA1UdEwEB/wQF\n" +
                "MAMBAf8wCwYDVR0PBAQDAgG2MBkGA1UdJQQSMBAGCCsGAQUFBwMBBgRVHSUAMA0G\n" +
                "CSqGSIb3DQEBCwUAA4IBAQAVgRZGhTjHGtOJFTYWw1gnlKH1M4yLSPboAgxou1wV\n" +
                "bAsSz2GQO91SqVD/kdih+HIubuSYdNJoGpOeYopb7pHubIQ7+Tx74/GdJ7YayVAN\n" +
                "8GY3hrlrQwSePzecDnaRLygflDEH/BztCPQubNmCtpJrbsKKCGCPm2JlgmxSn2hG\n" +
                "7rmCb19aAZZMUqnD4ptF7kjMwACp6JJ9W40mIo3dRNus2Y7HzkCBMMK1bBn/7OKH\n" +
                "X8wWi+QbNY7l3fVKmPkIjPko4PmRp0Qq53Tr4LqcWoQJ8BmDhRLnH3MElDdzhlY4\n" +
                "aHPZ+mEFHSpAY5/GJdbYgTZ8Iv2BMAslRO0h0CwayPuE\n" +
                "-----END CERTIFICATE-----";
        try {
            KeyStore keyStore = KeyStore.getInstance(PROVIDER);
            keyStore.load(null);
            Certificate existing = keyStore.getCertificate(caSerial);
            if (existing == null) {
                X509Certificate caCertificate = PemService.builder().build().decodeCertificate(caCertificateEncoded);
                keyStore.setCertificateEntry(caSerial, caCertificate);
            }
            return keyStore;
        } catch (Exception e) {
            Log.e(TAG, "failed to add root certificate", e);
            throw new CryptoException("failed to add root certificate", e);
        }
    }


    public static boolean containsAlias(String alias) throws CryptoException {
        try {
            return getKeyStore().containsAlias(alias);
        } catch (Exception e) {
            Log.e(TAG, "failed to inquire key alias", e);
            throw new CryptoException("failed to inquire key alias", e);
        }
    }

    public static List<String> getKeyAliases() throws CryptoException {
        try {
            List<String> keyAliases = new ArrayList<>();
            Enumeration<String> aliases = getKeyStore().aliases();
            while (aliases.hasMoreElements()) {
                String alias = aliases.nextElement();
                Log.i(TAG, "Got entry " + alias);
                if (getKeyStore().isKeyEntry(alias)) {
                    Log.d(TAG, "found key alias - " + alias);
                    keyAliases.add(alias);
                }
            }
            return keyAliases;
        } catch (Exception e) {
            Log.e(TAG, "failed to query key aliases", e);
            throw new CryptoException("failed to query key aliases", e);
        }
    }

    /*
    public static ProxyKey getProxyKey(ProxyId proxyId, String alias) throws CryptoException {
        try {
            KeyStore.PrivateKeyEntry keyEntry = (KeyStore.PrivateKeyEntry) getKeyStore()
                    .getEntry(alias, null);
            if (keyEntry == null) {
                return null;
            }
            if (keyEntry.getCertificateChain().length > 0) {
                Log.d(TAG, "Key " + alias + " has following following certificates");
                for (Certificate c : keyEntry.getCertificateChain()) {
                    X509Certificate x509Certificate = (X509Certificate) c;
                    Log.d(TAG, "Serial :" + x509Certificate.getSerialNumber());
                    Log.d(TAG, "Principal :" + x509Certificate.getSubjectX500Principal());
                }
            }
            return keyEntry.getPrivateKey();
            // return PemUtils.decodePrivateKey(PemUtils.encodePrivateKey(keyEntry.getPrivateKey()));
        } catch (GeneralSecurityException e) {
            Log.e(TAG, "Failed to retrieve private Key: " + alias, e);
            throw new CryptoException("Failed to retrieve private Key: " + alias, e);
        }
    }
    */

    public static List<String> getCertificateAliases() throws CryptoException {
        try {
            List<String> keyAliases = new ArrayList<>();
            Enumeration<String> aliases = getKeyStore().aliases();
            while (aliases.hasMoreElements()) {
                String alias = aliases.nextElement();
                if (getKeyStore().isCertificateEntry(alias)) {
                    Log.d(TAG, "found certificate alias - " + alias);
                    keyAliases.add(alias);
                }
            }
            return keyAliases;
        } catch (KeyStoreException e) {
            Log.e(TAG, "failed to query certificate aliases", e);
            throw new CryptoException("failed to query certificate aliases", e);
        }
    }

    public static boolean containsKeyAliases(String alias) throws CryptoException {
        try {
            return getKeyStore().containsAlias(alias);
        } catch (KeyStoreException e) {
            Log.e(TAG, "failed to query key aliases", e);
            throw new CryptoException("failed to query key aliases", e);
        }
    }

    public static void addSecretKey(String alias, PrivateKey privateKey, X509Certificate[] certChain)
            throws CryptoException {
        try {
            // mKeyStore.deleteEntry(alias);
            getKeyStore().setKeyEntry(alias, privateKey, null, certChain);
        } catch (KeyStoreException e) {
            Log.e(TAG, "failed to add secret key: " + alias, e);
            throw new CryptoException("failed to add secret key: " + alias, e);
        }
    }

    public static void addCertificate(String alias, X509Certificate cert) throws CryptoException {
        try {
            getKeyStore().setCertificateEntry(alias, cert);
        } catch (KeyStoreException e) {
            Log.e(TAG, "failed to add certificate: " + cert.getSubjectX500Principal(), e);
            throw new CryptoException("failed to add certificate: " + cert.getSubjectX500Principal(), e);
        }
    }

    public static X509Certificate getCertificate(String alias, String certificateSerial)
            throws CryptoException {
        Log.d(TAG, "getCertificate(" + alias + ", " + certificateSerial + ")");
        try {
            KeyStore.PrivateKeyEntry keyEntry = (KeyStore.PrivateKeyEntry) getKeyStore()
                    .getEntry(alias, null);
            if (keyEntry == null) {
                Log.w(TAG, "No Key Store Entry found: " + alias);
                throw new IllegalArgumentException("No Key Store Entry Found:" + alias);
            }
            if (keyEntry.getCertificateChain().length > 0) {
                Log.d(TAG, "Key " + alias + " has following following certificates");
                for (Certificate c : keyEntry.getCertificateChain()) {
                    X509Certificate x509Certificate = (X509Certificate) c;
                    if (x509Certificate.getSerialNumber().equals(new BigInteger(certificateSerial))) {
                        Log.d(TAG,
                                "getCertificate(" + alias + ", " + certificateSerial + ") => " + x509Certificate);
                        return x509Certificate;
                    }
                }
            }
            Log.w(TAG, "getCertificate(" + alias + ", " + certificateSerial + ") => null");
            throw new IllegalArgumentException("No Certificate Found: " + certificateSerial);
            // return PemUtils.decodePrivateKey(PemUtils.encodePrivateKey(keyEntry.getPrivateKey()));
        } catch (GeneralSecurityException e) {
            Log.e(TAG, "Failed to retrieve Certificate: " + alias, e);
            throw new CryptoException("Failed to retrieve Certificate: " + alias, e);
        }
    }

}