{
  outputs = {...}: with builtins; let
    secrets-list = let secret = import ./secrets.nix; in map (file-name: let 
      name = filter isString (split "/" (
        let m = match "^(.*)\.age$" file-name; in 
          if m == null then file-name else elemAt m 0
      ));
    in { 
      inherit name;
      inherit (secret.${file-name}) publicKeys; 
      file = ./. + ("/" + file-name);
    }) (attrNames secret);
    unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [];
    makeSecretsSet = depth: secrets-list: if secrets-list == [] then {} else
    let
      items = groupBy (s: elemAt s.name depth) secrets-list;
    in mapAttrs (_: item:
      if length item == 1
      then let value = elemAt item 0; in {
        inherit (value) file; name = concatStringsSep "/" value.name; 
      }
      else makeSecretsSet (depth + 1) item) items;
    secrets-set = (makeSecretsSet 0 secrets-list);
  in {
    define-secrets = attrs: listToAttrs (map (name: {
      inherit name;
      value = { publicKeys = unique attrs.${name}; };
    }) (attrNames attrs));
    secrets = secrets-set;
  };
}
