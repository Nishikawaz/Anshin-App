part of '../../main.dart';

class VoiceCaptureIndicator extends StatefulWidget {
  const VoiceCaptureIndicator({
    super.key,
    required this.isStarting,
    required this.isListening,
    required this.transcript,
    required this.onStop,
  });

  final bool isStarting;
  final bool isListening;
  final String transcript;
  final VoidCallback onStop;

  @override
  State<VoiceCaptureIndicator> createState() => _VoiceCaptureIndicatorState();
}

class _VoiceCaptureIndicatorState extends State<VoiceCaptureIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _isActive => widget.isStarting || widget.isListening;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant VoiceCaptureIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      return;
    }
    if (!_isActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive && widget.transcript.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final hasTranscript = widget.transcript.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isListening
            ? scheme.errorContainer.withValues(alpha: 0.35)
            : scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isListening ? scheme.error : scheme.primary,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _isActive
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation<double>(1),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isActive)
                        CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: widget.isListening
                              ? scheme.error
                              : scheme.primary,
                        ),
                      Icon(
                        _isActive
                            ? Icons.mic_rounded
                            : Icons.check_circle_rounded,
                        color: widget.isListening
                            ? scheme.error
                            : scheme.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isStarting
                      ? 'Iniciando micrófono...'
                      : (widget.isListening
                            ? 'Grabando gasto por voz...'
                            : 'Voz detectada'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isActive)
                TextButton.icon(
                  onPressed: widget.onStop,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Detener'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasTranscript
                ? '“${widget.transcript.trim()}”'
                : 'Habla ahora, por ejemplo: gaste 45.000 en supermercado.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_isActive) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}
