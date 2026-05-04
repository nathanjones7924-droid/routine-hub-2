package com.nathanjones.morningroutine.viewmodel

import android.app.Application
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.nathanjones.morningroutine.model.Routine
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

private val Application.dataStore by preferencesDataStore("morning_routine_prefs")

class RoutineViewModel(application: Application) : AndroidViewModel(application) {
    private val dataStore = application.dataStore
    private val json = Json { ignoreUnknownKeys = true }
    private val _routines = MutableStateFlow<List<Routine>>(emptyList())
    val routines: StateFlow<List<Routine>> = _routines
    private val _selectedRoutineId = MutableStateFlow<String?>(null)
    val selectedRoutineId: StateFlow<String?> = _selectedRoutineId
    private val _isExecuting = MutableStateFlow(false)
    val isExecuting: StateFlow<Boolean> = _isExecuting
    private val _executingRoutine = MutableStateFlow<Routine?>(null)
    val executingRoutine: StateFlow<Routine?> = _executingRoutine

    val selectedRoutine: Routine?
        get() = _selectedRoutineId.value?.let { id -> _routines.value.firstOrNull { it.id == id } }

    companion object {
        private val ROUTINES_KEY = stringPreferencesKey("saved_routines")
        private val SELECTED_KEY = stringPreferencesKey("selected_routine_id")
    }
    init {
        viewModelScope.launch {
            val saved = dataStore.data.map { it[ROUTINES_KEY]?.let { s -> json.decodeFromString<List<Routine>>(s) } ?: emptyList() }.first()
            _routines.value = saved
            val sel = dataStore.data.map { it[SELECTED_KEY] }.first()
            _selectedRoutineId.value = if (sel != null && saved.any { it.id == sel }) sel else saved.firstOrNull()?.id
        }
    }
    fun addRoutine(routine: Routine) {
        _routines.value += routine
        if (_routines.value.size == 1) { _selectedRoutineId.value = routine.id; saveSelected() }
        saveRoutines()
    }
    fun updateRoutine(routine: Routine) {
        val list = _routines.value.toMutableList()
        val idx = list.indexOfFirst { it.id == routine.id }
        if (idx != -1) { list[idx] = routine; _routines.value = list; saveRoutines() }
    }
    fun deleteRoutine(routine: Routine) {
        _routines.value = _routines.value.filter { it.id != routine.id }
        if (_selectedRoutineId.value == routine.id) { _selectedRoutineId.value = _routines.value.firstOrNull()?.id; saveSelected() }
        saveRoutines()
    }
    fun selectRoutine(routine: Routine) { _selectedRoutineId.value = routine.id; saveSelected() }
    fun startRoutine(routine: Routine) { _executingRoutine.value = routine; _isExecuting.value = true }
    fun stopRoutine() { _executingRoutine.value = null; _isExecuting.value = false }
    fun resetAllData() {
        _routines.value = emptyList(); _selectedRoutineId.value = null; _isExecuting.value = false; _executingRoutine.value = null
        viewModelScope.launch { dataStore.edit { it.clear() } }
    }
    private fun saveRoutines() {
        viewModelScope.launch { dataStore.edit { it[ROUTINES_KEY] = json.encodeToString(_routines.value) } }
    }
    private fun saveSelected() {
        viewModelScope.launch { dataStore.edit { id -> _selectedRoutineId.value?.let { id[SELECTED_KEY] = it } ?: id.remove(SELECTED_KEY) } }
    }
}
