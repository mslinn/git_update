<!-- markdownlint-disable-file MD012, MD014 -->
# `update` - Update Trees of Git Repos [![Gem Version](https://badge.fury.io/rb/git_update.svg)](https://badge.fury.io/rb/git_update)

This Ruby gem installs the `git-update` command,
which scans git directory trees and updates them.
Directories containing a file called `.ignore` are ignored.

## Usage

The `git-update` command requires at least one parameter:
the names of the top-level directories to update.

The following updates the directory tree of git repos under the `/data/work` directory:

```shell
$ git update /data/work
```

The following accomplishes the same thing:

```shell
$ export work=/data/work

$ git update $work
```

The following accomplishes the same thing:

```shell
$ git-update $work
```

The following updates the directory trees of git repos pointed to by `$work` and `$sites`:

```shell
$ export work=/data/work

$ export sites=/var/www

$ git update $work $sites
```


## Installation

Type the following at a shell prompt:

```shell
$ gem install git_tree
```


## Additional Information

More information is available on
[Mike Slinn&rsquo;s website](https://www.mslinn.com/git/1100-git-tree.html)


## Development

After checking out the repo, run `bin/setup` to install dependencies.

You can run `bin/console` for an interactive prompt that will allow you to experiment.

```shell
$ bin/console
irb(main):001:0> GitUpdate.command_update '/var/www'
```


### Build and Install Locally

To build and install this gem onto your local machine, run:

```shell
$ bundle exec rake install
```

Examine the newly built gem:

```shell
$ gem info git_update

*** LOCAL GEMS ***
git_update (0.1.0)
    Author: Mike Slinn
    Homepage:
    https://github.com/mslinn/git_update
    License: MIT
    Installed at: /home/mslinn/.gems
```


### Build and Push to RubyGems

To release a new version:

  1. Update the version number in `version.rb`.

  2. Commit all changes to git; if you don't the next step might fail with an
     unexplainable error message.

  3. Run the following:

     ```shell
     $ bundle exec rake release
     ```

     The above creates a git tag for the version, commits the created tag,
     and pushes the new `.gem` file to [RubyGems.org](https://rubygems.org).


## Contributing

1. Fork the project
2. Create a descriptively named feature branch
3. Add your feature
4. Submit a pull request


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
