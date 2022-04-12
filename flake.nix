{
  description = "Testing ILP";

  inputs.nixpkgs.url = "flake:nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        ilp = import ./nix/ilp.nix { inherit pkgs; };
        logger = pkgs.writeShellScript "logger" ''
          export NAME="$(basename "$(dirname "$PWD")")"

          out="$LOGS_DIR/$NAME"

          mkdir -p "$out"

          exec svlogd "$out"
        '';
        create-service = pkgs.writeShellApplication {
          name = "create-service";
          text = ''
            if [ "$#" -ne 1 ]; then
              echo "Usage 'create-service [name]'" >&2
              exit 1
            fi

            name="$1"
            shift 1

            dir="$SVDIR/$name"

            mkdir -p "$dir"
            [ -e "$dir/run" ] || printf "#!/bin/sh\n\nexec false" > "$dir/run"

            mkdir -p "$dir/log"
            [ -e "$dir/log/run" ] || cp ${logger} "$dir/log/run"

            echo "Created $name"
          '';
        };
        rund = pkgs.writeShellApplication {
          name = "rund";

          runtimeInputs = [ pkgs.runit pkgs.watch pkgs.pstree ];

          text = ''
            runsvdir "$SVDIR" > "$LOGS_DIR/runit.log" &
            RUNIT_PID="$!"

            watch -n1 pstree -p "$RUNIT_PID" -g3 -w

            kill -HUP "$RUNIT_PID"
          '';
        };
        get = pkgs.writeShellApplication {
          name = "get";

          runtimeInputs = [pkgs.jq];

          text = ''
            user_var="$1"
            path="$2"

            echo "''${!user_var}" | jq -r ".$path"
          '';
        };
        ilp-as = pkgs.writeShellApplication {
          name = "ilp-as";

          runtimeInputs = [ ilp.ilp get ];

          text = ''
            name="$1"
            shift 1

            echo "Running as $name (waiting for 1s)" >&2
            sleep 1
            auth="$(get "$name" auth)"
            node="http://$(get "$name" node)"
            export ILP_CLI_API_AUTH="$auth"
            export ILP_CLI_NODE_URL="$node"

            ilp-cli "$@"
          '';
        };
      in {
        packages = {
          inherit ilp;

          inherit (pkgs) redis go-ethereum;
          inherit (pkgs.nodePackages) ganache-cli;

          utils = {
            inherit create-service logger ilp-as;
          };
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.runit
            pkgs.redis
            pkgs.go-ethereum
            pkgs.nodePackages.ganache-cli
            pkgs.jq
            rund
            get
            ilp-as
            ilp.ilp
            ilp.settlement-engines.eth
            ilp.settlement-engines.xrp
            create-service
          ];

          # Environment variables
          RUST_LOG = "interledger=debug";

          # Configuration
          alice = builtins.toJSON {
            auth = "ilp_alice";
            node = "127.0.0.1:7770";
            token = "alice_token";
          };

          bob = builtins.toJSON {
            auth = "ilp_bob";
            node = "127.0.0.1:8770";
            token = "bob_token";
          };

          charlie = builtins.toJSON {
            auth = "ilp_charlie";
            node = "127.0.0.1:9770";
            token = "charlie_token";
          };
        };
      }
    );
}
