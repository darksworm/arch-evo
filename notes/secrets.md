# Secrets: SSH keys via `pass`

How SSH passphrase entry is wired in this setup, and what manual steps you
need to take after a fresh install.

## How it works

```
ssh / git push
   │
   ├─► reads ~/.ssh/id_ecdsa (encrypted)
   │
   ├─► SSH_ASKPASS=ssh-askpass-pass     (set in zshrc + hyprland env)
   │     │
   │     └─► pass show ssh/id_ecdsa
   │           │
   │           └─► gpg-agent → pinentry (first time per cache window)
   │
   ├─► decrypts key, uses it
   │
   └─► AddKeysToAgent yes  → loaded into ssh-agent for the session
```

- `ssh-agent.service` (systemd user unit) provides the socket at
  `$XDG_RUNTIME_DIR/ssh-agent.socket`.
- `~/.local/bin/ssh-askpass-pass` greps the key path out of the prompt and
  runs `pass show ssh/<basename>`.
- `gpg-agent` caches the GPG passphrase per its TTL (`~/.gnupg/gpg-agent.conf`,
  currently 8h); within that window `pass show` is silent.
- `~/.local/bin/lock` (bound to lock_cmd, $mod+F12, $mod+CTRL+Q) runs
  `ssh-add -D` and `gpg-connect-agent reloadagent` before locking, so unlock
  → next ssh use → fresh prompt.

## One-time manual setup

After running `apps/23_ssh_agent.sh`, do this as your user:

1. **Make sure `pass` is initialised** (it should be; check with `pass`).
2. **Insert the SSH key passphrases**, one per key file. The pass entry name
   must match the key file's basename:

   ```sh
   pass insert ssh/id_ecdsa
   pass insert ssh/id_ecdsa_darksworm
   ```

3. **Test it works** without restarting your session:

   ```sh
   ssh-add -D                   # clear any cached keys
   gpg-connect-agent reloadagent /bye   # force gpg pinentry on next use
   ssh -T git@github.com        # should pop pinentry once, then succeed
   ssh-add -l                   # key should now be listed (AddKeysToAgent)
   ```

4. **Confirm lock clears caches**: lock the session ($mod+CTRL+Q), unlock,
   then `ssh-add -l` should report no identities. Next ssh op re-prompts.

## When you generate a new SSH key

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_newthing       # set a passphrase
pass insert ssh/id_newthing                        # store the same passphrase
```

The askpass helper picks it up automatically by basename — no script edits
needed.

## Troubleshooting

- **`No pinentry program`** on first `pass show`: install a graphical
  pinentry — `sudo pacman -S pinentry` already pulls one, but you may need
  to set `pinentry-program` in `~/.gnupg/gpg-agent.conf` if defaults don't
  resolve. Reload with `gpg-connect-agent reloadagent /bye`.
- **`SSH_AUTH_SOCK` empty in a new shell**: `systemctl --user status
  ssh-agent.service` — should be active. zshrc and hyprland both export
  the socket path; if you're in a non-hypr graphical app and it's missing,
  re-login to refresh dbus activation env.
- **Wrong passphrase**: `pass show ssh/id_ecdsa` to verify the stored value
  matches the key file. To rotate: `ssh-keygen -p -f ~/.ssh/id_ecdsa` then
  `pass edit ssh/id_ecdsa`.

## Threat model (be honest)

This protects against:

- Passphrase exposure on disk (key file is encrypted, passphrase is in pass
  which is encrypted with your GPG key).
- Cached keys surviving lid close / suspend (the `lock` script clears them).

This does **not** protect against:

- Anything running as your user while gpg-agent / ssh-agent caches are
  warm. If you don't trust a process in your session, this setup won't
  stop it — that's a hardware-backed-key (YubiKey FIDO2 / TPM) problem,
  not a `pass` problem.
