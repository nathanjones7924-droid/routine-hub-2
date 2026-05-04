package com.nathanjones.morningroutine.viewmodel

import android.app.Application
import android.os.Looper
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.Calendar
import kotlin.math.acos
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.tan

class LocationViewModel(application: Application) : AndroidViewModel(application) {
    private val fused = LocationServices.getFusedLocationProviderClient(application)
    private val _sunrise = MutableStateFlow<Long?>(null)
    val sunriseTimeMillis: StateFlow<Long?> = _sunrise
    private val _hasPermission = mutableStateOf(false)
    val hasPermission: MutableState<Boolean> = _hasPermission
    private val _city = MutableStateFlow<String?>(null)
    val cityName: StateFlow<String?> = _city

    private val callback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val loc = result.lastLocation ?: return
            fused.removeLocationUpdates(this)
            calculateSunrise(loc.latitude, loc.longitude)
            _city.value = String.format("%.4f, %.4f", loc.latitude, loc.longitude)
        }
    }
    fun onPermissionResult(granted: Boolean) {
        _hasPermission.value = granted
        if (granted) requestLocation()
    }
    fun requestLocation() {
        if (!_hasPermission.value) return
        try {
            val req = LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, 10000).build()
            fused.requestLocationUpdates(req, callback, Looper.getMainLooper())
        } catch (_: SecurityException) {}
    }
    fun requestSingleLocation() {
        if (!_hasPermission.value) return
        try {
            fused.lastLocation.addOnSuccessListener { loc ->
                if (loc != null) {
                    calculateSunrise(loc.latitude, loc.longitude)
                    _city.value = String.format("%.4f, %.4f", loc.latitude, loc.longitude)
                } else { requestLocation() }
            }
        } catch (_: SecurityException) {}
    }
    private fun calculateSunrise(lat: Double, lon: Double) {
        val calendar = Calendar.getInstance()
        val dayOfYear = calendar.get(Calendar.DAY_OF_YEAR)
        val tzOffset = calendar.timeZone.rawOffset / 3600000
        val b = Math.toRadians((dayOfYear - 81) * 360.0 / 365.0)
        val eot = 9.87 * kotlin.math.sin(2 * b) - 7.53 * kotlin.math.cos(b) - 1.5 * kotlin.math.sin(b)
        val decl = Math.toRadians(23.44 * kotlin.math.sin(b))
        val latRad = Math.toRadians(lat)
        val cosH = -tan(latRad) * tan(decl)
        if (cosH < -1.0 || cosH > 1.0) { _sunrise.value = 6 * 60 * 60 * 1000L; return }
        val h = Math.toDegrees(acos(cosH))
        val sunriseHours = (720.0 - 4.0 * (lon + h) - eot + tzOffset * 60.0) / 60.0
        val hours = sunriseHours.toInt().coerceIn(0, 23)
        val minutes = ((sunriseHours - hours) * 60).toInt().coerceIn(0, 59)
        _sunrise.value = ((hours * 60 + minutes) * 60 * 1000).toLong()
    }
    override fun onCleared() { super.onCleared(); fused.removeLocationUpdates(callback) }
}
