# ---+ Extensions
# ---++ CustomMaketextPlugin

# **STRING 80x15**
# Default header for PO-files
$Foswiki::cfg{CustomMaketextPlugin}{Header} = "";

# **SELECT no-one,admin,everyone**
# Set permissions for execution of reload command: </ br>
# no-one: Do not allow execution. </ br>
# admin: Do allow server reload for wiki admin only. </ br>
# everyone: Do allow server reload for everyone.
$Foswiki::cfg{CustomMaketextPlugin}{AllowReload} = "no-one";

# **STRING**
# Command to reload webserver. The CustomMaketextPlugin does not ensure that the command is valid or even executable.
$Foswiki::cfg{CustomMaketextPlugin}{ReloadCommand} = "sudo service apache2 reload";
