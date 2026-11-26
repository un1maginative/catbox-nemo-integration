# catbox-nemo-integration

Right-click upload to [catbox.moe](https://catbox.moe) from the Nemo file manager (Cinnamon). Uploads the selected file(s), copies the link(s) to the clipboard, and shows a desktop notification.

## Install

```bash
git clone https://github.com/un1maginative/catbox-nemo-integration nemo-catbox
cd nemo-catbox
./install.sh
```

Options: `-y` (no prompts), `--no-deps` (skip dependency install), `--bin-dir DIR` (default `~/.local/bin`).

Supports pacman, apt, and dnf for dependencies (`curl`, `libnotify`, and `xclip`; `wl-copy` and `xsel` are also detected).

## Uninstall

```bash
./uninstall.sh
```

## Usage

Select one or more files in Nemo, right-click, **Upload to Catbox**. Folders are not supported.

## Account uploads (optional)

Uploads are anonymous by default. To tie them to your Catbox account:

```bash
mkdir -p ~/.config/catbox
echo 'YOUR_USERHASH' > ~/.config/catbox/userhash
chmod 600 ~/.config/catbox/userhash
```

## Notes

- Catbox limits uploads to 200 MB per file.
- Please follow Catbox's terms of service.
