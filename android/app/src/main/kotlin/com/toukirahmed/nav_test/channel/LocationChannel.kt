package com.toukirahmed.nav_test.channel

import android.app.Activity
import com.toukirahmed.nav_test.location.CurrentLocationResult
import com.toukirahmed.nav_test.location.LocationManager
import com.toukirahmed.nav_test.location.PermissionStatus
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import io.flutter.plugin.common.EventChannel

class LocationChannel(
    activity: Activity
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val CHANNEL_NAME =
            "com.toukirahmed.nav_test/location"

        const val LOCATION_STREAM_CHANNEL =
            "com.toukirahmed.nav_test/location_stream"
    }

    private val locationManager = LocationManager(activity)
    private var eventSink: EventChannel.EventSink? = null
    private val scope =
        CoroutineScope(
            SupervisorJob() + Dispatchers.Main
        )

    fun register(
        messenger: BinaryMessenger
    ) {
        MethodChannel(
            messenger,
            CHANNEL_NAME
        ).setMethodCallHandler(this)

        EventChannel(
            messenger,
            LOCATION_STREAM_CHANNEL
        ).setStreamHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {

            "checkPermission" -> {

                val status =
                    locationManager.checkLocationPermission()

                result.success(
                    status.toFlutterValue()
                )
            }

            "requestPermission" -> {

                locationManager.requestLocationPermission { status ->

                    result.success(
                        status.toFlutterValue()
                    )
                }
            }

            "isLocationEnabled" -> {
                val enabled =
                    locationManager.isLocationServiceEnabled()

                result.success(enabled)
            }

            "openLocationSettings" -> {
                locationManager.openLocationSettings()
                result.success(null)
            }

            "openAppSettings" -> {
                locationManager.openAppSettings()
                result.success(null)
            }

            "getCurrentLocation" -> {

                scope.launch {

                    when (
                        val location =
                            locationManager
                                .getCurrentLocation()
                    ) {

                        is CurrentLocationResult.Success -> {

                            result.success(
                                mapOf(
                                    "latitude" to
                                            location.latitude,

                                    "longitude" to
                                            location.longitude
                                )
                            )
                        }

                        is CurrentLocationResult.Error -> {

                            result.success(
                                mapOf(
                                    "error" to
                                            location.code
                                )
                            )
                        }
                    }
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        locationManager.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )
    }

    private fun PermissionStatus.toFlutterValue(): String {
        return when (this) {

            PermissionStatus.NOT_REQUESTED ->
                "notRequested"

            PermissionStatus.GRANTED ->
                "granted"

            PermissionStatus.DENIED ->
                "denied"

            PermissionStatus.PERMANENTLY_DENIED ->
                "permanentlyDenied"
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        eventSink = events

        locationManager.startLocationUpdates(
            onLocation = { latitude, longitude ->

                eventSink?.success(
                    mapOf(
                        "latitude" to latitude,
                        "longitude" to longitude
                    )
                )
            },
            onError = { error ->

                eventSink?.error(
                    error,
                    null,
                    null
                )
            }
        )
    }

    override fun onCancel(
        arguments: Any?
    ) {
        locationManager.stopLocationUpdates()
        eventSink = null
    }
}