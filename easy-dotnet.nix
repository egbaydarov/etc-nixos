{
  lib,
  buildDotnetGlobalTool,
  dotnetCorePackages,
}:

buildDotnetGlobalTool {
  pname = "EasyDotnet";
  version = "2.3.30";
  executables = [ "dotnet-easydotnet" ];
  dotnet-sdk = dotnetCorePackages.sdk_9_0;
  dotnet-runtime = dotnetCorePackages.runtime_9_0;

  nugetHash = "sha256-nlc7vKdf91EZGFtn7AIzefsTpLNMXRHPIr0JITPtKkE=";

  meta = {
    description = "Tool for better experience with dotnet in neovim";
    homepage = "https://github.com/GustavEikaas/easy-dotnet.nvim";
    license = lib.licenses.mit;
    mainProgram = "dotnet-easydotnet";
    maintainers = with lib.maintainers; [ semtexerror ];
  };
}
