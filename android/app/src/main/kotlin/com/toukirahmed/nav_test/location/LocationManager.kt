package com.toukirahmed.nav_test.location

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import android.location.Location
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import android.annotation.SuppressLint
import android.os.Looper
import kotlin.time.Duration.Companion.milliseconds
import androidx.core.content.edit
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult

class LocationManager(
    private val activity: Activity
) {
    companion object {

        private const val LOCATION_PERMISSION_REQUEST_CODE = 1001

        private const val PREFS_NAME =
            "location_preferences"

        private const val KEY_PERMISSION_REQUESTED =
            "location_permission_requested"

        private const val LOCATION_TIMEOUT_MILLIS =
            15_000L
    }

    private val preferences =
        activity.getSharedPreferences(
            PREFS_NAME,
            Context.MODE_PRIVATE
        )

    private val fusedLocationClient:
            FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(
            activity
        )

    private var locationCallback: LocationCallback? = null

    private var permissionCallback:
            ((PermissionStatus) -> Unit)? = null

    fun checkLocationPermission(): PermissionStatus {

        if (hasLocationPermission()) {
            return PermissionStatus.GRANTED
        }

        if (!hasRequestedPermission()) {
            return PermissionStatus.NOT_REQUESTED
        }

        return if (
            ActivityCompat.shouldShowRequestPermissionRationale(
                activity,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        ) {
            PermissionStatus.DENIED
        } else {
            PermissionStatus.PERMANENTLY_DENIED
        }
    }

    fun requestLocationPermission(
        callback: (PermissionStatus) -> Unit
    ) {
        permissionCallback = callback

        if (hasLocationPermission()) {

            permissionCallback = null

            callback(
                PermissionStatus.GRANTED
            )

            return
        }

        if (
            checkLocationPermission() ==
            PermissionStatus.PERMANENTLY_DENIED
        ) {
            permissionCallback = null

            callback(
                PermissionStatus.PERMANENTLY_DENIED
            )

            return
        }

        markPermissionAsRequested()

        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {

        if (
            requestCode !=
            LOCATION_PERMISSION_REQUEST_CODE
        ) {
            return
        }

        val status =
            checkLocationPermission()

        permissionCallback?.invoke(status)

        permissionCallback = null
    }

    private fun hasLocationPermission(): Boolean {

        val fineGranted =
            ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

        val coarseGranted =
            ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

        return fineGranted || coarseGranted
    }

    private fun hasRequestedPermission(): Boolean {

        return preferences.getBoolean(
            KEY_PERMISSION_REQUESTED,
            false
        )
    }

    private fun markPermissionAsRequested() {

        preferences.edit {
            putBoolean(
                KEY_PERMISSION_REQUESTED,
                true
            )
        }
    }

    fun isLocationServiceEnabled(): Boolean {

        val locationManager =
            activity.getSystemService(
                Context.LOCATION_SERVICE
            ) as LocationManager

        return locationManager.isProviderEnabled(
            LocationManager.GPS_PROVIDER
        ) || locationManager.isProviderEnabled(
            LocationManager.NETWORK_PROVIDER
        )
    }

    fun openLocationSettings() {
        val intent = Intent(
            Settings.ACTION_LOCATION_SOURCE_SETTINGS
        )

        activity.startActivity(intent)
    }

    fun openAppSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts(
                "package",
                activity.packageName,
                null
            )
        )

        activity.startActivity(intent)
    }

    suspend fun getCurrentLocation(): CurrentLocationResult {

        when (checkLocationPermission()) {

            PermissionStatus.NOT_REQUESTED,
            PermissionStatus.DENIED -> {

                return CurrentLocationResult.Error(
                    LocationErrorCodes.PERMISSION_DENIED
                )
            }

            PermissionStatus.PERMANENTLY_DENIED -> {

                return CurrentLocationResult.Error(
                    LocationErrorCodes
                        .PERMISSION_PERMANENTLY_DENIED
                )
            }

            PermissionStatus.GRANTED -> {
                // Continue
            }
        }


        if (!isLocationServiceEnabled()) {

            return CurrentLocationResult.Error(
                LocationErrorCodes.SERVICES_DISABLED
            )
        }


        return try {

            val location = withTimeout(
                LOCATION_TIMEOUT_MILLIS.milliseconds
            ) {
                requestCurrentLocation()
            }

            if (location != null) {

                CurrentLocationResult.Success(
                    latitude = location.latitude,
                    longitude = location.longitude
                )

            } else {

                CurrentLocationResult.Error(
                    LocationErrorCodes.TIMEOUT
                )
            }

        } catch (
            exception: TimeoutCancellationException
        ) {

            CurrentLocationResult.Error(
                LocationErrorCodes.TIMEOUT
            )

        } catch (
            exception: Exception
        ) {

            CurrentLocationResult.Error(
                LocationErrorCodes.UNKNOWN_ERROR
            )
        }
    }

    @SuppressLint("MissingPermission")
    private suspend fun requestCurrentLocation():
            Location? =
        suspendCancellableCoroutine { continuation ->

            val cancellationTokenSource =
                CancellationTokenSource()

            val request =
                CurrentLocationRequest.Builder()
                    .setPriority(
                        Priority.PRIORITY_HIGH_ACCURACY
                    )
                    .setMaxUpdateAgeMillis(0L)
                    .build()


            fusedLocationClient
                .getCurrentLocation(
                    request,
                    cancellationTokenSource.token
                )
                .addOnSuccessListener { location ->

                    if (continuation.isActive) {
                        continuation.resume(location)
                    }
                }
                .addOnFailureListener { exception ->

                    if (continuation.isActive) {
                        continuation.resumeWithException(
                            exception
                        )
                    }
                }


            continuation.invokeOnCancellation {

                cancellationTokenSource.cancel()
            }
        }


    @SuppressLint("MissingPermission")
    fun startLocationUpdates(
        onLocation: (latitude: Double, longitude: Double) -> Unit,
        onError: (String) -> Unit
    ) {
        if (!hasLocationPermission()) {
            onError(LocationErrorCodes.PERMISSION_DENIED)
            return
        }

        if (!isLocationServiceEnabled()) {
            onError(LocationErrorCodes.SERVICES_DISABLED)
            return
        }

        stopLocationUpdates()

        val locationRequest =
            LocationRequest.Builder(
                Priority.PRIORITY_HIGH_ACCURACY,
                5_000L
            )
                .setMinUpdateIntervalMillis(1_000L)
                .setMinUpdateDistanceMeters(5f)
                .setWaitForAccurateLocation(false)
                .build()

        locationCallback =
            object : LocationCallback() {

                override fun onLocationResult(
                    result: LocationResult
                ) {
                    val location =
                        result.lastLocation
                            ?: return

                    onLocation(
                        location.latitude,
                        location.longitude
                    )
                }
            }

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback!!,
            Looper.getMainLooper()
        ).addOnFailureListener {
            onError(LocationErrorCodes.UNKNOWN_ERROR)
        }
    }

    fun stopLocationUpdates() {
        locationCallback?.let { callback ->
            fusedLocationClient.removeLocationUpdates(callback)
        }

        locationCallback = null
    }
}