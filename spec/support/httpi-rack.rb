require 'httpi'
require 'httpi/response'

module HTTPI
  module Adapters
    # This is an adapter for testing the Rack applications with HTTPI-capable
    # clients.
    class Rack
      class << self
        attr_accessor :mounted_apps
      end

      self.mounted_apps = {}

      def self.mount(host, application)
        self.mounted_apps[host] = application
      end

      def initialize(request=nil)
      end

      def method_missing(method, *args)
        if %w{get post head put delete}.include?(method.to_s)
          request, = args

          app = self.class.mounted_apps[request.url.host]
          mock_req = ::Rack::MockRequest.new(app)

          env = {}
          request.headers.each do |header, value|
            env["HTTP_#{header.gsub('-', '_').upcase}"] = value
          end

          mock_resp = mock_req.request(method.to_s.upcase, request.url.to_s,
                { :fatal => true, :input => request.body.to_s }.merge(env))

          HTTPI::Response.new(mock_resp.status, mock_resp.headers, mock_resp.body)
        else
          super
        end
      end
    end
  end

  Adapter::ADAPTERS[:rack] = { :class => Adapters::Rack, :require => 'rack/mock' }
end
