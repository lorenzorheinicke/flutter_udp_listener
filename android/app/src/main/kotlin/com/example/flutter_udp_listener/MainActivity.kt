package com.example.flutter_udp_listener

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.DatagramPacket
import java.net.DatagramSocket
import kotlinx.coroutines.*
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example/udp_channel"
    private var udpSocket: DatagramSocket? = null
    private var isListening = false
    private val scope = CoroutineScope(Dispatchers.IO + Job())
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startUDPServer" -> {
                    val port = call.argument<Int>("port") ?: 65001
                    startUDPServer(port)
                    result.success("UDP Server started on port $port")
                }
                "stopUDPServer" -> {
                    stopUDPServer()
                    result.success("UDP Server stopped")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startUDPServer(port: Int) {
        if (isListening) return
        
        isListening = true
        scope.launch {
            try {
                udpSocket = DatagramSocket(port)
                val buffer = ByteArray(1024)
                
                while (isListening) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    try {
                        udpSocket?.receive(packet)
                        val message = String(packet.data, 0, packet.length)
                        val senderAddress = packet.address.hostAddress
                        val senderPort = packet.port
                        
                        withContext(Dispatchers.Main) {
                            flutterEngine?.let { engine ->
                                val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                                channel.invokeMethod("onMessageReceived", mapOf(
                                    "message" to message,
                                    "senderAddress" to senderAddress,
                                    "senderPort" to senderPort
                                ))
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("UDP", "Error receiving packet: ${e.message}")
                    }
                }
            } catch (e: Exception) {
                Log.e("UDP", "Error starting UDP server: ${e.message}")
            }
        }
    }

    private fun stopUDPServer() {
        isListening = false
        udpSocket?.close()
        udpSocket = null
    }

    override fun onDestroy() {
        stopUDPServer()
        scope.cancel()
        super.onDestroy()
    }
}
