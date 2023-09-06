# wt-fetch

This is a simple, cached, opinionated interface for
[`wttr.in`](https://github.com/chubin/wttr.in). `wt-fetch` will compose and
display specific weather modules based on an input location. These modules can
then be displayed in terminals, status bars, text prompts, etc...

## How to Use

### Nix

The best way to run this application is to use
[`nix`](https://nixos.org/download.html). `Nix` will include all the
dependencies needed to run the application.

```shell
# Run from this repository directory.
nix run .#wt-fetch -- --help

# Run from remote repository.
nix run github:siph/wt-fetch#wt-fetch -- --help
```

### Nushell

Nushell is currently very unstable so this method is not recommended but it is
compatible with version `0.84.0`

```
# Pass into fresh nushell instance.
nu wt-fetch.nu --help

# Create environment with script shebang.
./wt-fetch.nu --help
```
## Weather Modules

Here is a preview of the four modules `wt-fetch` currently supports:

 - Condition: `⛅️`
 - Temperature: `73°F`
 - Wind: `↘8mph`
 - Moon: `🌖`

## How It Works

Location data fetched from `wttr.in` will be cached with subsequent calls
preferring to use the cache. This provides a more stable and performant way of
retrieving up-to-date weather information. If a locations cache is older than
the threshold (2 hours by default), `wt-fetch` will refresh the cache.

