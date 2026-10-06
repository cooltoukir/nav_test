package com.toukirahmed.nav_test.location

sealed class CurrentLocationResult {

    data class Success(
        val latitude: Double,
        val longitude: Double
    ) : CurrentLocationResult()

    data class Error(
        val code: String
    ) : CurrentLocationResult()
}
