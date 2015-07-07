# Bandiera::Client (Ruby)

This is a client for talking to the [Bandiera][bandiera] feature flagging service from a Ruby application.

This client is compatible with the [v2 Bandiera API][bandiera-api].

[![Gem version][shield-gem]][info-gem]
[![Build status][shield-build]][info-build]
[![Dependencies][shield-dependencies]][info-dependencies]
[![MIT licensed][shield-license]][info-license]

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

client = Bandiera::Client.new('http://bandiera-demo.herokuapp.com')
params = {}

if client.enabled?('pubserv', 'show-new-search', params)
  # show the new experimental search function
end
```

The `client.enabled?` command takes two main arguments - the 'feature group',
and the 'feature name'.  This is because in Bandiera, features are organised
into groups as it is intented as a service for multiple applications to use at
the same time - this organisation allows separation of feature flags that are
intended for different audiences.

`client.enabled?` also takes an optional `params` hash, this is
for use with some of the more advanced features in Bandiera - user group and percentage based flags.  It is in this params hash you pass in your
`user_group` and `user_id`, i.e.:

```ruby
client.enabled?('pubserv', 'show-new-search',
  { user_id: '1234567', user_group: 'Administrators' })
```

For more information on these advanced features, please see the Bandiera wiki:

https://github.com/nature/bandiera/wiki/How-Feature-Flags-Work#feature-flags-in-bandiera

## Caching

`Bandiera::Client#enabled?` has a small layer of caching built into it in order to:

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
client = Bandiera::Client.new('http://bandiera-demo.herokuapp.com')
client.cache_strategy = :all
```

### Cache Expiration

The default cache lifetime is 5 seconds.  If you would like to alter this you
can do so as follows:

```ruby
client = Bandiera::Client.new('http://bandiera-demo.herokuapp.com')
client.cache_ttl = 10 # 10 seconds
```

# Direct API Access

If you'd prefer not to use the `enabled?` method for featching feature flag values, the following methods are available...

Get features for all groups:

```ruby
client.get_all(params)
```

Get features for a group:

```ruby
client.get_features_for_group('pubserv', params)
```

Get an individual feature:

```ruby
client.get_feature('pubserv', 'show-article-metrics', params)
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
[info-dependencies]: https://gemnasium.com/nature/bandiera-client-node
[info-license]: LICENSE
[info-gem]: https://rubygems.org/gems/bandiera-client
[info-build]: https://travis-ci.org/nature/bandiera-client-ruby
[shield-dependencies]: https://img.shields.io/gemnasium/nature/bandiera-client-ruby.svg
[shield-license]: https://img.shields.io/badge/license-MIT-blue.svg
[shield-gem]: https://img.shields.io/gem/v/bandiera-client.svg
[shield-build]: https://img.shields.io/travis/nature/bandiera-client-ruby/master.svg
