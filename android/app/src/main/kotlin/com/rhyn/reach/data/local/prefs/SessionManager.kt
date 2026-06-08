package com.rhyn.reach.data.local.prefs

import android.content.Context
import android.content.SharedPreferences

import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SessionManager @Inject constructor(
    context: Context
) {
    private val prefs: SharedPreferences = context.getSharedPreferences("reach_auth", Context.MODE_PRIVATE)

    // --- GETTERS ---
    fun getJwtToken(): String? = prefs.getString("jwt_token", null)
    fun getUserId(): String? = prefs.getString("user_id", null)
    fun getUsername(): String? = prefs.getString("username", null)
    fun getSavedPassword(): String? = prefs.getString("saved_password", null)
    fun isCloudSynced(): Boolean = prefs.getBoolean("is_synced_to_cloud", false)

    // RSA Keys (Encryption)
    fun getPublicKey(): String? = prefs.getString("rsa_public_key", null)
    fun getPrivateKey(): String? = prefs.getString("rsa_private_key", null)

    // Ed25519 Keys (Signatures)
    fun getSigningPublicKey(): String? = prefs.getString("ed25519_public_key", null)
    fun getSigningPrivateKey(): String? = prefs.getString("ed25519_private_key", null)


    // --- SETTERS / SAVERS ---

    fun setCloudSynced(isSynced: Boolean) {
        prefs.edit().putBoolean("is_synced_to_cloud", isSynced).apply()
    }

    fun saveToken(token: String) {
        prefs.edit().putString("jwt_token", token).apply()
    }

    fun saveUserId(userId: String) {
        prefs.edit().putString("user_id", userId).apply()
    }

    fun saveUsername(username: String) {
        prefs.edit().putString("username", username).apply()
    }

    // RSA Keys (Encryption)
    fun savePublicKey(publicKey: String) {
        prefs.edit().putString("rsa_public_key", publicKey).apply()
    }

    fun savePrivateKey(privateKey: String) {
        prefs.edit().putString("rsa_private_key", privateKey).apply()
    }

    // Ed25519 Keys (Signatures)
    fun saveSigningPublicKey(key: String) {
        prefs.edit().putString("ed25519_public_key", key).apply()
    }

    fun saveSigningPrivateKey(key: String) {
        prefs.edit().putString("ed25519_private_key", key).apply()
    }

    // --- BATCH SAVERS ---

    fun saveLocalOfflineIdentity(userId: String, username: String, password: String, pubKey: String, privKey: String) {
        prefs.edit()
            .putString("user_id", userId)
            .putString("username", username)
            .putString("saved_password", password)
            .putString("rsa_public_key", pubKey)
            .putString("rsa_private_key", privKey)
            .putBoolean("is_synced_to_cloud", false)
            .apply()
    }

    fun logout() {
        prefs.edit().clear().apply()
    }
}