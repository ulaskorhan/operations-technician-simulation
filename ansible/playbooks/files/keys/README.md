# SSH public keys for users.yml

Put one **public** key per user here, named `<username>.pub` (for example `labuser.pub`).
Never put a private key (the file without `.pub`) in this repo.

For the lab, the simplest is to reuse my own key:

```bash
cp ~/.ssh/id_ed25519.pub labuser.pub
cp ~/.ssh/id_ed25519.pub opsviewer.pub
```

Or create a separate key pair per user (keep the private keys outside the repo):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/opsviewer -C "opsviewer@lab"
cp ~/.ssh/opsviewer.pub opsviewer.pub
```

TODO: add the key files before running `users.yml`.
