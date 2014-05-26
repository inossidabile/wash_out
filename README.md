# WashOut

WashOut is a gem that greatly simplifies creation of SOAP service providers.

[![Gem Version](https://badge.fury.io/rb/wash_out.png)](http://badge.fury.io/rb/wash_out)
[![Travis CI](https://secure.travis-ci.org/inossidabile/wash_out.png)](https://travis-ci.org/inossidabile/wash_out)
[![Code Climate](https://codeclimate.com/github/inossidabile/wash_out.png)](https://codeclimate.com/github/inossidabile/wash_out)

But if you have a chance, please [http://stopsoap.com/](http://stopsoap.com/).

##  Requirements

1. {Ruby 1.9.x or Ruby 2.0.x}[http://www.ruby-lang.org]
2. {Ruby on Rails}[http://rubyonrails.org].
3. {Virtus Gem}[https://github.com/solnic/virtus]
4. {ActiveModel Gem}[https://rubygems.org/gems/activemodel]

## Compatibility

Rails >3.0 only. MRI 1.9, 2.0, JRuby (--1.9).

Ruby 1.8 is not officially supported since 0.5.3. We will accept further compatibilty pull-requests but no upcoming versions will be tested against it.

Rubinius support temporarily dropped since 0.6.2 due to Rails 4 incompatibility.

## Installation

In your Gemfile, add this line:

    gem 'wash_out'

Please read [release details](https://github.com/inossidabile/wash_out/releases) if you are upgrading. We break backward compatibility between large ticks but you can expect it to be specified at release notes.

## Usage

A SOAP endpoint in WashOut is simply a Rails controller which includes the module WashOut::SOAP. Each SOAP
action corresponds to a certain controller method; this mapping, as well as the argument definition, is defined
by [soap_action][] method. Check the method documentation for complete info; here, only a few examples will be
demonstrated.

  [soap_action]: http://rubydoc.info/gems/wash_out/WashOut/SOAP/ClassMethods#soap_action-instance_method

```ruby
# app/controllers/rumbas_controller.rb
class RumbasController < ApplicationController
  soap_service namespace: 'urn:WashOut'

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

client = Savon::Client.new(wsdl: "http://localhost:3000/rumbas/wsdl")

client.operations # => [:integer_to_string, :concat, :add_circle]

result = client.call(:concat, message: { :a => "123", :b => "abc" })

# actual wash_out
result.to_hash # => {:concat_reponse => {:value=>"123abc"}}

# wash_out below 0.3.0 (and this is malformed response so please update)
result.to_hash # => {:value=>"123abc"}
```

## Reusable types

Basic inline types definition is fast and furious for the simple cases. You have an option to describe SOAP types
inside separate classes for the complex ones. Here's the way to do that:

```ruby
class Fluffy < WashOut::Type
   attribute name, String, :options => {:minoccurs => 0, :maxoccurs => 1, :nillable =>true }
  attribute name, Integer, :options => {:minoccurs => 0, :maxoccurs => 1, :nillable =>true }
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

Use `config.wash_out...` inside your environment configuration to setup WashOut globally.
To override the values on a specific controller just add an override as part of the arguments to the `soap_service` method.

Available properties are:

* **parser**: XML parser to use – `:rexml` or `:nokogiri`. The first one is default but the latter is much faster. Be sure to add `gem nokogiri` if you want to use it.
* **wsdl_style**: sets WSDL style. Supported values are: 'document' and 'rpc'.
* **catch_xml_errors**: intercept Rails parsing exceptions to return correct XML response for corrupt XML input. Default is `false`.
* **namespace**: SOAP namespace to use. Default is `urn:WashOut`.
* **snakecase_input**: Determines if WashOut should modify parameters keys to snakecase. Default is `false`.
* **camelize_wsdl**: Determines if WashOut should camelize types within WSDL and responses. Supports `true` for CamelCase and `:lower` for camelCase. Default is `false`.

### Camelization

Note that WSDL camelization will affect method names but only if they were given as a symbol:

```ruby
soap_action :foo  # this will be affected
soap_action "foo" # this will be passed as is
```

## Maintainers

* Boris Staal, [@inossidabile](http://staal.io)

## Contributors (in random order)

* Mikael Henriksson, [@mhenrixon](http://twitter.com/mhenrixon)
* Björn Nilsson [@Bjorn-Nilsson](https://github.com/Bjorn-Nilsson)
* Tobias Bielohlawek [@rngtng](https://github.com/rngtng)
* Francesco Negri [@dhinus](https://github.com/dhinus)
* Edgars Beigarts [@ebeigarts](https://github.com/ebeigarts)
* [Exad](https://github.com/exad) [@wknechtel](https://github.com/wknechtel) and [@☈king](https://github.com/rking)
* Mark Goris [@gorism](https://github.com/gorism)
* ... and [others](https://github.com/inossidabile/wash_out/graphs/contributors)

## License

It is free software, and may be redistributed under the terms of MIT license.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/inossidabile/wash_out/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
