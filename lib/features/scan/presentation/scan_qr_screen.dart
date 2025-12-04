import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';

class ScanQrScreen extends ConsumerStatefulWidget {
  final EstablishmentModel establishment;

  const ScanQrScreen({super.key, required this.establishment});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isProcessing = false; 

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enfoca el QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      // Botón de rescate PIN
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("¿Falla el GPS?"),
        icon: const Icon(Icons.lock_open),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        onPressed: _showManualCodeDialog,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // 1. FRENAZO
                  setState(() => _isProcessing = true);
                  controller.stop(); 

                  // 2. Validar
                  _validateQr(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Marco visual
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text("[ Enfoca el QR ]", style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
            ),
        ],
      ),
    );
  }

  Future<void> _validateQr(String scannedCode) async {
    // 1. VALIDAR CÓDIGO
    if (scannedCode != widget.establishment.qrUuid) {
      _showErrorAndRestart("Código Incorrecto ❌", "Este QR no pertenece a ${widget.establishment.name}.");
      return;
    }

    // 2. VALIDAR GPS
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorAndRestart("Permiso denegado", "Necesitamos ubicación para validar.");
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if (widget.establishment.latitude != null && widget.establishment.longitude != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          widget.establishment.latitude!,
          widget.establishment.longitude!,
        );

        print("Distancia: $distanceInMeters");

        if (distanceInMeters > 300) {
          _showErrorAndRestart(
            "Demasiado lejos 🏃‍♂️",
            "Estás a ${distanceInMeters.toInt()}m del local.\nAcércate más.",
          );
          return;
        }
      }

      // 3. ¡ÉXITO! -> DEVOLVEMOS 'TRUE' Y SALIMOS
      if (mounted) {
        context.pop(true); // <--- ESTA ES LA CLAVE. VOLVEMOS AL DETALLE.
      }

    } catch (e) {
      _showErrorAndRestart("Error GPS", "No pudimos validarte: $e");
    }
  }

  void _showErrorAndRestart(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              controller.start();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showManualCodeDialog() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Código Manual"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "PIN Camarero"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (pinController.text == "0000") {
                // Si el PIN es bueno, cerramos y devolvemos TRUE
                controller.stop();
                context.pop(true); 
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Incorrecto")));
              }
            },
            child: const Text("Validar"),
          ),
        ],
      ),
    );
  }
}