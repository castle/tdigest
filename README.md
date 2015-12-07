# Tdigest

[![Gem Version](https://badge.fury.io/rb/tdigest.svg)](https://badge.fury.io/rb/tdigest)

Ruby implementation of Ted Dunning's [t-digest](https://github.com/tdunning/t-digest) data structure.

Inspired by the [Javascript implementation](https://github.com/welch/tdigest) by [Will Welch](https://github.com/welch)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tdigest'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tdigest

## Usage

```ruby
td = ::TDigest::TDigest.new
1_000.times { td.push(rand) }
td.compress!

puts td.percentile(0.5)
puts td.p_rank(0.95)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/castle/tdigest.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
