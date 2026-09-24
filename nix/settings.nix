# Personal settings. A fork edits this file.
{
  # Account name on every machine, and the macOS account's uid, which
  # nix-darwin needs before it manages the login shell.
  user = "kk";
  uid = 501;

  # This repo's checkout, relative to $HOME. Files under home/ link into
  # it, so an edit applies without a rebuild.
  dotfiles = "dotfiles";

  # Git, jj, and SSH read the name, email, and signing key from here. With
  # the 1Password CLI signed in, `git-identity` reads the name and email
  # from op://Personal/git instead.
  identity = {
    name = "xkef";
    email = "git@xkef.dev";
    signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFXPTYbJpNsexhTZ+x8Ci8tVkGV/d0MvWqFrlyT3yTki";
  };
}
