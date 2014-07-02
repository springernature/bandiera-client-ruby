# Bandiera::Client (Ruby)

This is a client for talking to the [Bandiera][bandiera] feature flagging
service from a Ruby application.

This client is compatible with the [v2 Bandiera API][bandiera-api].

**Current Version:** 2.1.0  
**License:** [MIT][mit]  
**Build Status:** [![Build Status][travis-img]][travis]

## Ruby Support:

This client has been tested against the following ruby versions:

**MRI:** 1.9.3-p385, 1.9.3-p448, 1.9.3-p484, 1.9.3-p545, 2.0.0-p0, 2.0.0-p247,
2.0.0-p353, 2.0.0-p451, 2.1.0, 2.1.1, 2.1.2  
**JRuby:** 1.7.10, 1.7.11, 1.7.12  
**Rubinius:** 2.2.6, 2.2.7, 2.2.9, 2.2.10

# Usage

Add the following to your `Gemfile`:

```ruby
gem 'bandiera-client'
```

Then interact with a Bandiera server like so:

```ruby
require 'bandiera/client'

$bandiera = Bandiera::Client.new('http://bandiera.example.com')

if $bandiera.enabled?('pubserv', 'show-new-search')
  # show the new experimental search function
end
```

The `$bandiera.enabled?` command takes two arguments - the 'feature group',
and the 'feature name'.  This is because in Bandiera, features are organised
in groups as it is intented as a service for multiple applications to use at
the same time - this organisation allows separation of feature flags that are
intended for different audiences.

# Development

1. Fork this repo.
2. Run `bundle install`

# License

[&copy; 2014 Nature Publishing Group](LICENSE.txt).  
Bandiera::Client (Ruby) is licensed under the [MIT License][mit].


[mit]: http://opensource.org/licenses/mit-license.php
[bandiera]: https://github.com/nature/bandiera
[bandiera-api]: https://github.com/nature/bandiera/wiki/API-Documentation
[travis]: https://travis-ci.org/nature/bandiera-client-ruby
[travis-img]: https://travis-ci.org/nature/bandiera-client-ruby.svg?branch=master
