class EmulatableService {
  bool useEmulator;
  String emulatorHostnameOrIpAddress;
  int emulatorPort;

  EmulatableService({
    this.useEmulator = false,
    required this.emulatorHostnameOrIpAddress,
    required this.emulatorPort
  });
}