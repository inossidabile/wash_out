module WashOut
  class Wsse

    def initialize token
      if token.nil? && required?
        raise WashOut::Dispatcher::SOAPError, "Unauthorized"
      end
      @username_token = token
      check_auth if required?
    end

    def required?
      WashOut::Engine.wsse_required
    end

    def expected_user
      WashOut::Engine.wsse_username
    end

    def expected_pass
      WashOut::Engine.wsse_password
    end

    def matches_expected_digest?(password)
      nonce = @username_token.values_at(:nonce, :Nonce).compact.first
      timestamp = @username_token.values_at(:created, :Created).compact.first

      flavors = Array.new

      # Flavor one (Savon)
      token = nonce + timestamp + expected_pass
      flavors << Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!

      # Flavor two (SOAP UI)
      token = Base64.decode64(nonce) + timestamp + expected_pass
      flavors << Base64.encode64(Digest::SHA1.digest(token)).chomp!

      flavors.each do |f|
        return true if f==password
      end
      return false
    end

    def check_auth
      user = @username_token.values_at(:username, :Username).compact.first
      pass = @username_token.values_at(:password, :Password).compact.first

      if (expected_user == user && expected_pass == pass)
        return
      end

      if (expected_user == user && matches_expected_digest?(pass))
        return
      end

      raise WashOut::Dispatcher::SOAPError, "Unauthorized"
    end

  end
end
