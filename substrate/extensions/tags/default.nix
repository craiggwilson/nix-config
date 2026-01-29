{ lib, config, ... }:
let
  finderName = "by-tags";
  rawTags = config.substrate.settings.tags;
  slib = config.substrate.lib;

  # Extracts parent prefixes from a hierarchical tag.
  # e.g., "desktop:custom:niri" -> ["desktop", "desktop:custom"]
  parentPrefixes =
    tag:
    let
      parts = lib.splitString ":" tag;
      indices = lib.range 1 (builtins.length parts - 1);
    in
    lib.map (i: lib.concatStringsSep ":" (lib.take i parts)) indices;

  normalizedTags = lib.foldl' (
    acc: item:
    lib.foldl' (
      a: name:
      a
      // {
        ${name} = (a.${name} or [ ]) ++ item.${name};
      }
    ) acc (builtins.attrNames item)
  ) { } rawTags;

  allTagNames = builtins.attrNames normalizedTags;
  allImpliedTags = slib.unique (lib.flatten (builtins.attrValues normalizedTags));
  invalidImpliedTags = lib.filter (t: !(builtins.elem t allTagNames)) allImpliedTags;

  validatedTagNames =
    if invalidImpliedTags == [ ] then
      allTagNames
    else
      throw "Invalid implied tags: ${builtins.toString invalidImpliedTags}. All implied tags must be explicitly declared.";

  # Recursively expands a tag to include all implied tags and parent prefixes.
  # Uses a 'seen' set to prevent infinite loops from circular implications.
  expandTag =
    tag: seen:
    if builtins.elem tag seen then
      [ ]
    else
      let
        newSeen = seen ++ [ tag ];
        explicitImplied = if normalizedTags ? ${tag} then normalizedTags.${tag} else [ ];
        parents = parentPrefixes tag;
        allImplied = slib.unique (explicitImplied ++ parents);
      in
      [ tag ] ++ lib.flatten (lib.map (t: expandTag t newSeen) allImplied);

  expandTags = tags: slib.unique (lib.flatten (lib.map (t: expandTag t [ ]) tags));

  # Tag matching functions:
  # - elemPrefix: checks if any element in xs starts with prefix x
  # - validSingle: a single tag requirement is satisfied if there's a prefix match
  # - validAll: handles both string tags and nested lists (AND logic for lists)
  #   e.g., tags = ["gui"] means "gui" must match
  #   e.g., tags = [["gui" "fonts"]] means BOTH "gui" AND "fonts" must match
  elemPrefix = x: xs: builtins.any (e: lib.strings.hasPrefix x e) xs;
  validSingle = x: xs: elemPrefix x xs;
  validAll =
    x: xs:
    if builtins.isString x then
      validSingle x xs
    else if builtins.isList x then
      builtins.all (e: validAll e xs) x
    else
      false;

  tagsType = lib.types.listOf (lib.types.enum validatedTagNames);

  tagsFromAttrs = attrs: if attrs ? tags then attrs.tags else [ ];

  filterByTags =
    tags: modules:
    lib.filter (m: builtins.deepSeq (tagsFromAttrs m) (validAll (tagsFromAttrs m) tags)) modules;

  computeTags =
    { hostcfg, usercfg, ... }:
    let
      hostTags = if hostcfg != null then hostcfg.tags else [ ];

      userTags =
        if usercfg != null then
          usercfg.tags
        else if hostcfg != null then
          lib.flatten (lib.map (user: config.substrate.users.${user}.tags) hostcfg.users)
        else
          [ ];
    in
    expandTags (slib.unique (hostTags ++ userTags));

  mkHasTag = tags: tag: builtins.any (t: lib.strings.hasPrefix tag t) tags;
in
{
  options.substrate = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            tags = lib.mkOption {
              type = tagsType;
              description = "The tags to apply for the host.";
              default = [ ];
            };
          };
        }
      );
    };
    settings = {
      finder = lib.mkOption {
        type = lib.types.enum [ finderName ];
      };

      tags = lib.mkOption {
        type = lib.types.listOf (
          lib.types.either lib.types.str (lib.types.attrsOf (lib.types.listOf lib.types.str))
        );
        apply =
          list:
          lib.map (
            item: if builtins.isString item then { ${item} = [ ]; } else item
          ) list;
        description = ''
          All the tags available for use. A list where each element can be:
          - A simple string: "tag1" (tag with no implications)
          - A metatag attrset: { "hardware:dell" = [ "laptop" "thunderbolt" ]; }
          When a host/user has a metatag, all implied tags are automatically included.
          After apply, all elements are normalized to attrset format for merging.
        '';
        default = [ ];
      };
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            tags = lib.mkOption {
              type = tagsType;
              description = "The tags to apply for the user.";
              default = [ ];
            };
          };
        }
      );
    };
  };

  config.substrate = {
    finders.${finderName} = {
      find =
        cfgs:
        let
          allTags = slib.unique (lib.flatten (lib.map tagsFromAttrs cfgs));
        in
        # Force evaluation of validatedTagNames to trigger validation errors early
        builtins.seq validatedTagNames (filterByTags (expandTags allTags) (config.substrate.finders.all.find cfgs));
    };

    settings = {
      extraModuleOptions.tags = lib.mkOption {
        type = tagsType;
        description = "The tags required to enable this module.";
        default = [ ];
      };

      finder = finderName;

      extraArgsGenerators = [
        (
          args@{ ... }:
          {
            hasTag = mkHasTag (computeTags args);
          }
        )
      ];

      checks =
        let
          allModules = config.substrate.finders.all.find [ ];

          validateModuleTags =
            let
              modulesWithInvalidTags = lib.filter (
                m:
                let
                  moduleTags = m.tags or [ ];
                  invalidTags = lib.filter (t: !(lib.elem t validatedTagNames)) moduleTags;
                in
                invalidTags != [ ]
              ) allModules;
            in
            {
              name = "module-tags";
              valid = modulesWithInvalidTags == [ ];
              message =
                if modulesWithInvalidTags == [ ] then
                  "All module tags are valid"
                else
                  let
                    details = lib.concatMapStringsSep "\n" (
                      m: "  - Module with invalid tags: ${toString (m.tags or [ ])}"
                    ) modulesWithInvalidTags;
                  in
                  "Found modules with invalid tags:\n${details}";
            };

          validateHostTags =
            let
              hostsWithInvalidTags = lib.filterAttrs (
                name: host:
                let
                  hostTags = host.tags or [ ];
                  invalidTags = lib.filter (t: !(lib.elem t validatedTagNames)) hostTags;
                in
                invalidTags != [ ]
              ) config.substrate.hosts;
            in
            {
              name = "host-tags";
              valid = hostsWithInvalidTags == { };
              message =
                if hostsWithInvalidTags == { } then
                  "All host tags are valid"
                else
                  let
                    details = lib.concatStringsSep "\n" (
                      lib.mapAttrsToList (
                        name: host:
                        let
                          invalidTags = lib.filter (t: !(lib.elem t validatedTagNames)) (host.tags or [ ]);
                        in
                        "  - Host '${name}': invalid tags ${toString invalidTags}"
                      ) hostsWithInvalidTags
                    );
                  in
                  "Found hosts with invalid tags:\n${details}";
            };

          validateUserTags =
            let
              usersWithInvalidTags = lib.filterAttrs (
                name: user:
                let
                  userTags = user.tags or [ ];
                  invalidTags = lib.filter (t: !(lib.elem t validatedTagNames)) userTags;
                in
                invalidTags != [ ]
              ) config.substrate.users;
            in
            {
              name = "user-tags";
              valid = usersWithInvalidTags == { };
              message =
                if usersWithInvalidTags == { } then
                  "All user tags are valid"
                else
                  let
                    details = lib.concatStringsSep "\n" (
                      lib.mapAttrsToList (
                        name: user:
                        let
                          invalidTags = lib.filter (t: !(lib.elem t validatedTagNames)) (user.tags or [ ]);
                        in
                        "  - User '${name}': invalid tags ${toString invalidTags}"
                      ) usersWithInvalidTags
                    );
                  in
                  "Found users with invalid tags:\n${details}";
            };

          validateImpliedTags =
            let
              allImplied = slib.unique (lib.flatten (builtins.attrValues normalizedTags));
              invalidImplied = lib.filter (t: !(lib.elem t validatedTagNames)) allImplied;
            in
            {
              name = "implied-tags";
              valid = invalidImplied == [ ];
              message =
                if invalidImplied == [ ] then
                  "All implied tags are valid"
                else
                  "Found invalid implied tags: ${toString invalidImplied}";
            };

          # Detect circular tag implications (e.g., A implies B, B implies A)
          validateCircularTags =
            let
              # Check if following implications from a tag leads back to itself
              hasCircularPath =
                startTag: currentTag: visited:
                let
                  implied = normalizedTags.${currentTag} or [ ];
                  isCircular = lib.elem startTag implied;
                  newVisited = visited ++ [ currentTag ];
                  # Only follow tags we haven't visited to avoid infinite recursion
                  unvisitedImplied = lib.filter (t: !(lib.elem t newVisited)) implied;
                in
                isCircular || builtins.any (t: hasCircularPath startTag t newVisited) unvisitedImplied;

              tagsWithCircular = lib.filter (tag: hasCircularPath tag tag [ ]) (builtins.attrNames normalizedTags);
            in
            {
              name = "circular-tag-implications";
              valid = tagsWithCircular == [ ];
              warn = true; # Warning rather than error since expandTag handles cycles
              message =
                if tagsWithCircular == [ ] then
                  "No circular tag implications detected"
                else
                  "Found tags with circular implications: ${toString tagsWithCircular}. While handled safely, this may indicate a configuration error.";
            };

          validateUnusedTags =
            let
              # Reuse the top-level parentPrefixes function
              expandWithPrefixes = tags: slib.unique (tags ++ lib.flatten (lib.map parentPrefixes tags));

              moduleTagsUsed = expandWithPrefixes (lib.flatten (lib.map (m: m.tags or [ ]) allModules));

              hostTagsUsed = expandWithPrefixes (
                lib.flatten (lib.mapAttrsToList (_: h: h.tags or [ ]) config.substrate.hosts)
              );

              userTagsUsed = expandWithPrefixes (
                lib.flatten (lib.mapAttrsToList (_: u: u.tags or [ ]) config.substrate.users)
              );

              impliedTagsUsed = lib.flatten (builtins.attrValues normalizedTags);

              allReferencedTags = slib.unique (moduleTagsUsed ++ hostTagsUsed ++ userTagsUsed ++ impliedTagsUsed);

              unusedTags = lib.filter (t: !(lib.elem t allReferencedTags)) validatedTagNames;
            in
            {
              name = "unused-tags";
              valid = unusedTags == [ ];
              warn = true; # This is a warning, not an error
              message =
                if unusedTags == [ ] then
                  "All declared tags are referenced"
                else
                  "Found unreferenced tags: ${toString unusedTags}";
            };
        in
        [
          validateModuleTags
          validateHostTags
          validateUserTags
          validateImpliedTags
          validateCircularTags
          validateUnusedTags
        ];
    };
  };
}
