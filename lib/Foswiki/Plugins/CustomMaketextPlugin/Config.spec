# ---+ Extensions
# ---++ CustomMaketextPlugin

# **STRING 80x15**
# Custom header for PO-files
$Foswiki::cfg{CustomMaketextPlugin}{Header} = "";

# **STRING**
# Set comma separated groups for execution of reload command.
$Foswiki::cfg{CustomMaketextPlugin}{AllowReload} = "AdminGroup";

# **STRING**
# Command to reload webserver. The CustomMaketextPlugin does not ensure that the command is valid or even executable.
$Foswiki::cfg{CustomMaketextPlugin}{ReloadCommand} = "sudo /usr/sbin/service apache2 reload";
