module WashOut

  module WsseParams
    def wsse_username
      if request.env['WSSE_TOKEN']
        request.env['WSSE_TOKEN'].values_at(:username, :Username).compact.first
      end
    end
  end

  class Wsse
    attr_reader :soap_config
    def self.authenticate(soap_config, token)
      wsse = self.new(soap_config, token)

      unless wsse.eligible?
        raise WashOut::Dispatcher::SOAPError, "Unauthorized"
      end
    end

    def initialize(soap_config, token)
      @soap_config = soap_config
      if token.blank? && required?
        raise WashOut::Dispatcher::SOAPError, "Missing required UsernameToken"
      end
      @username_token = token
    end

    def required?
      !soap_config.wsse_username.blank? || auth_callback?
    end

    def auth_callback?
      return !!soap_config.wsse_auth_callback && soap_config.wsse_auth_callback.respond_to?(:call) && soap_config.wsse_auth_callback.arity == 4
    end

    def perform_auth_callback(user, password, nonce, timestamp)
      soap_config.wsse_auth_callback.call(user, password, nonce, timestamp)
    end

    def expected_user
      soap_config.wsse_username
    end

    def expected_password
      soap_config.wsse_password
    end

    def eligible?
      return true unless required?

      user     = @username_token.values_at(:username, :Username).compact.first
      password = @username_token.values_at(:password, :Password).compact.first

      nonce = @username_token.values_at(:nonce, :Nonce).compact.first
      timestamp = @username_token.values_at(:created, :Created).compact.first

      if (expected_user == user && self.class.matches_expected_digest?(expected_password, password, nonce, timestamp))
        return true
      end

      if auth_callback?
        return perform_auth_callback(user, password, nonce, timestamp)
      end

      if (expected_user == user && expected_password == password)
        return true
      end

      return false
    end

    def self.matches_expected_digest?(expected_password, password, nonce, timestamp)
      return false if nonce.nil? || timestamp.nil?

      timestamp = timestamp.to_datetime

      # Token should not be accepted if timestamp is older than 5 minutes ago
      # http://www.oasis-open.org/committees/download.php/16782/wss-v1.1-spec-os-UsernameTokenProfile.pdf
      offset_in_minutes = ((DateTime.now - timestamp)* 24 * 60).to_i
      return false if offset_in_minutes >= 5

      # There are a few different implementations of the digest calculation

      flavors = Array.new

      # Ruby / Savon
      token = nonce + timestamp.strftime("%Y-%m-%dT%H:%M:%SZ") + expected_password
      flavors << Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!

      # Java
      token = Base64.decode64(nonce) + timestamp.strftime("%Y-%m-%dT%H:%M:%SZ") + expected_password
      flavors << Base64.encode64(Digest::SHA1.digest(token)).chomp!

      # SoapUI
      token = Base64.decode64(nonce) + timestamp.strftime("%Y-%m-%dT%H:%M:%S.%3NZ") + expected_password
      flavors << Base64.encode64(Digest::SHA1.digest(token)).chomp!

      flavors.each do |f|
        return true if f == password
      end

      return false
    end
  end
end
