{
  self,
  lib,
  config,
  argvKernelName ? "",
  codemirrorMode ? "",
  kernelName ? "",
  language ? "",
}: let
  inherit (lib) types;
in {
  argvKernelName = lib.mkOption {
    type = types.str;
    default = argvKernelName;
    internal = true;
    description = ''
      Name of the kernel that gets used in argv.
    '';
  };

  codemirrorMode = lib.mkOption {
    type = types.str;
    default = codemirrorMode;
    internal = true;
    description = ''
      The kernel language to be used with codemirror.
    '';
  };

  language = lib.mkOption {
    type = types.str;
    default = language;
    internal = true;
    description = ''
      The kernel language to be used in the kernelspec.
    '';
  };

  projectDir = lib.mkOption {
    type = types.path;
    default = self + "/modules/kernels/${kernelName}";
    defaultText = lib.literalExpression "self + \"/modules/kernels/${kernelName}\"";
    example = lib.literalExpression "self + \"/kernels/${kernelName}\"";
    description = ''
      Path to the root of the poetry project that provides this ${kernelName}
      kernel.
    '';
  };

  kernelModuleDir = lib.mkOption {
    type = types.path;
    internal = true;
    default = self + "/modules/kernels/${kernelName}";
    defaultText = lib.literalExpression "self + \"/modules/kernels/${kernelName}\"";
    example = lib.literalExpression "self + \"/kernels/${kernelName}\"";
    description = ''
      Path to the root of the kernel module
    '';
  };

  pyproject = lib.mkOption {
    type = types.path;
    default = config.projectDir + "/pyproject.toml";
    defaultText = lib.literalExpression "kernel.${kernelName}.<name>.projectDir + \"/pyproject.toml\"";
    example = lib.literalExpression "self + \"/kernels/${kernelName}/pyproject.toml\"";
    description = ''
      Path to `pyproject.toml` of the poetry project that provides this
      ${kernelName} kernel.
    '';
  };

  poetrylock = lib.mkOption {
    type = types.path;
    default = config.projectDir + "/poetry.lock";
    defaultText = lib.literalExpression "kernel.${kernelName}.<name>.projectDir + \"/poetry.lock\"";
    example = lib.literalExpression "self + \"/kernels/${kernelName}/poetry.lock\"";
    description = ''
      Path to `poetry.lock` of the poetry project that provides this
      ${kernelName} kernel.
    '';
  };

  overrides = lib.mkOption {
    type = with lib.types;
      oneOf [
        (listOf unspecified)
        (types.functionTo (listOf unspecified))
        path
      ];
    default = self + "/modules/kernels/${kernelName}/overrides.nix";
    defaultText = lib.literalExpression "self + \"/modules/kernels/${kernelName}/overrides.nix\"";
    example = lib.literalExpression "self + \"/kernels/${kernelName}/overrides.nix\"";
    description = ''
      Path to `overrides.nix` file which provides python package overrides
      for this ${kernelName} kernel.
    '';
  };

  withDefaultOverrides = lib.mkOption {
    type = types.bool;
    default = true;
    example = lib.literalExpression "false";
    description = ''
      Should we use default overrides provided by `poetry2nix`.
    '';
  };

  python = lib.mkOption {
    type = types.package;
    default = config.nixpkgs.python3;
    example = "python310";
    description = ''
      Name of the python interpreter (from nixpkgs) to be used for this
      ${kernelName} kernel.
    '';
  };

  editablePackageSources = lib.mkOption {
    type = types.attrsOf (types.nullOr types.path);
    default = {};
    example = lib.literalExpression "{}";
    description = ''
      A mapping from package name to source directory, these will be
      installed in editable mode. Note that path dependencies with `develop
      = true` will be installed in editable mode unless explicitly passed
      to `editablePackageSources` as `null`.
    '';
  };

  extraPackages = lib.mkOption {
    type = types.functionTo (types.listOf types.package);
    default = ps: [];
    defaultText = lib.literalExpression "ps: []";
    example = lib.literalExpression "ps: [ps.numpy]";
    description = ''
      A function taking a Python package set and returning a list of extra
      packages to include in the environment. This is intended for
      packages deliberately not added to `pyproject.toml` that you still
      want to include. An example of such a package may be `pip`.
    '';
  };

  preferWheels = lib.mkOption {
    type = types.bool;
    default = false;
    example = lib.literalExpression "true";
    description = ''
      Use wheels rather than sdist as much as possible.
    '';
  };

  groups = lib.mkOption {
    type = types.listOf types.str;
    default = ["dev"];
    defaultText = lib.literalExpression "[\"dev\"]";
    example = lib.literalExpression ''["dev" "doc"]'';
    description = ''
      Which Poetry 1.2.0+ dependency groups to install for this ${kernelName}
      kernel.
    '';
  };

  poetry2nix = lib.mkOption {
    type = types.path;
    default = self.inputs.poetry2nix;
    defaultText = lib.literalExpression "self.inputs.poetry2nix";
    example = lib.literalExpression "self.inputs.poetry2nix";
    description = ''
      poetry2nix flake input to be used for this ${kernelName} kernel.
    '';
  };

  ignoreCollisions = lib.mkOption {
    type = types.bool;
    default = false;
    example = lib.literalExpression "true";
    description = ''
      Ignore file collisions inside the environment.
    '';
  };

  env = lib.mkOption {
    type = types.nullOr types.package;
    default =
      (config.nixpkgs.poetry2nix.mkPoetryEnv {
        inherit
          (config)
          projectDir
          pyproject
          poetrylock
          editablePackageSources
          extraPackages
          preferWheels
          groups
          python
          ;

        overrides =
          if kernelName == "elm" || kernelName == "python"
          then import config.overrides config.nixpkgs
          else if config.withDefaultOverrides == true
          then config.nixpkgs.poetry2nix.overrides.withDefaults (import config.overrides)
          else config.overrides;
      })
      .override (args: {inherit (config) ignoreCollisions;});

    defaultText = lib.literalExpression "pkgs.poetry2nix.mkPoetryEnv or pkgs.python3.buildEnv";
    example = lib.literalExpression "pkgs.poetry2nix.mkPoetryEnv or pkgs.python3.buildEnv";
    description = ''
      The poetry environment for this ${kernelName} kernel.
    '';
  };
}
