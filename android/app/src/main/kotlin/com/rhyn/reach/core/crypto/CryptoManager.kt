package com.rhyn.reach.core.crypto

import android.util.Base64
import android.util.Log
import java.io.DataInputStream
import java.io.InputStream
import java.io.OutputStream
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.SecureRandom
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import javax.crypto.Cipher
import javax.crypto.CipherInputStream
import javax.crypto.CipherOutputStream
import javax.crypto.KeyGenerator
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CryptoManager @Inject constructor() {

    private val secureRandom = SecureRandom()
    private val tag = "CryptoManager"

    // --- RSA KEY GENERATION ---

    fun generateNewKeyPair(): Pair<String, String> {
        val keyPairGenerator = KeyPairGenerator.getInstance("RSA")
        keyPairGenerator.initialize(2048)
        val keyPair = keyPairGenerator.generateKeyPair()

        val pubBase64 = Base64.encodeToString(keyPair.public.encoded, Base64.NO_WRAP)
        val privBase64 = Base64.encodeToString(keyPair.private.encoded, Base64.NO_WRAP)

        return Pair(pubBase64, privBase64)
    }

    // --- HYBRID ENCRYPTION (STRING PAYLOADS) ---

    fun encryptMessage(plaintext: String, publicKeyBase64: String): String {
        return try {
            val keyGen = KeyGenerator.getInstance("AES")
            keyGen.init(256)
            val aesKey = keyGen.generateKey()
            val iv = ByteArray(12)
            secureRandom.nextBytes(iv)

            val aesCipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, iv)
            aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, spec)
            val encryptedBody = aesCipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))

            val rsaKeyBytes = Base64.decode(publicKeyBase64, Base64.NO_WRAP)
            val rsaPublicKey = KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(rsaKeyBytes))
            val rsaCipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
            rsaCipher.init(Cipher.ENCRYPT_MODE, rsaPublicKey)
            val encryptedAesKey = rsaCipher.doFinal(aesKey.encoded)

            val keyLength = encryptedAesKey.size
            val result = java.nio.ByteBuffer.allocate(4 + keyLength + iv.size + encryptedBody.size)
                .putInt(keyLength)
                .put(encryptedAesKey)
                .put(iv)
                .put(encryptedBody)
                .array()

            Base64.encodeToString(result, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(tag, "Hybrid encryption failed for text payload", e)
            "ENCRYPTION_FAILED"
        }
    }

    fun decryptMessage(combinedBase64: String, privateKeyBase64: String): String {
        return try {
            val combined = Base64.decode(combinedBase64, Base64.NO_WRAP)
            val buffer = java.nio.ByteBuffer.wrap(combined)

            if (buffer.remaining() < 4) {
                throw IllegalArgumentException("Payload too short to contain a valid key length header")
            }

            val keyLength = buffer.int

            if (keyLength <= 0 || keyLength > buffer.remaining()) {
                throw IllegalArgumentException("Corrupted encrypted payload. Invalid key length: $keyLength")
            }

            val encryptedAesKey = ByteArray(keyLength)
            buffer.get(encryptedAesKey)

            if (buffer.remaining() < 12) {
                throw IllegalArgumentException("Payload missing IV or body")
            }

            val privKeyBytes = Base64.decode(privateKeyBase64, Base64.NO_WRAP)
            val rsaPrivateKey = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(privKeyBytes))
            val rsaCipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
            rsaCipher.init(Cipher.DECRYPT_MODE, rsaPrivateKey)
            val aesKeyBytes = rsaCipher.doFinal(encryptedAesKey)
            val aesKey = SecretKeySpec(aesKeyBytes, "AES")

            val iv = ByteArray(12)
            buffer.get(iv)
            val encryptedBody = ByteArray(buffer.remaining())
            buffer.get(encryptedBody)

            val aesCipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, iv)
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, spec)
            val decryptedBytes = aesCipher.doFinal(encryptedBody)

            String(decryptedBytes, Charsets.UTF_8)
        } catch (e: Exception) {
            Log.e(tag, "Hybrid decryption failed for text payload", e)
            "Encrypted Message"
        }
    }

    // --- HYBRID ENCRYPTION (FILE STREAMS) ---

    fun encryptStream(inputStream: InputStream, outputStream: OutputStream, publicKeyBase64: String) {
        try {
            val keyGen = KeyGenerator.getInstance("AES")
            keyGen.init(256)
            val aesKey = keyGen.generateKey()
            val iv = ByteArray(12)
            secureRandom.nextBytes(iv)

            val rsaKeyBytes = Base64.decode(publicKeyBase64, Base64.NO_WRAP)
            val rsaPublicKey = KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(rsaKeyBytes))
            val rsaCipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
            rsaCipher.init(Cipher.ENCRYPT_MODE, rsaPublicKey)
            val encryptedAesKey = rsaCipher.doFinal(aesKey.encoded)

            // Write header (Key Length + Encrypted AES Key + IV) directly to the output stream
            val headerBuffer = java.nio.ByteBuffer.allocate(4 + encryptedAesKey.size + iv.size)
                .putInt(encryptedAesKey.size)
                .put(encryptedAesKey)
                .put(iv)
                .array()
            outputStream.write(headerBuffer)

            val aesCipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, iv)
            aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, spec)

            val cipherOutputStream = CipherOutputStream(outputStream, aesCipher)

            val buffer = ByteArray(8192)
            var bytesRead: Int
            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                cipherOutputStream.write(buffer, 0, bytesRead)
            }

            cipherOutputStream.close()
            inputStream.close()
        } catch (e: Exception) {
            Log.e(tag, "Stream encryption failed during file processing", e)
            throw e
        }
    }

    fun decryptStream(inputStream: InputStream, outputStream: OutputStream, privateKeyBase64: String) {
        try {
            val dataInput = DataInputStream(inputStream)

            // Read Header
            val keyLength = dataInput.readInt()
            if (keyLength !in 1..1024) {
                throw IllegalArgumentException("Invalid key length parsed from stream: $keyLength")
            }

            val encryptedAesKey = ByteArray(keyLength)
            dataInput.readFully(encryptedAesKey)

            val iv = ByteArray(12)
            dataInput.readFully(iv)

            val privKeyBytes = Base64.decode(privateKeyBase64, Base64.NO_WRAP)
            val rsaPrivateKey = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(privKeyBytes))
            val rsaCipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
            rsaCipher.init(Cipher.DECRYPT_MODE, rsaPrivateKey)
            val aesKeyBytes = rsaCipher.doFinal(encryptedAesKey)
            val aesKey = SecretKeySpec(aesKeyBytes, "AES")

            val aesCipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, iv)
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, spec)

            val cipherInputStream = CipherInputStream(dataInput, aesCipher)

            val buffer = ByteArray(8192)
            var bytesRead: Int
            while (cipherInputStream.read(buffer).also { bytesRead = it } != -1) {
                outputStream.write(buffer, 0, bytesRead)
            }

            outputStream.flush()
            cipherInputStream.close()
            outputStream.close()
        } catch (e: Exception) {
            Log.e(tag, "Stream decryption failed during file processing", e)
            throw e
        }
    }

    // --- AES KEY ESCROW (PIN Logic) ---

    private fun generateAesKeyFromPin(pin: String, salt: ByteArray): SecretKeySpec {
        val iterationCount = 10000
        val keyLength = 256
        val spec = PBEKeySpec(pin.toCharArray(), salt, iterationCount, keyLength)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        val secretKeyBytes = factory.generateSecret(spec).encoded
        return SecretKeySpec(secretKeyBytes, "AES")
    }

    fun encryptPrivateKeyWithPin(rawPrivateKey: String, pin: String): String {
        val salt = ByteArray(16)
        val iv = ByteArray(16)
        secureRandom.nextBytes(salt)
        secureRandom.nextBytes(iv)

        val secretKey = generateAesKeyFromPin(pin, salt)
        val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, IvParameterSpec(iv))

        val encryptedBytes = cipher.doFinal(rawPrivateKey.toByteArray(Charsets.UTF_8))
        val combined = salt + iv + encryptedBytes
        return Base64.encodeToString(combined, Base64.NO_WRAP)
    }

    fun decryptPrivateKeyWithPin(lockedPrivateKeyBase64: String, pin: String): Result<String> {
        return try {
            val combined = Base64.decode(lockedPrivateKeyBase64, Base64.DEFAULT)
            val salt = combined.copyOfRange(0, 16)
            val iv = combined.copyOfRange(16, 32)
            val encryptedBytes = combined.copyOfRange(32, combined.size)

            val secretKey = generateAesKeyFromPin(pin, salt)
            val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
            cipher.init(Cipher.DECRYPT_MODE, secretKey, IvParameterSpec(iv))

            val decryptedBytes = cipher.doFinal(encryptedBytes)
            Result.success(String(decryptedBytes, Charsets.UTF_8))
        } catch (e: Exception) {
            Log.w(tag, "Failed to decrypt private key with provided PIN", e)
            Result.failure(Exception("Invalid PIN or corrupted key"))
        }
    }

    // --- Ed25519 SIGNATURES ---

    init {
        // Register BouncyCastle Provider for Ed25519 support on older APIs
        java.security.Security.removeProvider("BC")
        java.security.Security.addProvider(org.bouncycastle.jce.provider.BouncyCastleProvider())
    }

    fun generateEd25519KeyPair(): Pair<String, String> {
        val keyPairGenerator = KeyPairGenerator.getInstance("Ed25519", "BC")
        val keyPair = keyPairGenerator.generateKeyPair()

        val pubBase64 = Base64.encodeToString(keyPair.public.encoded, Base64.NO_WRAP)
        val privBase64 = Base64.encodeToString(keyPair.private.encoded, Base64.NO_WRAP)

        return Pair(pubBase64, privBase64)
    }

    fun signData(data: String, privateKeyBase64: String): String {
        return try {
            val privKeyBytes = Base64.decode(privateKeyBase64, Base64.NO_WRAP)
            val privateKey = KeyFactory.getInstance("Ed25519", "BC").generatePrivate(PKCS8EncodedKeySpec(privKeyBytes))
            
            val signature = java.security.Signature.getInstance("Ed25519", "BC")
            signature.initSign(privateKey)
            signature.update(data.toByteArray(Charsets.UTF_8))
            
            val sigBytes = signature.sign()
            Base64.encodeToString(sigBytes, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(tag, "Failed to sign data", e)
            ""
        }
    }

    fun verifySignature(data: String, signatureBase64: String, publicKeyBase64: String): Boolean {
        return try {
            val pubKeyBytes = Base64.decode(publicKeyBase64, Base64.NO_WRAP)
            val publicKey = KeyFactory.getInstance("Ed25519", "BC").generatePublic(X509EncodedKeySpec(pubKeyBytes))
            
            val signature = java.security.Signature.getInstance("Ed25519", "BC")
            signature.initVerify(publicKey)
            signature.update(data.toByteArray(Charsets.UTF_8))
            
            val sigBytes = Base64.decode(signatureBase64, Base64.NO_WRAP)
            signature.verify(sigBytes)
        } catch (e: Exception) {
            Log.e(tag, "Failed to verify signature", e)
            false
        }
    }
}