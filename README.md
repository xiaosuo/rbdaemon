# RBDaemon

A daemon library in Ruby

## Installation

Add this line to your application's Gemfile:

    gem 'rbdaemon'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rbdaemon

## Usage

````ruby
require 'rubygems'
gem 'rbdaemon'
require 'rbdaemon'

RBDaemon::Daemon.new do
  loop do
    sleep(3)
  end
end
````

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
