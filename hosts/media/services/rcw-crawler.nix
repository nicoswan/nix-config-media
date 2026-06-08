{ inputs, ... }:
{
  imports = [
    inputs.rcw-crawler.nixosModules.default
  ];

  networking.firewall = {
    allowedTCPPorts = [
      3050
    ];
  };

  services.rcw-crawler = {
    enable = true;
    qdrantUrl = "http://127.0.0.1:6334";
    serverPort = 3050;
    targetChapters = "61.10,61.12,61.16,61.24,61.30,61.34,61.38,61.40,19.86,64.38,64.90,64.34,19.16,6.15";

    # Memory and Threading Optimization
    onnxIntraThreads = 2; # Limit internal CPU threads for ONNX Runtime to reduce memory overhead
    # rerankEnabled = false; # Set to false if you want to completely disable cross-encoder reranking (saves ~1.2GB)
    # rerankModel = "jinaai/jina-reranker-v1-turbo-en"; # Lighter/faster reranker model (~270MB vs BGE's ~1.1GB) default "BAAI/bge-reranker-base"

    # qdrantCollection  = "legal_collection"; # Qdrant collection name.
    # crawlCronSchedule = "0 0 1 * * *"; # Cron expression for crawl scheduling.
    # embeddingStrategy = "fastembed"; # Embedding strategy (fastembed for local CPU, qdrant_cloud for server-side inference).
    # embeddingModel = "sentence-transformers/all-minilm-l6-v2"; # HuggingFace model identifier for embeddings.
    # rerankCandidateLimit = 15; # Candidate limit for reranking.
    # logLevel = "info"; # RUST_LOG environment variable level.

    # If you use sops-nix to manage secrets (QDRANT_API_KEY and OPENAI_API_KEY):
    # environmentFile = null; # Path to environment file containing secrets like QDRANT_API_KEY, OPENAI_API_KEY.
    # environmentFile = config.sops.secrets."services/rcw-crawler/env".path;
  };

  # To define the secret in sops.nix:
  # sops.secrets."services/rcw-crawler/env" = {
  #   restartUnits = [ "rcw-crawler.service" ];
  # };
}
