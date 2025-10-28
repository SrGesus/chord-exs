{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  name = "elixir-dev-env";

  buildInputs = with pkgs; [
    beam27Packages.elixir
    elixir-ls

    # VSCode
    (vscode-with-extensions.override {
      # When the extension is already available in the default extensions set.
      vscodeExtensions = with vscode-extensions; [
        jnoortheen.nix-ide
        elixir-lsp.vscode-elixir-ls
      ];
    })
  ];

  shellHook = ''
    echo "Elixir dev environment ready!

    Elixir:
    $(elixir --version)
    "
  '';
}
