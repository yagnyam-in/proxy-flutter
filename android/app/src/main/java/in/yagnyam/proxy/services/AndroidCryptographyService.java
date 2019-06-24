package in.yagnyam.proxy.services;

import org.bouncycastle.util.encoders.Base64;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.InvalidKeyException;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.SecureRandom;
import java.security.Signature;
import java.security.SignatureException;
import java.security.cert.Certificate;

import javax.crypto.spec.SecretKeySpec;
import javax.crypto.Cipher;
import javax.crypto.Mac;

import lombok.Builder;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Builder
public class AndroidCryptographyService implements CryptographyService {

    private static final Charset DEFAULT_CHARSET = Charset.forName("UTF-8");

    @NonNull
    private PemService pemService;


    @Override
    public String getHash(String hashAlgorithm, String message) throws GeneralSecurityException {
        MessageDigest digest = MessageDigest.getInstance(hashAlgorithm);
        byte[] hash = digest.digest(message.getBytes(StandardCharsets.UTF_8));
        return Base64.toBase64String(hash);
    }

    @Override
    public String getHmac(String hmacAlgorithm, String key, String message) throws GeneralSecurityException {
        Mac mac = Mac.getInstance(hmacAlgorithm);
        SecretKeySpec secretKey = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), hmacAlgorithm);
        mac.init(secretKey);
        byte[] hmac = mac.doFinal(message.getBytes(StandardCharsets.UTF_8));
        return Base64.toBase64String(hmac);
    }

    @Override
    public KeyPair generateKeyPair(String keyGenerationAlgorithm, int keySize) throws GeneralSecurityException {
        KeyPairGenerator generator = KeyPairGenerator.getInstance(keyGenerationAlgorithm);
        log.info("Using {}", generator.getProvider());
        generator.initialize(keySize, new SecureRandom());
        return generator.generateKeyPair();
    }

    @Override
    public String getSignature(String algorithm, PrivateKey privateKey, String input)
            throws GeneralSecurityException {
        try {
            Signature signatureInstance = Signature.getInstance(algorithm);
            signatureInstance.initSign(privateKey);
            signatureInstance.update(input.getBytes(DEFAULT_CHARSET));
            return Base64.toBase64String(signatureInstance.sign());
        } catch (NoSuchAlgorithmException | InvalidKeyException | SignatureException e) {
            log.error("Error signing for algorithm " + algorithm, e);
            throw new GeneralSecurityException(e);
        }
    }

    @Override
    public boolean verifySignature(String algorithm, Certificate certificate, String input,
                                   String signature) throws GeneralSecurityException {
        try {
            Signature signatureInstance = Signature.getInstance(algorithm);
            signatureInstance.initVerify(certificate);
            signatureInstance.update(input.getBytes(DEFAULT_CHARSET));
            return signatureInstance.verify(Base64.decode(signature.getBytes(DEFAULT_CHARSET)));
        } catch (NoSuchAlgorithmException | InvalidKeyException | SignatureException e) {
            log.error("Error verifying signature of algorithm " + algorithm, e);
            throw new GeneralSecurityException(e);
        }
    }

    @Override
    public String encrypt(String encryptionAlgorithm, Certificate certificate, String input)
            throws GeneralSecurityException {
        Cipher cipher = Cipher.getInstance(encryptionAlgorithm);
        cipher.init(Cipher.ENCRYPT_MODE, certificate);
        byte[] cipherText = cipher.doFinal(input.getBytes(DEFAULT_CHARSET));
        return Base64.toBase64String(cipherText);
    }

    @Override
    public String decrypt(String encryptionAlgorithm, PrivateKey privateKey, String cipherText)
            throws GeneralSecurityException {
        Cipher cipher = Cipher.getInstance(encryptionAlgorithm);
        cipher.init(Cipher.DECRYPT_MODE, privateKey);
        byte[] originalText = cipher.doFinal(Base64.decode(cipherText.getBytes(DEFAULT_CHARSET)));
        return new String(originalText, DEFAULT_CHARSET);
    }


}
