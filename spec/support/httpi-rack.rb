require 'httpi'
require 'httpi/response'

module HTTPI
  module Adapters
    class Rack
      def initialize(request=nil)
      end

      def method_missing(method, *args)
        if %w{get post head put delete}.include?(method.to_s)
          request, = args

          action = ('_' + request.url.path.split('/').last).to_sym
          app = $controller.action(action)
          app = ActionDispatch::ParamsParser.new(app)
          mock_req = ::Rack::MockRequest.new(app)

          env = {}
          env['HTTP_X_POST_DATA_FORMAT'] = 'xml'
          env['HTTP_SOAPACTION'] = request.headers['SOAPAction'] if request.headers.include? 'SOAPAction'
          mock_resp = mock_req.request(method.to_s.upcase, request.url.to_s,
                { :fatal => true, :lint => true, :input => request.body.to_s }.merge(env))

          HTTPI::Response.new(mock_resp.status, mock_resp.headers, mock_resp.body)
        else
          super
        end
      end
    end
  end

  Adapter::ADAPTERS[:rack] = { :class => Adapters::Rack, :require => 'rack/mock' }
end
