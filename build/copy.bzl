def copy_cmd(ctx, src, dst):
    # Most Windows binaries built with MSVC use a certain argument quoting
    # scheme. Bazel uses that scheme too to quote arguments. However,
    # cmd.exe uses different semantics, so Bazel's quoting is wrong here.
    # To fix that we write the command to a .bat file so no command line
    # quoting or escaping is required.
    bat = ctx.actions.declare_file("copy%s-cmd.bat" % hash(src.path))
    ctx.actions.write(
        output = bat,
        # Do not use lib/shell.bzl's shell.quote() method, because that uses
        # Bash quoting syntax, which is different from cmd.exe's syntax.
        content = "@copy /Y \"%s\" \"%s\" >NUL" % (
            src.path.replace("/", "\\"),
            dst.path.replace("/", "\\"),
        ),
        is_executable = True,
    )
    ctx.actions.run(
        inputs = [src],
        tools = [bat],
        outputs = [dst],
        executable = "cmd.exe",
        arguments = ["/C", bat.path.replace("/", "\\")],
        mnemonic = "CopyFile",
        progress_message = "Copying file %s" % src.short_path,
        use_default_shell_env = True,
    )

def copy_bash(ctx, src, dst):
    ctx.actions.run_shell(
        inputs = [src],
        outputs = [dst],
        command = "cp -f \"$1\" \"$2\"",
        arguments = [src.path, dst.path],
        mnemonic = "CopyFile",
        progress_message = "Copying file %s" % src.short_path,
        use_default_shell_env = True,
    )


def copy(ctx, src, dst):
    is_windows = select({
        "@bazel_tools//src/conditions:host_windows": True,
        "//conditions:default": False,
    })
    if is_windows:
        copy_cmd(ctx, src, dst)
    else:
        copy_bash(ctx, src, dst)
