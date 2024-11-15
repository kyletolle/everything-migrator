# Everything::Migrator

For migrating `everything` pieces from v1 to v2. Used to migrate hundreds of pieces in my everything repo in November 2024.

## Installation

Clone from github and run with Ruby 3.3.1.

## Usage

From the `everything-migrator` folder, you can run this script in a few ways.

### Use Cases

1. Migrate all pieces under a path and move all the files from those piece folders up into the root folder.

```
ruby bin/everything-migrator  ~/your/everything/path/
```

2. Migrate a single piece at a path and move all its files from the piece up into the root folder.

```
ruby bin/everything-migrator  ~/your/everything/path/old-piece --single-piece
```

3. Migrate a single piece at a path but keep its files inside that piece folder.

```
ruby bin/everything-migrator  ~/your/everything/path/old-piece --single-piece --keep-in-subfolder
```

4. Migrate all pieces under a path except for a comma separated list of pieces/folders you want to entirely ignore. Can be used with either `--keep-in-subfolder` or not.

```
ruby bin/everything-migrator  ~/your/everything/path/ --skip-pieces this-one,that-one
```

### Options

- `--keep-in-subfolder`, `-k` - Keep all pieces folders in the subfolder instead of moving them to the root
- `--single-piece`, `-s` - Treat the root path as the location of a single piece
- `--skip-pieces`, `-x` - List of pieces to skip

## Development & Contributing

This was mostly a one-off script, so probably won't have need for this. Was initally created as a gem, but I don't think it makes sense to try to actually publish it that way, since this has served its purpose now and I've run it.

## License

The repo is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
