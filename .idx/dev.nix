# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"

  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.nodePackages.firebase-tools
    pkgs.jdk21
    pkgs.unzip
    pkgs.dart
    pkgs.flutter
    pkgs.nodejs_20
    pkgs.curl
    pkgs.zip
    pkgs.poppler_utils
  ];

  # Sets environment variables in the workspace
  env = {};

  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.dart-code"
      "Dart-Code.flutter"
    ];

previews = {
      enable = true;
      previews = {
        web = {
          command = [
            "bash"
            "-c"
            "cd mobile && flutter run --machine -d web-server --web-hostname 0.0.0.0 --web-port $PORT"
          ];
          manager = "web";
        };
        android = {
          command = [
            "bash"
            "-c"
            "cd mobile && flutter run --machine -d android"
          ];
          manager = "android"; # これにより、IDXが自動でエミュレータを準備します
        };
      };
    };

    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
onCreate = {
    };
      # Runs when the workspace is (re)started
      onStart = {
        # Example: start a continuous build process
        # build-flutter = "flutter build web";
      };
    };
  };
}