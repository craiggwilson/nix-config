{
  substrate.publish.packages.fastmail-create-tasks =
    { lib, pkgs, ... }:
    let
      python = pkgs.python3.withPackages (ps: [ ps.caldav ]);
      script = pkgs.writeText "fastmail-create-tasks.py" ''
        import argparse
        import getpass
        import sys
        from urllib.parse import quote

        import caldav

        parser = argparse.ArgumentParser(
            description="Create a VTODO task collection in Fastmail."
        )
        parser.add_argument("--username", help="Fastmail email address")
        parser.add_argument(
            "--password",
            help=(
                "Fastmail app password (less secure than prompting: visible in "
                "shell history/process listings)"
            ),
        )
        parser.add_argument("--name", help="Task-list name")
        args = parser.parse_args()

        username = (args.username or input("Fastmail email: ")).strip()
        if not username:
            print("Fastmail email is required.", file=sys.stderr)
            raise SystemExit(2)

        password = args.password or getpass.getpass("Fastmail app password: ")
        if not password:
            print("Fastmail app password is required.", file=sys.stderr)
            raise SystemExit(2)

        task_list_name = (
            args.name or input("Task-list name [Tasks]: ").strip() or "Tasks"
        )

        try:
            client = caldav.DAVClient(
                # The generic Fastmail endpoint works for some CalDAV clients,
                # but python-caldav needs the account's calendar-home URL.
                url=(
                    "https://caldav.fastmail.com/dav/calendars/user/"
                    + quote(username, safe="@")
                    + "/"
                ),
                username=username,
                password=password,
            )
            principal = client.principal()

            for calendar in principal.calendars():
                if calendar.name != task_list_name:
                    continue
                components = calendar.get_supported_components()
                if "VTODO" in components:
                    print(f"A VTODO collection named {task_list_name} already exists:")
                    print(calendar.url)
                    raise SystemExit(0)
                print(
                    f"Fastmail already has a calendar named {task_list_name}, but it does not "
                    "advertise VTODO support. Choose another name or remove it first.",
                    file=sys.stderr,
                )
                raise SystemExit(1)

            task_list = principal.make_calendar(
                name=task_list_name,
                supported_calendar_component_set=["VTODO"],
            )
            print("Created Fastmail VTODO collection:")
            print(task_list.url)
        except SystemExit:
            raise
        except Exception as error:
            print(f"Unable to create Fastmail task list: {error}", file=sys.stderr)
            raise SystemExit(1)
      '';
    in
    pkgs.writeShellApplication {
      name = "fastmail-create-tasks";
      text = ''
        exec ${python}/bin/python3 ${script} "$@"
      '';
      meta = {
        description = "Create a VTODO task collection named Tasks in Fastmail";
        mainProgram = "fastmail-create-tasks";
        platforms = lib.platforms.linux;
      };
    };
}
