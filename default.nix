let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  flakeCompat = builtins.fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/35bb57c0c8d8b62bbfd284272c928ceb64ddbde9.tar.gz";
    sha256 = "1prd9b1xx8c0sfwnyzkspplh30m613j42l1k789s521f4kv4c2z2";
  };
in
  (import flakeCompat { src = ./.; }).defaultNix
