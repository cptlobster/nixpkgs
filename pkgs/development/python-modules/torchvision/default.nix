{
  lib,
  torch,
  buildPythonPackage,
  fetchFromGitHub,

  # nativeBuildInputs
  libpng,
  ninja,
  which,

  # buildInputs
  libjpeg_turbo,

  # dependencies
  numpy,
  pillow,
  scipy,

  # tests
  pytest,
  writableTmpDirAsHomeHook,
}:

let
  inherit (torch) cudaCapabilities cudaPackages cudaSupport rocmPackages rocmSupport rocmtoolkit_joined gpuTargetString;

in
buildPythonPackage.override { inherit (torch) stdenv; } (finalAttrs: {
  pname = "torchvision";
  version = "0.26.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytorch";
    repo = "vision";
    tag = "v${finalAttrs.version}";
    hash = "sha256-FOdDGY3v8yWBhtNo9tZP79/xwrc7AoIY5Y1ZABzWe6g=";
  };

  nativeBuildInputs = [
    libpng
    ninja
    which
  ]
  ++ lib.optionals cudaSupport [ cudaPackages.cuda_nvcc ]
  ++ lib.optionals rocmSupport [
    rocmtoolkit_joined
    rocmPackages.clr # Added separately so setup hook applies
  ];

  buildInputs = [
    libjpeg_turbo
    libpng
    torch.cxxdev
  ];

  dependencies = [
    numpy
    pillow
    torch
    scipy
  ];

  env = {
    TORCHVISION_INCLUDE = "${libjpeg_turbo.dev}/include/";
    TORCHVISION_LIBRARY = "${libjpeg_turbo}/lib/";
  }
  // lib.optionalAttrs cudaSupport {
    TORCH_CUDA_ARCH_LIST = "${lib.concatStringsSep ";" cudaCapabilities}";
    FORCE_CUDA = 1;
  }
  // lib.optionalAttrs rocmSupport {
    ROCM_PATH = "${rocmtoolkit_joined}";
    ROCM_SOURCE_DIR = "${rocmtoolkit_joined}";
    PYTORCH_ROCM_ARCH = "${gpuTargetString}";
  }

  # tests download big datasets, models, require internet connection, etc.
  doCheck = false;

  pythonImportsCheck = [ "torchvision" ];

  nativeCheckInputs = [
    pytest
    writableTmpDirAsHomeHook
  ];

  checkPhase = ''
    py.test test --ignore=test/test_datasets_download.py
  '';

  meta = {
    description = "PyTorch vision library";
    homepage = "https://pytorch.org/";
    changelog = "https://github.com/pytorch/vision/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.bsd3;
    platforms = with lib.platforms; linux ++ lib.optionals (!cudaSupport && !rocmSupport) darwin;
    maintainers = with lib.maintainers; [ GaetanLepage ];
  };
})
