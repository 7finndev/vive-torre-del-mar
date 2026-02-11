import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- IMPORTANTE
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';

class ScanQrScreen extends StatefulWidget {
  final EstablishmentModel establishment;

  const ScanQrScreen({super.key, required this.establishment});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with WidgetsBindingObserver {
  late MobileScannerController controller;
  bool _isProcessing = false;
  //Estado del flash:
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  // Control del ciclo de vida
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      controller.start();
    } else if (state == AppLifecycleState.inactive) {
      controller.stop();
    }
  }

  // --- 1. LÓGICA DE VALIDACIÓN QR + GPS ---
  Future<void> _validateQr(String scannedCode) async {
    // A. Validar Código
    final validCode = widget.establishment.qrUuid ?? widget.establishment.id.toString();
    
    if (scannedCode != validCode) {
      _showErrorAndRestart(
        "Código Incorrecto ❌",
        "Este QR no pertenece a ${widget.establishment.name}.",
      );
      return;
    }

    // B. Validar GPS
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

        debugPrint("Distancia GPS: $distanceInMeters m");

        // Margen de 300 metros
        if (distanceInMeters > 300) {
          _showErrorAndRestart(
            "Demasiado lejos 🏃‍♂️",
            "Estás a ${distanceInMeters.toInt()}m del local.\nAcércate más.",
          );
          return;
        }
      }

      // C. ¡ÉXITO!
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      _showErrorAndRestart("Error GPS", "No pudimos validarte: $e");
    }
  }

  void _showErrorAndRestart(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              controller.start(); // Reactivar cámara
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --- 2. LÓGICA DE PIN MANUAL (CONECTADA A SUPABASE) ---
  void _showManualCodeDialog() {
    // 1. Pausamos cámara para ahorrar recursos
    controller.stop();

    final TextEditingController pinController = TextEditingController();
    bool loading = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false, // Obligamos a usar botones
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key, color: Colors.orange),
              SizedBox(width: 10),
              Text("Modo Manual"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Introduce el PIN del camarero:", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "••••",
                  counterText: "",
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (_) {
                   if (errorText != null) setDialogState(() => errorText = null);
                },
              ),
              const SizedBox(height: 10),
              if (loading) const LinearProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                controller.start(); // 🔥 REANUDAR CÁMARA AL CANCELAR
              },
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                final inputPin = pinController.text.trim();
                if (inputPin.length < 4) {
                   setDialogState(() => errorText = "Faltan dígitos");
                   return;
                }

                setDialogState(() => loading = true);

                try {
                  // --- CONSULTA A SUPABASE ---
                  final response = await Supabase.instance.client
                      .from('establishments')
                      .select('waiter_pin')
                      .eq('id', widget.establishment.id)
                      .single();

                  final String? realPin = response['waiter_pin'];

                  if (realPin != null && realPin == inputPin) {
                    // ✅ PIN CORRECTO
                    if (context.mounted) Navigator.pop(ctx); // Cierra diálogo
                    if (mounted) context.pop(true); // Cierra pantalla devolviendo TRUE (Voto válido)
                  } else {
                    // ❌ PIN INCORRECTO
                    setDialogState(() {
                      loading = false;
                      errorText = "PIN Incorrecto";
                      pinController.clear();
                    });
                  }
                } catch (e) {
                  setDialogState(() {
                    loading = false;
                    errorText = "Error de conexión";
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
              child: const Text("VALIDAR"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final double scanWindowSize = isDesktop ? 400 : 250;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Enfoca el QR", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.white,
            ),
            tooltip: "Alternar Flash",
            //onPressed: () => controller.toggleTorch(),
            onPressed: () async {
              try {
                await controller.toggleTorch();
                setState(() => _isFlashOn = !_isFlashOn);
              } catch(e){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Flash no disponible en este dispositivo.")),
                );
              }
            },
          ),
          //Boton cambiar camara
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            tooltip: "Cambiar Cámara",
            //onPressed: () => controller.switchCamera(),
            onPressed: () {
              try{
                controller.switchCamera();
              }catch(e){
                debugPrint("Error cambiando cámara: $e");
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: isDesktop ? 800 : double.infinity,
          height: isDesktop ? 600 : double.infinity,
          decoration: isDesktop ? BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
          ) : null,
          
          child: ClipRRect(
            borderRadius: isDesktop ? BorderRadius.circular(20) : BorderRadius.zero,
            child: Stack(
              children: [
                // A. CÁMARA
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (_isProcessing) return;
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        setState(() => _isProcessing = true);
                        controller.stop(); // Paramos para validar
                        _validateQr(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),

                // B. MARCO VISUAL
                CustomPaint(
                  painter: ScannerOverlayPainter(scanWindowSize: scanWindowSize),
                  child: Container(),
                ),

                // C. CARGANDO
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
                  ),

                // D. PARTE INFERIOR: TEXTO Y BOTÓN PIN
                Positioned(
                  bottom: 40,
                  left: 0, 
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: const Text(
                          "Apunta al código QR del establecimiento",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 🔥 BOTÓN PIN ACTUALIZADO (Con llamada a la nueva función)
                      TextButton.icon(
                        onPressed: _showManualCodeDialog, 
                        icon: const Icon(Icons.keyboard, color: Colors.white),
                        label: const Text(
                          "¿Falla el escáner? Introducir Código",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white24,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanWindowSize;
  ScannerOverlayPainter({required this.scanWindowSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scanWindowWidth = scanWindowSize;
    final double scanWindowHeight = scanWindowSize;
    final double left = (size.width - scanWindowWidth) / 2;
    final double top = (size.height - scanWindowHeight) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, scanWindowWidth, scanWindowHeight);

    final Paint backgroundPaint = Paint()..color = Colors.black54;
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect);

    canvas.drawPath(backgroundPath..fillType = PathFillType.evenOdd, backgroundPaint);

    final Paint borderPaint = Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.round;
    final double cornerSize = 30.0;
    final double right = left + scanWindowWidth;
    final double bottom = top + scanWindowHeight;

    canvas.drawPath(Path()..moveTo(left, top + cornerSize)..lineTo(left, top)..lineTo(left + cornerSize, top), borderPaint);
    canvas.drawPath(Path()..moveTo(right - cornerSize, top)..lineTo(right, top)..lineTo(right, top + cornerSize), borderPaint);
    canvas.drawPath(Path()..moveTo(left, bottom - cornerSize)..lineTo(left, bottom)..lineTo(left + cornerSize, bottom), borderPaint);
    canvas.drawPath(Path()..moveTo(right - cornerSize, bottom)..lineTo(right, bottom)..lineTo(right, bottom - cornerSize), borderPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}