WashOut
========

WashOut is a gem that greatly simplifies creation of SOAP service providers.

But if you have a chance, please [http://stopsoap.com/](http://stopsoap.com/).

Compatibility
--------------

Rails >3.0 only.

WashOut should work like a charm on CRuby 1.9.x.

We do support CRuby 1.8.7. However it is not a goal and it is not well supported by our specs. According to
this fact it maybe sometimes broken from the start on major releases. You are welcome to hold on an old
version and give us enough issues and pull-requests to make it work.

All dependencies are JRuby-compatible so again it will work well in --1.9 mode but it can fail with
fresh releases if you go --1.8.

Installation
------------

In your Gemfile, add this line:

    gem 'wash_out'

Usage
-----

A SOAP endpoint in WashOut is simply a Rails controller which includes the module WashOut::SOAP. Each SOAP
action corresponds to a certain controller method; this mapping, as well as the argument definition, is defined
by [soap_action][] method. Check the method documentation for complete info; here, only a few examples will be
demonstrated.

  [soap_action]: http://rubydoc.info/gems/wash_out/WashOut/SOAP/ClassMethods#soap_action-instance_method

```ruby
# app/controllers/rumbas_controller.rb
class RumbasController < ApplicationController
  include WashOut::SOAP

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

  soap_action "AddCircle",
              :args   => { :circle => { :center => { :x => :integer,
                                                     :y => :integer },
                                        :radius => :double } },
              :return => [],
              :to     => :add_circle
  def add_circle
    circle = params[:circle]

    raise SOAPError, "radius is too small" if circle[:radius] < 3.0

    Circle.new(circle[:center][:x], circle[:center][:y], circle[:radius])

    render :soap => nil
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
result.to_hash # => {:value=>"123abc"}
```

Take a look at [WashOut sample application](https://github.com/roundlake/wash_out-sample).

License
-------

    Copyright (C) 2011 by Boris Staal <boris@roundlake.ru>,
                          Peter Zotov <p.zotov@roundlake.ru>.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
