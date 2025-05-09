# Need to wire this up to use my own built box64 package
{
  lib,
  stdenv,
  fetchFromGitHub,
  gitUpdater,
  cmake,
  python3,
  # TODO: https://github.com/ptitSeb/box64/issues/2484
  withDynarec ? false,
  # withDynarec ? (
  # stdenv.hostPlatform.isAarch64 || stdenv.hostPlatform.isRiscV64 || stdenv.hostPlatform.isLoongArch64
  # ),
  runCommand,
  hello-x86_64,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "box64-bleeding-edge";
  #version = "0.3.4";
  #version = "c40f9651bc51c0f3446484233d6ce63d05ec4b7b";
  version = "35fa13899a09334d598e230917965ae9ae1aa992";
  binaryName = "box64-bleeding-edge";
  doCheck = false;

  src = fetchFromGitHub {
    owner = "ptitSeb";
    repo = "box64";
    #rev = "v${finalAttrs.version}";
    rev = "${finalAttrs.version}";
    hash = "sha256-9j1XNjsW+AQPxsLLYhEX+DJ6eo9EldIjvq8kSBdEeSY=";
  };

  nativeBuildInputs = [
    cmake
    python3
  ];

  cmakeFlags =
    [
      (lib.cmakeBool "NOGIT" true)

      # Arch mega-option
      (lib.cmakeBool "ARM64" stdenv.hostPlatform.isAarch64)
      (lib.cmakeBool "RV64" stdenv.hostPlatform.isRiscV64)
      (lib.cmakeBool "PPC64LE" (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian))
      (lib.cmakeBool "LARCH64" stdenv.hostPlatform.isLoongArch64)
    ]
    ++ lib.optionals stdenv.hostPlatform.isx86_64 [
      # x86_64 has no arch-specific mega-option, manually enable the options that apply to it
      (lib.cmakeBool "LD80BITS" true)
      (lib.cmakeBool "NOALIGN" true)
    ]
    ++ [
      # Arch dynarec
      (lib.cmakeBool "ARM_DYNAREC" (withDynarec && stdenv.hostPlatform.isAarch64))
      (lib.cmakeBool "RV64_DYNAREC" (withDynarec && stdenv.hostPlatform.isRiscV64))
      (lib.cmakeBool "LARCH64_DYNAREC" (withDynarec && stdenv.hostPlatform.isLoongArch64))
    ]
    ++ [
      # Box32 integration
      (lib.cmakeBool "BOX32" true)
      (lib.cmakeBool "BOX32_BINFMT" true)
    ];

  installPhase = ''
    runHook preInstall

    install -Dm 0755 box64 "$out/bin/${finalAttrs.binaryName}"

    runHook postInstall
  '';

  # doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  installCheckPhase = ''
    runHook preInstallCheck

    echo Checking if it works
    $out/bin/${finalAttrs.binaryName} -v 

    echo Checking if Dynarec option was respected
    $out/bin/${finalAttrs.binaryName} -v | grep ${lib.optionalString (!withDynarec) "-v"} Dynarec 

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
    tests.hello =
      runCommand "box64-test-hello" { nativeBuildInputs = [ finalAttrs.finalPackage ]; }
        # There is no actual "Hello, world!" with any of the logging enabled, and with all logging disabled it's hard to
        # tell what problems the emulator has run into.
        ''
          BOX64_NOBANNER=0 BOX64_LOG=1 ${finalAttrs.binaryName} ${lib.getExe hello-x86_64} --version | tee $out
        '';
  };

  meta = {
    homepage = "https://box86.org/";
    description = "Lets you run x86_64 Linux programs on non-x86_64 Linux systems";
    changelog = "https://github.com/ptitSeb/box64/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      gador
      OPNA2608
    ];
    mainProgram = finalAttrs.binaryName;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "riscv64-linux"
      "powerpc64le-linux"
      "loongarch64-linux"
      "mips64el-linux"
    ];
  };
})
