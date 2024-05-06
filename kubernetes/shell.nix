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

  passthru.fhs = (pkgs.buildFHSUserEnv {
    name = "bazel-userenv";
    runScript = "zsh";  # replace with your shell of choice
    targetPkgs = pkgs: with pkgs; [
      libz  # required for bazelisk to unpack Bazel itself
    ];
  }).env;
}
