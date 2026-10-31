# Toolchain Android para buildar o app mobile (Tauri v2) no NixOS.
#
# - JDK 17: exigido pelo Gradle do Tauri.
# - Android SDK via `androidenv`: plataformas + build-tools + platform-tools,
#   tudo declarativo no store do Nix (sem Android Studio).
# - NDK 26.1.10909125: a versão que o Tauri v2 espera para cross-compilar o Rust.
# - rustup (instalado em dev.nix) gerencia o toolchain Rust e os targets
#   Android (aarch64/armv7/i686/x86_64-linux-android).
#
# O PATH já inclui ~/.cargo/bin (bash/.bashrc do repo de dotfiles), então o
# cargo/rustc do rustup passam a valer após `rustup default stable`.
#
# iOS NÃO é suportado aqui: build de iOS exige macOS + Xcode. Use o workflow
# "iOS app" no GitHub Actions ou uma máquina Mac (veja docs/MOBILE.md do repo).
{ pkgs, ... }:
let
  # SDK Android composto via androidenv (mesma API do exemplo shell.nix do
  # nixpkgs). O template do Tauri v2.12 gera `compileSdk = 37` no módulo app
  # (plataforma android-37.0) e `compileSdk = 36` na biblioteca tauri-android
  # (plataforma android-36); o AGP usa build-tools 36.0.0. O SDK do Nix é
  # read-only, então esses componentes precisam vir provisionados (o Gradle
  # não pode instalá-los sob demanda).
  android-composition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "36" "37.0" ];
    buildToolsVersions = [ "36.0.0" ];
    includeNDK = true;
    ndkVersions = [ "26.1.10909125" ];
  };

  androidSdk = android-composition.androidsdk;
  platformTools = android-composition.platform-tools;
  androidHome = "${androidSdk}/libexec/android-sdk";
in
{
  home.packages = [
    pkgs.jdk17
    androidSdk
    platformTools # adb (para `tauri android dev` num aparelho conectado)
  ];

  # Mesmo padrão do dev.nix: env do systemd --user (environment.d), que a
  # sessão gráfica carrega e os terminais herdam. Trocar exige logout/login.
  systemd.user.sessionVariables = {
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
    ANDROID_NDK_HOME = "${androidHome}/ndk/26.1.10909125";
    # O CLI do Tauri procura `NDK_HOME`; `ANDROID_NDK_HOME` é o nome moderno.
    NDK_HOME = "${androidHome}/ndk/26.1.10909125";
    JAVA_HOME = "${pkgs.jdk17.home}";
  };
}
