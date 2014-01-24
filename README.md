# Bandiera::Client (Ruby)

This is a client for talking to the [Bandiera][bandiera] feature flagging
service from a Ruby application.

# Usage

Add the following to your `Gemfile`:

```ruby
gem "bandiera-client"
```

Then interact with a Bandiera server like so:

```ruby
require "bandiera/client"

$bandiera = Bandiera::Client.new("http://bandiera.example.com")

if $bandiera.enabled?("pubserv", "show-new-search")
  # show the new experimental search function
end
```

The `$bandiera.enabled?` command takes two arguments - the "feature group",
and the "feature name".  This is because in Bandiera, features are organised
in groups as it is intented as a service for multiple applications to use at
the same time - this organisation allows separation of feature flags that are
intended for different audiences.

# Development

1. Fork this repo.
2. Run `bundle install`

# License

[&copy; 2014, Nature Publishing Group](LICENSE.txt).

Bandiera is licensed under the [GNU General Public License 3.0][gpl].

[gpl]: http://www.gnu.org/licenses/gpl-3.0.html
[bandiera]: https://github.com/nature/bandiera

