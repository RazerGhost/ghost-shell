// Entry point for the login screen: greetd runs `qs -p /etc/greetd/quickshell/greeter.qml`
// (a copy of this folder, see modules/core/greeter.sh). The desktop shell is shell.qml.
import Quickshell
import qs.greeter

ShellRoot {
    Greeter {}
}
