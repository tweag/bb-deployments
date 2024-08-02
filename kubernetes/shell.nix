{ nixpkgs ? builtins.getFlake "nixpkgs"
, system ? builtins.currentSystem
, pkgs ? nixpkgs.legacyPackages.${system}
}:
pkgs.mkShell {
  packages = with pkgs; [
    kubectl
    lima-bin
    grpc-client-cli
    bazelisk
    kubernetes-helm
    cmctl
    openssl
    jq
  ];

  env = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    BAZEL_LINKOPTS = with pkgs.darwin.apple_sdk;
      "-F${frameworks.Foundation}/Library/Frameworks:-L${objc4}/lib";
    BAZEL_CXXOPTS = "-I${pkgs.libcxx.dev}/include/c++/v1";
  };

  passthru.fhs = (pkgs.buildFHSUserEnv {
    name = "bazel-userenv";
    runScript = "zsh";  # replace with your shell of choice
    targetPkgs = pkgs: with pkgs; [
      libz  # required for bazelisk to unpack Bazel itself
    ];
  }).env;
}
