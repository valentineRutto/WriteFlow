package com.example.writeflow

import android.app.Application
import com.example.writeflow.di.appModule
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin

class WriteFlowApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        startKoin {
            androidContext(this@WriteFlowApplication)
            modules(appModule)
        }
    }
}
