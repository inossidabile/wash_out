# WashOut

WashOut is a gem that greatly simplifies creation of SOAP service providers.

But if you have a chance, please [http://stopsoap.com/](http://stopsoap.com/).

## Compatibility

Rails >3.0 only.

WashOut should work like a charm on CRuby 1.9.x.

![Travis CI](https://secure.travis-ci.org/roundlake/wash_out.png)

We do support CRuby 1.8.7. However it is not a goal and it is not well supported by our specs. According to
this fact it maybe sometimes broken from the start on major releases. You are welcome to hold on an old
version and give us enough issues and pull-requests to make it work.

All dependencies are JRuby-compatible so again it will work well in --1.9 mode but it can fail with
fresh releases if you go --1.8.

## Installation

In your Gemfile, add this line:

    gem 'wash_out'

## Usage

A SOAP endpoint in WashOut is simply a Rails controller which includes the module WashOut::SOAP. Each SOAP
action corresponds to a certain controller method; this mapping, as well as the argument definition, is defined
by [soap_action][] method. Check the method documentation for complete info; here, only a few examples will be
demonstrated.

  [soap_action]: http://rubydoc.info/gems/wash_out/WashOut/SOAP/ClassMethods#soap_action-instance_method

```ruby
# app/controllers/rumbas_controller.rb
class RumbasController < ApplicationController
  include WashOut::SOAP

  # Simple case
  soap_action "integer_to_string",
              :args   => :integer,
              :return => :string
  def integer_to_string
    render :soap => params[:value].to_s
  end

  soap_action "concat",
              :args   => { :a => :string, :b => :string },
              :return => :string
  def concat
    render :soap => (params[:a] + params[:b])
  end

  # Complex structures
  soap_action "AddCircle",
              :args   => { :circle => { :center => { :x => :integer,
                                                     :y => :integer },
                                        :radius => :double } },
              :return => nil, # [] for wash_out below 0.3.0
              :to     => :add_circle
  def add_circle
    circle = params[:circle]

    raise SOAPError, "radius is too small" if circle[:radius] < 3.0

    Circle.new(circle[:center][:x], circle[:center][:y], circle[:radius])

    render :soap => nil
  end

  # Arrays
  soap_action "integers_to_boolean",
              :args => { :data => [:integer] },
              :return => [:boolean]
  def integers_to_boolean
    render :soap => params[:data].map{|x| x ? 1 : 0}
  end

  # You can use all Rails features like filtering, too. A SOAP controller
  # is just like a normal controller with a special routing.
  before_filter :dump_parameters
  def dump_parameters
    Rails.logger.debug params.inspect
  end
end
```

```ruby
# config/routes.rb
WashOutSample::Application.routes.draw do
  wash_out :rumbas
end
```

In such a setup, the generated WSDL may be queried at path `/api/wsdl`. So, with a
gem like Savon, a request can be done using this path:

```ruby
require 'savon'

client = Savon::Client.new("http://localhost:3000/rumbas/wsdl")

client.wsdl.soap_actions # => [:integer_to_string, :concat, :add_circle]

result = client.request(:concat) do
  soap.body = { :a => "123", :b => "abc" }
end

# actual wash_out
result.to_hash # => {:concat_reponse => {:value=>"123abc"}}

# wash_out below 0.3.0 (and this is malformed response so please update)
result.to_hash # => {:value=>"123abc"}
```

Take a look at [WashOut sample application](https://github.com/roundlake/wash_out-sample).

## Reusable types

Basic inline types definition is fast and furious for the simple cases. You have an option to describe SOAP types
inside separate classes for the complex ones. Here's the way to do that:

```ruby
class Fluffy < WashOut::Type
  map :universe => {
        :name => :string,
        :age  => :int
      }
end

class FluffyContainer < WashOut::Type
  type_name 'fluffy_con'
  map :fluffy => Fluffy
end
```

To use defined type inside your inline declaration, pass the class instead of type symbol (`:fluffy => Fluffy`).

Note that WashOut extends the `ActiveRecord` so every model you use is already a WashOut::Type and can be used
inside your interface declarations.

## Configuration

Use `config.wash_out...` inside your environment configuration to setup WashOut.

Available properties are:

* **namespace**: SOAP namespace to use. Default is `urn:WashOut`.
* **snakecase**: *(DEPRECATED SINCE 0.4.0)* Determines if WashOut should modify parameters keys to snakecase. Default is `false`.
* **snakecase_input**: Determines if WashOut should modify parameters keys to snakecase. Default is `false`.
* **camelize_wsdl**: Determinse if WashOut should camelize types within WSDL and responses. Default is `false`.

### Camelization

Note that WSDL camelization will affect method names but only if they were given as a symbol:

```ruby
soap_action :foo  # this will be affected
soap_action "foo" # this will be passed as is
```

## Credits

<img src="http://roundlake.ru/assets/logo.png" align="right" />

* Boris Staal ([@_inossidabile](http://twitter.com/#!/_inossidabile))
* Peter Zotov ([@whitequark](http://twitter.com/#!/whitequark))

## Contributors

* Björn Nilsson ([@Bjorn-Nilsson](https://github.com/Bjorn-Nilsson))
* Tobias Bielohlawek ([@rngtng](https://github.com/rngtng))
* Francesco Negri ([@dhinus](https://github.com/dhinus))
* Edgars Beigarts ([@ebeigarts](https://github.com/ebeigarts))

## LICENSE

It is free software, and may be redistributed under the terms of MIT license.
