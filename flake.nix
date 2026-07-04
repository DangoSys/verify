{
  description = "Buckyball verification environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/64c08a7ca051951c8eae34e3e3cb1e202fe36786";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPkgs = system: import nixpkgs { inherit system; };
      uvm12 = builtins.fetchTarball {
        url = "https://www.accellera.org/images/downloads/standards/uvm/uvm-1.2.tar.gz";
        sha256 = "sha256-rvsxPd2FtTDPx9IzA6+4DybrPx+3p7ZC0FX4brsWoaI=";
      };
    in
    {
      devShells = forAllSystems (system:
      let
        pkgs = mkPkgs system;
        cc = pkgs.gcc13;
      in
      {
        default = (pkgs.mkShell.override { stdenv = pkgs.gcc13Stdenv; }) {
          packages = [
            pkgs.cargo
            pkgs.rustc
            pkgs.rustfmt
            pkgs.clippy
            cc
            pkgs.gnumake
          ];

          UVM_HOME = "${uvm12}";
          UVM_VERSION = "1.2";
          VCS_UVM_ARGS = "+incdir+${uvm12}/src ${uvm12}/src/uvm.sv ${uvm12}/src/dpi/uvm_dpi.cc -CFLAGS -DVCS";

          shellHook = ''
            export VCS_ARCH_OVERRIDE=linux
            export VCS_CC="$(command -v gcc)"
            export VCS_CPP="$(command -v g++)"
            export VCS_LD="$(command -v g++)"

            echo "================= Buckyball Verification Environment Activated ========================="
            echo "Development environment loaded:"
            echo "UVM_HOME: $UVM_HOME"
            echo "UVM_VERSION: $UVM_VERSION"
            echo "GCC: $(gcc --version 2>&1 | head -1)"
            echo "==========================================================================="
          '';
        };
      });
    };
}
