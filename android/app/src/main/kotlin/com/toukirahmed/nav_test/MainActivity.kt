package com.toukirahmed.nav_test

import com.toukirahmed.nav_test.channel.LocationChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private lateinit var locationChannel: LocationChannel

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        locationChannel = LocationChannel(activity = this)

        locationChannel.register(
            flutterEngine.dartExecutor.binaryMessenger
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        locationChannel.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )
    }
}