package com.dndy.mastek

import android.util.Log
import com.google.firebase.FirebaseException
import com.google.firebase.FirebaseTooManyRequestsException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException
import com.google.firebase.auth.FirebaseAuthMissingActivityForRecaptchaException
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthOptions
import com.google.firebase.auth.PhoneAuthProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
	private val tag = "MediMitraOTP"
	private val channelName = "com.dndy.mastek/otp"
	private var lastVerificationId: String? = null
	private var resendToken: PhoneAuthProvider.ForceResendingToken? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		// When overriding, explicitly register plugins to avoid MissingPluginException
		// for platform plugins like `printing`.
		GeneratedPluginRegistrant.registerWith(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
			when (call.method) {
				"sendOtp" -> {
					val phoneNumber = call.argument<String>("phoneNumber")
					if (phoneNumber.isNullOrBlank()) {
						result.error("invalid_args", "phoneNumber is required", null)
						return@setMethodCallHandler
					}

					val auth = FirebaseAuth.getInstance()

					val callbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
						override fun onVerificationCompleted(credential: PhoneAuthCredential) {
							// Instant verification / Auto-retrieval
							Log.d(tag, "onVerificationCompleted:$credential")
							signInWithPhoneAuthCredential(auth, credential) { ok, err ->
								if (ok) {
									// If auto-verification happened, there may be no onCodeSent.
									// Return a sentinel value so Dart can proceed.
									result.success("__verified__")
								} else {
									result.error("otp_failed", err ?: "OTP auto verification failed", null)
								}
							}
						}

						override fun onVerificationFailed(e: FirebaseException) {
							Log.w(tag, "onVerificationFailed", e)

							when (e) {
								is FirebaseAuthInvalidCredentialsException -> {
									// Invalid request
								}
								is FirebaseTooManyRequestsException -> {
									// SMS quota exceeded
								}
								is FirebaseAuthMissingActivityForRecaptchaException -> {
									// reCAPTCHA attempted with null Activity
								}
							}

							result.error("otp_failed", e.message ?: "OTP verification failed", null)
						}

						override fun onCodeSent(verificationId: String, token: PhoneAuthProvider.ForceResendingToken) {
							Log.d(tag, "onCodeSent:$verificationId")
							lastVerificationId = verificationId
							resendToken = token
							result.success(verificationId)
						}
					}

					val options = PhoneAuthOptions.newBuilder(auth)
						.setPhoneNumber(phoneNumber)
						.setTimeout(60L, TimeUnit.SECONDS)
						.setActivity(this)
						.setCallbacks(callbacks)
						.build()

					PhoneAuthProvider.verifyPhoneNumber(options)
				}

				"verifyOtp" -> {
					val verificationId = call.argument<String>("verificationId") ?: lastVerificationId
					val smsCode = call.argument<String>("smsCode")

					if (verificationId.isNullOrBlank() || smsCode.isNullOrBlank()) {
						result.error("invalid_args", "verificationId and smsCode are required", null)
						return@setMethodCallHandler
					}

					val auth = FirebaseAuth.getInstance()
					val credential = PhoneAuthProvider.getCredential(verificationId, smsCode)
					signInWithPhoneAuthCredential(auth, credential) { ok, err ->
						if (ok) result.success(true) else result.error("otp_invalid", err ?: "Invalid OTP", null)
					}
				}

				else -> result.notImplemented()
			}
		}
	}

	private fun signInWithPhoneAuthCredential(
		auth: FirebaseAuth,
		credential: PhoneAuthCredential,
		callback: (Boolean, String?) -> Unit,
	) {
		auth.signInWithCredential(credential)
			.addOnCompleteListener(this) { task ->
				if (task.isSuccessful) {
					Log.d(tag, "signInWithCredential:success")
					callback(true, null)
				} else {
					Log.w(tag, "signInWithCredential:failure", task.exception)
					callback(false, task.exception?.message)
				}
			}
	}
}
