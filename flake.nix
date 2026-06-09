{
  description = "Nix package for the graphify command line tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      python = pkgs.python312;
      py = python.pkgs;

      pythonModuleName = pname: builtins.replaceStrings [ "-" ] [ "_" ] pname;

      buildTreeSitterWheel =
        { pname, version, url, hash }:
        py.buildPythonPackage {
          inherit pname version;
          format = "wheel";
          src = pkgs.fetchurl { inherit url hash; };
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib ];
          doCheck = false;
          pythonImportsCheck = [ (pythonModuleName pname) ];
        };

      datasketch = py.buildPythonPackage rec {
        pname = "datasketch";
        version = "1.10.0";
        pyproject = true;
        src = pkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-0jrqgM5MQHkMp6QHlWWYSL6S7MQ9uAlCvibyHoHSRxQ=";
        };
        build-system = [
          py.hatchling
        ];
        dependencies = with py; [
          numpy
          scipy
        ];
        doCheck = false;
        pythonImportsCheck = [ "datasketch" ];
      };

      treeSitterGrammarSpecs = [
        # The Python grammar sdists are inconsistent across projects, and some
        # omit tree_sitter/parser.h. Use the locked ABI3 Linux wheels so the CLI
        # installs without pip/uv downloads at runtime.
        {
          pname = "tree-sitter-bash";
          version = "0.25.1";
          url = "https://files.pythonhosted.org/packages/d7/22/9f70bc3d3b942ab9fc0f89c1dc9e087519a3a94f64ae6b7377aae3a7a0f0/tree_sitter_bash-0.25.1-cp310-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl";
          hash = "sha256-P0hMS7h5bN56h8o1HmEW8JZT7awOs8bSOFZjWd0osRc=";
        }
        {
          pname = "tree-sitter-c";
          version = "0.24.2";
          url = "https://files.pythonhosted.org/packages/e9/8c/0dfb88d726f8821d1c4c36042f092be974a800afd734307a595b8604190c/tree_sitter_c-0.24.2-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-UEHvZ+tozmvIuwsfjvOlWFzlI9rgx+7BCasGJ911rt4=";
        }
        {
          pname = "tree-sitter-c-sharp";
          version = "0.23.5";
          url = "https://files.pythonhosted.org/packages/41/5a/a8855cbb5bbab28adb29c2c7f0e7be5a9f1d21450c13b3c3e613190d9b8c/tree_sitter_c_sharp-0.23.5-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-qoingCBM0VPEwa4tWcZUzuFAIhL6DQaYI9bTQwFYdDg=";
        }
        {
          pname = "tree-sitter-cpp";
          version = "0.23.4";
          url = "https://files.pythonhosted.org/packages/6a/4d/23e390234d2acd351f5563b1079c515d7c1fe13ddb7392cee543be74dda3/tree_sitter_cpp-0.23.4-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-dz0sr8CLvA+Zhof6M/QvN4waNxzbWChwxNE6uwYJJwY=";
        }
        {
          pname = "tree-sitter-elixir";
          version = "0.3.5";
          url = "https://files.pythonhosted.org/packages/31/35/78c94e164542ad08098b83cb7e046261f3ab2edade96e29727dd209bfa35/tree_sitter_elixir-0.3.5-cp39-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-6/40kaPQCsULEqO/yrscVk84Ce2KCVCZ/of0nWs5h+Y=";
        }
        {
          pname = "tree-sitter-fortran";
          version = "0.6.0";
          url = "https://files.pythonhosted.org/packages/57/86/0923f061e36f229d99660a8f53f8e3b57da459e08512c09e256de820c472/tree_sitter_fortran-0.6.0-cp39-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl";
          hash = "sha256-rEgAtKvBsl5uerSj8uridMWxkQe+sY06RzwPZ1CcdIY=";
        }
        {
          pname = "tree-sitter-go";
          version = "0.25.0";
          url = "https://files.pythonhosted.org/packages/86/fb/b30d63a08044115d8b8bd196c6c2ab4325fb8db5757249a4ef0563966e2e/tree_sitter_go-0.25.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-BLOzy0r/GOdOKNSbcWxvJMtx3f3WZ2iYfibk0PqBL3Q=";
        }
        {
          pname = "tree-sitter-groovy";
          version = "0.1.2";
          url = "https://files.pythonhosted.org/packages/c6/b7/451ac5e158f2418fea7eb0744254dd27238359c070420d69d711aaf06356/tree_sitter_groovy-0.1.2-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-npOOnCzV/bCP0bKNfWIdFeqVmhekvAt3gz4HqU/n0mM=";
        }
        {
          pname = "tree-sitter-java";
          version = "0.23.5";
          url = "https://files.pythonhosted.org/packages/29/09/e0d08f5c212062fd046db35c1015a2621c2631bc8b4aae5740d7adb276ad/tree_sitter_java-0.23.5-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-NwsgS5UAuEf20MWtWEBFgxzuaemj5Nh4U1055KfkxPE=";
        }
        {
          pname = "tree-sitter-javascript";
          version = "0.25.0";
          url = "https://files.pythonhosted.org/packages/5f/c4/7da74ecdcd8a398f88bd003a87c65403b5fe0e958cdd43fbd5fd4a398fcf/tree_sitter_javascript-0.25.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-ncBLqR/IWDNE5XwfHtWyyX7Kr0dIABG5L76rjdqW23U=";
        }
        {
          pname = "tree-sitter-json";
          version = "0.24.8";
          url = "https://files.pythonhosted.org/packages/77/08/10001992526670e0d6f24c571b179f0ece90e5e014a4b98a3ce076884f32/tree_sitter_json-0.24.8-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-hcyneYcvcnjzp06zhTPTS5xN5P1UhhXjNh+mT+NQrQo=";
        }
        {
          pname = "tree-sitter-julia";
          version = "0.23.1";
          url = "https://files.pythonhosted.org/packages/0b/4c/09534d31ab95c3da2284f538bb134bf6fe064770c0bf6fe4fb6f2b028d9e/tree_sitter_julia-0.23.1-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-fU9q6TgZj8C+m26nYxOt4k/NuJvgGnkeDMkMiPrldD0=";
        }
        {
          pname = "tree-sitter-kotlin";
          version = "1.1.0";
          url = "https://files.pythonhosted.org/packages/65/bd/0f3aac45eb88b6b3173ac9c23bc41d8865943cbbe1caaafc001cd1b73c90/tree_sitter_kotlin-1.1.0-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-mpKv4ktjTPkUxYEq8PXFMYSxwYvfbuVQXIOvrIH2v2w=";
        }
        {
          pname = "tree-sitter-lua";
          version = "0.5.0";
          url = "https://files.pythonhosted.org/packages/45/2b/1edfd9bef9a1cc11047cd87ca9c60707b8425080cfc0498a7d3bc762d783/tree_sitter_lua-0.5.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-XsRIyFT+oyQUoESRR9ZIvFut33oDVwCMSr4yads1Nwo=";
        }
        {
          pname = "tree-sitter-objc";
          version = "3.0.2";
          url = "https://files.pythonhosted.org/packages/60/cd/a153a4268b9b405a69ee3e427f19fc570a3c63d4b4d7766bee5a7ba28744/tree_sitter_objc-3.0.2-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-5xKCrJwJapZr8vpqTs2+pL0DfT4B6kqpu8ZNmkwAIvY=";
        }
        {
          pname = "tree-sitter-php";
          version = "0.24.1";
          url = "https://files.pythonhosted.org/packages/9a/c6/fd863a7a779d0ab67688939eba0e08bff7b1ffe731288d3d3610df21217b/tree_sitter_php-0.24.1-cp310-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl";
          hash = "sha256-ehQEow8pckmKzgQLAClzi42sRdChKTLMuLYF65S6++Q=";
        }
        {
          pname = "tree-sitter-powershell";
          version = "0.26.4";
          url = "https://files.pythonhosted.org/packages/de/ff/5bba5fef4b3808ade114512ebf44e0c192050cc825cdcf42fa2043e5abd0/tree_sitter_powershell-0.26.4-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-VlCOSseq0eOyby75a40rYLFJxO+gwjdC6R6AmhHbc+4=";
        }
        {
          pname = "tree-sitter-python";
          version = "0.25.0";
          url = "https://files.pythonhosted.org/packages/aa/cb/d9b0b67d037922d60cbe0359e0c86457c2da721bc714381a63e2c8e35eba/tree_sitter_python-0.25.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-hvEY5e7K1hbs24HRcaNt3pvvWgsh7XHqnD45CBPDuvU=";
        }
        {
          pname = "tree-sitter-ruby";
          version = "0.23.1";
          url = "https://files.pythonhosted.org/packages/23/dd/1171b5dd25da10f768732a20fb62d2e3ae66e3b42329351f2ce5bf723abb/tree_sitter_ruby-0.23.1-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-97zZOXK0yigDhW1P4PvQQSP/KcRZK7ufEqJ1KL0lI0E=";
        }
        {
          pname = "tree-sitter-rust";
          version = "0.24.2";
          url = "https://files.pythonhosted.org/packages/ca/45/a051bbd3045a61182dde25b93ae9a33d2677c935b16952283e12eaf46051/tree_sitter_rust-0.24.2-cp39-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-4DPFqTtXyI4Kg1iA3jn8gCkJ/2n1eq/2AAIRwZbqUZA=";
        }
        {
          pname = "tree-sitter-scala";
          version = "0.26.0";
          url = "https://files.pythonhosted.org/packages/3f/61/e64e1c2b2552f5dc556c9710ecf935ed531efa8a3eb9de9ad4e7c95f6e97/tree_sitter_scala-0.26.0-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-z/F4qTENhZ6Bmm/hDzErbkI9mh0Myl5jVKRf4AQWd74=";
        }
        {
          pname = "tree-sitter-swift";
          version = "0.7.2";
          url = "https://files.pythonhosted.org/packages/c9/74/0af5181a67c71f09af7a9f7942ba8f65e22a4f4d6eed426e6daf6253d3a6/tree_sitter_swift-0.7.2-cp38-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
          hash = "sha256-YABTs+12O+qlFWuh1wsiYC7Yimz/bPOqsjgTOYNCb54=";
        }
        {
          pname = "tree-sitter-typescript";
          version = "0.23.2";
          url = "https://files.pythonhosted.org/packages/49/d1/a71c36da6e2b8a4ed5e2970819b86ef13ba77ac40d9e333cb17df6a2c5db/tree_sitter_typescript-0.23.2-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-6W02uFvKzeuP9cJhjXVZPvEuuvG06s40d+K9squxdSw=";
        }
        {
          pname = "tree-sitter-verilog";
          version = "1.0.3";
          url = "https://files.pythonhosted.org/packages/2a/c1/8782535dbb6ea1f3556eb2bc473f5f131339739278775171fc42b0a57536/tree_sitter_verilog-1.0.3-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-dH3X1LyV+zibw3Il+C0W8MQFSYVumiRL4/+de/5itzA=";
        }
        {
          pname = "tree-sitter-zig";
          version = "1.1.2";
          url = "https://files.pythonhosted.org/packages/78/02/275523eb05108d83e154f52c7255763bac8b588ae14163563e19479322a7/tree_sitter_zig-1.1.2-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-6SRQncrFpgVNo1fj1rzzfqgphO4dKjdlaXU9MvYeqLs=";
        }
      ];

      treeSitterGrammarPackages = map buildTreeSitterWheel treeSitterGrammarSpecs;

      coreDependencies =
          [
            datasketch
          ]
          ++ (with py; [
            networkx
            rapidfuzz
            tree-sitter
          ])
          ++ treeSitterGrammarPackages;

      commonRuntimeDependencies = with py; [
        anthropic
        boto3
        markdownify
        openai
        openpyxl
        pypdf
        psycopg
        tiktoken
        watchdog
        py."python-docx"
      ];

      runtimeTools = [
        pkgs.git
      ];

      mkGraphifyyPackage =
        {
          pname ? "graphifyy",
          extraDependencies ? [ ],
        }:
        py.buildPythonPackage rec {
          inherit pname;
          version = "0.8.35";
          pyproject = true;
          src = ./.;
          build-system = [ py.setuptools ];
          dependencies = coreDependencies ++ extraDependencies;
          doCheck = false;
          pythonImportsCheck = [ "graphify" ];
          meta = {
            description = "Turn a project into a queryable knowledge graph";
            homepage = "https://github.com/safishamsi/graphify";
            license = lib.licenses.mit;
            mainProgram = "graphify";
          };
        };

      mkGraphifyyCli =
        {
          graphifyPackage,
        }:
        let
          graphifyPython = python.withPackages (_: [ graphifyPackage ]);
        in
        pkgs.writeShellApplication {
          name = "graphify";
          runtimeInputs = runtimeTools;
          text = ''
            export PYTHONNOUSERSITE=1
            export GRAPHIFY_COMMAND_WRAPPER="$0"
            export GRAPHIFY_INTERPRETER="${graphifyPython}/bin/python"
            exec "$GRAPHIFY_INTERPRETER" -I -m graphify "$@"
          '';
          meta = {
            description = "Turn a project into a queryable knowledge graph";
            homepage = "https://github.com/safishamsi/graphify";
            license = lib.licenses.mit;
            mainProgram = "graphify";
          };
        };

      graphifyyCorePackage = mkGraphifyyPackage {
        pname = "graphifyy-core";
      };

      graphifyyPackage = mkGraphifyyPackage {
        pname = "graphifyy";
        extraDependencies = commonRuntimeDependencies;
      };

      graphifyyCore = mkGraphifyyCli {
        graphifyPackage = graphifyyCorePackage;
      };

      graphifyy = mkGraphifyyCli {
        graphifyPackage = graphifyyPackage;
      };
    in
    {
      packages.${system} = {
        default = graphifyy;
        graphifyy = graphifyy;
        graphify = graphifyy;
        graphifyy-core = graphifyyCore;
        graphify-core = graphifyyCore;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${lib.getExe graphifyy}";
          meta.description = "Run the graphify CLI";
        };
        graphify = {
          type = "app";
          program = "${lib.getExe graphifyy}";
          meta.description = "Run the graphify CLI";
        };
      };

      checks.${system}.default = graphifyy;
    };
}
