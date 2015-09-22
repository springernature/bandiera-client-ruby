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

The `client.enabled?` command takes two main arguments - the 'feature group', and the 'feature name'.  This is because in Bandiera, features are organised into groups as it is intented as a service for multiple applications to use at the same time - this organisation allows separation of feature flags that are intended for different audiences.

`client.enabled?` also takes an optional `params` hash, this is for use with some of the more advanced features in Bandiera - user group and percentage based flags.  It is in this params hash you pass in your `user_group` and `user_id`, i.e.:

```ruby
client.enabled?('pubserv', 'show-new-search',
  { user_id: '1234567', user_group: 'Administrators' })
```

For more information on these advanced features, please see the Bandiera wiki:

https://github.com/nature/bandiera/wiki/How-Feature-Flags-Work#feature-flags-in-bandiera

# Performance

Using the `client.enabled?` method all over your codebase isn't the most efficient way of working with Bandiera as every time you call `enabled?` you will make a HTTP request to the Bandiera server.

One way of working more efficiently is using the [Direct API Access](#direct-api-access) methods, to fetch all the feature flags for a given group (or even **all** of the feature flags in the Bandiera server) in one request. You can then hold these as you please in your application and call on the values when needed.

Another approach is to use the Bandiera::Middleware class supplied in this gem.  This can be used in conjunction with other middlewares for identifying your currently logged in user and assigning them a UUID to enable all of the most advanced features in Bandiera very simply.

[See the blog post on cruft.io for more information on how Bandiera::Client is used at Nature.](http://cruft.io)

<a name="direct-api-access"></a># Direct API Access

If you'd prefer not to use the `enabled?` method for featching feature flag values, the following methods are available...

Get features for all groups:

```ruby
client.get_all(params)
  # gives:
  # {
  #   'group1' => {
  #     'feature1' => true,
  #     'feature2' => false
  #   },
  #   'group2' => {
  #     'feature1' => false
  #   },
  # }
```

Get features for a group:

```ruby
client.get_features_for_group('pubserv', params)
  # gives:
  # {
  #   'feature1' => true,
  #   'feature2' => false
  # }
```

Get an individual feature:

```ruby
client.get_feature('pubserv', 'show-article-metrics', params)
  # gives: true/false
```

As with the `enabled?` method the `params` hash is for passing in your `user_group` and `user_id` values if you are using some of the more advanced features in Bandiera.

# Development

1. Fork this repo.
2. Run `bundle install`

# License

[&copy; 2014 Nature Publishing Group](LICENSE.txt).
Bandiera::Client (Ruby) is licensed under the [MIT License][mit].


[mit]: http://opensource.org/licenses/mit-license.php
[bandiera]: https://github.com/nature/bandiera
[bandiera-api]: https://github.com/nature/bandiera/wiki/API-Documentation
[info-dependencies]: https://gemnasium.com/nature/bandiera-client-ruby
[info-license]: LICENSE
[info-gem]: https://rubygems.org/gems/bandiera-client
[info-build]: https://travis-ci.org/nature/bandiera-client-ruby
[shield-dependencies]: https://img.shields.io/gemnasium/nature/bandiera-client-ruby.svg
[shield-license]: https://img.shields.io/badge/license-MIT-blue.svg
[shield-gem]: https://img.shields.io/gem/v/bandiera-client.svg
[shield-build]: https://img.shields.io/travis/nature/bandiera-client-ruby/master.svg
