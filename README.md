# ⚠️ This tap is frozen at v0.6.4 — the project moved

**AginxBrowser is now [diting](https://github.com/yinnho/diting).**
New tap: `yinnho/diting` (https://github.com/yinnho/homebrew-diting)

```bash
brew uninstall aginxbrowser || true
brew untap yinnho/aginxbrowser || true
brew tap yinnho/diting && brew install yinnho/diting/diting
```

This tap keeps serving v0.6.4 so existing `brew upgrade` paths don't
break, but it will never see another release.

---

# Yinnho Aginxbrowser

## How do I install these formulae?

`brew install yinnho/aginxbrowser/<formula>`

Or `brew tap yinnho/aginxbrowser` and then `brew install <formula>`.

Or, in a `brew bundle` `Brewfile`:

```ruby
tap "yinnho/aginxbrowser"
brew "<formula>"
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
