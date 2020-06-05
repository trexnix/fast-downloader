# FastDownloader

A simple tool for downloading a file in segments simultaneously and combine them into one later.

## Installation

```bash
git clone https://github.com/trexnix/fast-downloader.git
cd fast-downloader
mix deps.get
```

## Usage

```bash
./bin/fast_downloader <file_url> --requests <number_of_concurrent_requests>
```

## Development

Makes changes to `lib/fast_downloader.ex` then rebuild the escript:

```bash
mix escript.build
```