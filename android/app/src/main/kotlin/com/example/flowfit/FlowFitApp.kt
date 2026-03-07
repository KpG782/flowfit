package com.example.pulsify

import android.app.Application
import android.util.Log

/**
 * Custom Application class for Pulsify
 * Provides application-level initialization and context
 */
class PulsifyApp : Application() {
    companion object {
        private const val TAG = "PulsifyApp"
        
        /**
         * Global application instance
         * Useful for accessing application context from anywhere
         */
        lateinit var instance: PulsifyApp
            private set
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        Log.i(TAG, "✅ Pulsify Application initialized")
        Log.i(TAG, "📱 Application context available: ${applicationContext.javaClass.simpleName}")
    }
}
