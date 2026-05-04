package com.nathanjones.morningroutine.viewmodel

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nathanjones.morningroutine.model.RoutineAction
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class TimerViewModel : ViewModel() {
    private val _remaining = mutableIntStateOf(0)
    val remainingSeconds: MutableState<Int> = _remaining
    private val _isRunning = mutableStateOf(false)
    val isRunning: MutableState<Boolean> = _isRunning
    private val _completed = mutableStateOf(false)
    val isCompleted: MutableState<Boolean> = _completed
    private val _currentIndex = mutableIntStateOf(0)
    val currentActionIndex: MutableState<Int> = _currentIndex
    private val _allDone = mutableStateOf(false)
    val allActionsCompleted: MutableState<Boolean> = _allDone
    private var actions: List<RoutineAction> = emptyList()
    private var timerJob: Job? = null

    val currentAction: RoutineAction? get() = actions.getOrNull(_currentIndex.intValue)
    val progress: Float
        get() {
            val act = currentAction ?: return 0f
            if (act.durationSeconds <= 0) return 0f
            return 1f - (_remaining.intValue.toFloat() / act.durationSeconds.toFloat())
        }
    val formattedRemainingTime: String
        get() {
            val m = _remaining.intValue / 60
            val s = _remaining.intValue % 60
            return String.format("%d:%02d", m, s)
        }
    val hasNextAction: Boolean get() = _currentIndex.intValue < actions.size - 1

    fun setupWithActions(list: List<RoutineAction>) {
        actions = list; _currentIndex.intValue = 0; _allDone.value = false
        _remaining.intValue = list.firstOrNull()?.durationSeconds ?: 0
        _isRunning.value = false; _completed.value = false
    }
    fun start() {
        if (_isRunning.value || _remaining.intValue <= 0) return
        _isRunning.value = true; _completed.value = false
        timerJob = viewModelScope.launch {
            while (_isRunning.value && _remaining.intValue > 0) {
                delay(1000); tick()
            }
        }
    }
    fun pause() { _isRunning.value = false; timerJob?.cancel(); timerJob = null }
    fun stop() { pause(); _remaining.intValue = currentAction?.durationSeconds ?: 0; _completed.value = false }
    fun reset() { pause(); _currentIndex.intValue = 0; _allDone.value = false; _remaining.intValue = actions.firstOrNull()?.durationSeconds ?: 0; _completed.value = false }
    fun moveToNextAction() {
        pause()
        if (_currentIndex.intValue < actions.size - 1) {
            _currentIndex.intValue += 1; _remaining.intValue = actions[_currentIndex.intValue].durationSeconds; _completed.value = false
        } else { _allDone.value = true }
    }
    private fun tick() {
        if (!_isRunning.value) return
        if (_remaining.intValue > 0) _remaining.intValue -= 1
        if (_remaining.intValue == 0 && _isRunning.value) { pause(); _completed.value = true }
    }
    override fun onCleared() { super.onCleared(); timerJob?.cancel() }
}
