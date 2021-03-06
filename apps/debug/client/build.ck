/*++

Copyright (c) 2012 Minoca Corp.

    This file is licensed under the terms of the GNU General Public License
    version 3. Alternative licensing terms are available. Contact
    info@minocacorp.com for details. See the LICENSE file at the root of this
    project for complete licensing information.

Module Name:

    Debug Client

Abstract:

    This module builds the debug client, which debugs and profiles firmware,
    the kernel, and user mode applications.

Author:

    Evan Green 26-Jul-2012

Environment:

    User

--*/

from menv import application, mconfig;

function build() {
    var arch = mconfig.arch;
    var archSources;
    var armSources;
    var buildApp;
    var buildArch = mconfig.build_arch;
    var buildArchSources;
    var buildConfig;
    var buildGuiApp;
    var buildGuiConfig;
    var buildGuiSources;
    var buildOs = mconfig.build_os;
    var buildLibs;
    var buildSources;
    var commonSources;
    var entries;
    var includes;
    var minocaSources;
    var targetApp;
    var targetDynlibs;
    var targetLibs;
    var targetSources;
    var win32CmdSources;
    var win32CommonSources;
    var win32GuiSources;
    var win32Sources;
    var x86Sources;

    commonSources = [
        "armdis.c",
        "cmdtab.c",
        "coff.c",
        "consio.c",
        "dbgapi.c",
        "dbgdwarf.c",
        "dbgeval.c",
        "dbgrcomm.c",
        "dbgrprof.c",
        "dbgsym.c",
        "debug.c",
        "disasm.c",
        "dwarf.c",
        "dwexpr.c",
        "dwframe.c",
        "dwline.c",
        "dwread.c",
        "elf.c",
        "exts.c",
        "profthrd.c",
        "remsrv.c",
        "stabs.c",
        "symbols.c",
        "thmdis.c",
        "thm32dis.c",
        "x86dis.c"
    ];

    x86Sources = [
        "x86/dbgarch.c"
    ];

    armSources = [
        "armv7/dbgarch.c"
    ];

    minocaSources = [
        "minoca/cmdln.c",
        "minoca/extsup.c",
        "minoca/sock.c"
    ];

    win32Sources = [
        "win32/ntcomm.c",
        "win32/ntextsup.c",
        "win32/ntsock.c",
        "win32/ntusrdbg.c",
        "win32/ntusrsup.c"
    ];

    win32CmdSources = [
        "win32/cmdln/ntcmdln.c",
    ];

    win32GuiSources = [
        "win32/ui/debugres.rc",
        "win32/ui/ntdbgui.c"
    ];

    targetLibs = [
        "lib/im:im"
    ];

    buildLibs = [
        "lib/im:build_im",
        "lib/rtl/base:build_basertl",
        "lib/rtl/rtlc:build_rtlc"
    ];

    targetDynlibs = [
        "apps/osbase:libminocaos"
    ];

    includes = [
        "$S/lib/im",
        "$S/apps/debug/client",
    ];

    if (arch == "x86") {
        archSources = x86Sources;

    } else if ((arch == "armv7") || (arch == "armv6")) {
        archSources = armSources;

    } else {
        Core.raise(ValueError("Unknown architecture"));
    }

    targetSources = commonSources + minocaSources + targetLibs +
                     targetDynlibs + archSources;

    if ((buildArch == "x86") || (buildArch == "x64")) {
        buildArchSources = x86Sources;

    } else if ((buildArch == "armv7") || (buildArch == "armv6")) {
        buildArchSources = armSources;

    } else {
        Core.raise(ValueError("Unknown architecture"));
    }

    buildConfig = {};
    buildGuiConfig = {};
    if (buildOs == "Windows") {
        win32CommonSources = commonSources + buildArchSources +
                               win32Sources;

        buildSources = win32CommonSources + win32CmdSources;
        buildGuiSources = win32CommonSources + win32GuiSources;
        buildConfig["DYNLIBS"] = [
            "-lpsapi",
            "-lws2_32",
            "-lmswsock",
            "-ladvapi32"
        ];

        buildGuiConfig["DYNLIBS"] = buildConfig["DYNLIBS"] + ["-lshlwapi"];
        buildGuiConfig["LDFLAGS"] = ["-mwindows"];

    } else if (buildOs == "Minoca") {
        buildSources = commonSources + minocaSources + targetLibs;
        buildConfig["DYNLIBS"] = ["-lminocaos"];

    } else {
        buildSources = null;
    }

    targetApp = {
        "label": "debug",
        "inputs": targetSources,
        "includes": includes
    };

    entries = application(targetApp);
    if (buildSources) {
        buildApp = {
            "label": "build_debug",
            "output": "debug",
            "inputs": buildSources + buildLibs,
            "includes": includes,
            "config": buildConfig,
            "build": true,
            "prefix": "build",
            "binplace": "tools/bin"
        };

        entries += application(buildApp);
    }

    //
    // Build the Windows GUI application if applicable.
    //

    if (buildOs == "Windows") {
        buildGuiApp = {
            "label": "build_debugui",
            "output": "debugui",
            "inputs": buildGuiSources + buildLibs,
            "includes": includes,
            "config": buildGuiConfig,
            "build": true,
            "prefix": "buildui",
            "binplace": "tools/bin"
        };

        entries += application(buildGuiApp);
    }

    return entries;
}

