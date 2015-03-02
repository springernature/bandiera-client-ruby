# Bandiera::Client (Ruby)

This is a client for talking to the [Bandiera][bandiera] feature flagging
service from a Ruby application.

This client is compatible with the [v2 Bandiera API][bandiera-api].

**Current Version:** 2.2.2
**License:** [MIT][mit]
**Build Status:** [![Build Status][travis-img]][travis]

## Ruby Support:

This client has been tested against the latest MRI and JRuby builds.

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

## Caching

Bandiera::Client has a small layer of caching built into it in order to:

1. Reduce the amount of HTTP requests made to the Bandiera server
2. Make things faster

### Strategies

There are three request/caching strategies you can use with Bandiera::Client.

**:single_feature**

This strategy calls the Bandiera API for each new .enabled? request, and stores
the response in it's local cache. Subsequent `.enabled?` requests (using the
same arguments) will read from the cache until it has expired.  This is the
**least** efficient strategy in terms of reducing HTTP requests and speed.

**:group**

This strategy calls the Bandiera API **once** for each feature flag group
requested, and then stores the resulting feature flag values in the cache.
This means that all subsequent calls to `.enabled?` for the same group will not
perform a HTTP request and instead read from the cache until it has expired.
This is a good compromise in terms of speed and number of HTTP requests, **and
is the default caching strategy**.

**:all**

This strategy calls the Bandiera API **once** and fetches/caches all feature
flag values locally. All subsequent calls to `.enabled?` read from the cache
until it has expired. This strategy is obviously the most efficient in terms of
the number of HTTP requests if you are requesting flags from across multiple
groups, but might not be the fastest if there are **lots** of flags in your
Bandiera instance.

#### Changing the Cache Strategy

```ruby
$bandiera = Bandiera::Client.new('http://bandiera.example.com')
$bandiera.cache_strategy = :all
```

### Cache Expiration

The default cache lifetime is 5 seconds.  If you would like to alter this you
can do so as follows:

```ruby
$bandiera = Bandiera::Client.new('http://bandiera.example.com')
$bandiera.cache_ttl = 10 # 10 seconds
```


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
